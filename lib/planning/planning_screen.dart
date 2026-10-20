import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../budget_order.dart';
import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../money.dart';
import '../month/month_providers.dart';
import '../settings/settings_providers.dart';
import '../theme/budget_theme.dart';
import '../widgets/amount_field.dart';
import '../widgets/budget_badges.dart';
import '../widgets/budget_order_button.dart';
import '../widgets/budget_sankey.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/leaf_background.dart';
import '../widgets/new_month_card.dart';
import '../widgets/reorderable_budgets.dart';
import 'guided_planning_help.dart';
import 'guided_planning_screen.dart';
import 'month_overview_card.dart';
import 'month_set_up.dart';
import 'plan_editing.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final incomes = ref.watch(currentIncomesProvider);
    final budgets = ref.watch(currentBudgetsProvider);
    final expenses = ref.watch(currentExpensesProvider);

    return Scaffold(
      body: LeafBackground(
        child: SafeArea(
          child: switch ((month, incomes, budgets, expenses)) {
            (
              AsyncData(value: final month),
              AsyncData(value: _),
              AsyncData(value: final budgets),
              AsyncData(value: _),
            )
                when month.needsSetUp =>
              MonthSetUp(month: month, budgets: budgets),
            (
              AsyncData(value: final month),
              AsyncData(value: final incomes),
              AsyncData(value: final budgets),
              AsyncData(value: final expenses),
            ) =>
              _BudgetPlan(
                month: month,
                incomes: incomes,
                budgets: budgets,
                expenses: expenses,
              ),
            (AsyncError(:final error), _, _, _) ||
            (_, AsyncError(:final error), _, _) ||
            (_, _, AsyncError(:final error), _) ||
            (
              _,
              _,
              _,
              AsyncError(:final error),
            ) => Center(child: Text('Something went wrong: $error')),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _BudgetPlan extends ConsumerWidget {
  const _BudgetPlan({
    required this.month,
    required this.incomes,
    required this.budgets,
    required this.expenses,
  });

  final Month month;
  final List<Income> incomes;
  final List<Budget> budgets;

  /// Spending tracked so far, if the plan was locked in before.
  final List<Expense> expenses;

  Future<void> _copyPlanFromMonthBefore(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final monthName = formatMonth(month.year, month.month);
    final confirmed = await showConfirmDialog(
      context,
      title: "Copy last month's plan?",
      message: [
        "This replaces $monthName's incomes and budgets with last month's.",
        if (expenses.isNotEmpty)
          'Its ${expenses.length} tracked '
              '${expenses.length == 1 ? 'expense is' : 'expenses are'} '
              'deleted too.',
        'Your notes are kept.',
      ].join(' '),
      confirmLabel: 'Replace plan',
    );
    if (!confirmed) return;
    final copied = await ref
        .read(appDatabaseProvider)
        .copyPlanFromMonthBefore(month.id);
    if (!copied && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There is no earlier month to copy.')),
      );
    }
  }

  Future<void> _editCarryOver(BuildContext context, WidgetRef ref) async {
    final carryOverCents = await showDialog<int>(
      context: context,
      builder: (_) => _CarryOverDialog(
        carryOverCents: month.carryOverCents,
        leftCents: month.carryOverCents - month.carryOverAdjustmentCents,
      ),
    );
    if (carryOverCents != null) {
      await ref
          .read(appDatabaseProvider)
          .setCarryOverCents(month.id, carryOverCents);
    }
  }

  /// Locks the plan in, or says what's in the way when [blocker] is set.
  void _lock(BuildContext context, WidgetRef ref, String? blocker) {
    if (blocker != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(blocker)));
      return;
    }
    ref.read(appDatabaseProvider).lockMonth(month.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final assignedCents = budgets.fold(0, (sum, b) => sum + b.amountCents);
    final availableCents = month.incomeCents + month.carryOverCents;
    final leftCents = availableCents - assignedCents;
    // A locked in plan is read only until it's unlocked for editing.
    final isLocked = month.lockedAt != null;
    // Tracked expenses mean the plan was locked in before and is being edited.
    final isEditing = expenses.isNotEmpty;
    final title = switch ((isLocked, isEditing)) {
      (true, _) => 'Planned Budget',
      (false, true) => 'Edit your plan',
      (false, false) => 'Welcome!',
    };
    final spent = spentByBudget(expenses);
    final budgetOrder =
        ref.watch(
          settingsProvider.select((settings) => settings.value?.budgetOrder),
        ) ??
        BudgetOrder.category;
    final lockBlocker = switch (leftCents) {
      _ when availableCents == 0 || budgets.isEmpty =>
        'Add your income and budgets before locking in.',
      > 0 =>
        'Assign the remaining ${formatCents(leftCents)} before locking in.',
      < 0 =>
        'Take ${formatCents(-leftCents)} off your budgets before locking '
            'in.',
      _ => null,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverList.list(
                children: [
                  const NewMonthCard(),
                  _TitleRow(
                    title: title,
                    isLocked: isLocked,
                    onCopyPlan: () => _copyPlanFromMonthBefore(context, ref),
                    // Tracking pauses while the plan is unlocked; expenses are
                    // kept.
                    onLockToggle: isLocked
                        ? () => ref
                              .read(appDatabaseProvider)
                              .unlockMonth(month.id)
                        : () => _lock(context, ref, lockBlocker),
                  ),
                  const SizedBox(height: 24),
                  if (!isLocked) const _GuidedPlanningCard(),
                  MonthOverviewCard(
                    month: month,
                    incomes: incomes,
                    budgets: budgets,
                    onEditCarryOver: () => _editCarryOver(context, ref),
                  ),
                  if (budgets.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Where your money goes', style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: BudgetSankey(
                          incomes: incomes,
                          carryOverCents: month.carryOverCents,
                          budgets: budgets,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Budgets', style: textTheme.titleLarge),
                      ),
                      const BudgetOrderButton(),
                      if (!isLocked)
                        FilledButton.icon(
                          onPressed: () =>
                              promptAddBudget(context, ref, month.id),
                          icon: const Icon(Icons.add),
                          label: const Text('Add budget'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (budgets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No budgets yet. Add one for everything your income '
                        'needs to cover, like rent, groceries or savings.',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
            // Long press a budget to move it.
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: ReorderableBudgetsSliver(
                budgets: sortBudgets(budgets, budgetOrder),
                itemBuilder: (context, budget) => Card(
                  child: ListTile(
                    // Badges go on the next line when they don't fit.
                    title: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          budget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (budget.isFixed) const FixedBadge(),
                        if (budget.isSinkingFund) const SinkingFundBadge(),
                        if (budget.category != BudgetCategory.other)
                          CategoryBadge(budget.category),
                      ],
                    ),
                    subtitle: Text(
                      [
                        formatCents(budget.amountCents),
                        if (budget.savedCents != 0)
                          '${formatCents(budget.savedCents)} saved',
                        if (spent[budget.id] case final spentCents?)
                          '${formatCents(spentCents)} spent',
                      ].join(' · '),
                    ),
                    onTap: isLocked
                        ? null
                        : () => promptEditBudget(context, ref, budget),
                    trailing: isLocked
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit ${budget.name}',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    promptEditBudget(context, ref, budget),
                              ),
                              IconButton(
                                tooltip: 'Delete ${budget.name}',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => confirmDeleteBudget(
                                  context,
                                  ref,
                                  budget,
                                  expenses,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList.list(
                children: [
                  if (!isLocked) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: lockBlocker == null
                          ? () => ref
                                .read(appDatabaseProvider)
                                .lockMonth(month.id)
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.lock_outline),
                      label: Text(
                        isEditing ? 'Lock in changes' : 'Lock in budget',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lockBlocker ??
                          'Once locked in, fixed budgets count as spent in '
                              'full and you track the rest of your spending '
                              'for the month.',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The title on the left and the plan's actions on the right, as far apart
/// as they go. When the title and the labeled lock button don't fit on one
/// line, the button shrinks to just its lock.
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.isLocked,
    required this.onCopyPlan,
    required this.onLockToggle,
  });

  final String title;
  final bool isLocked;
  final VoidCallback onCopyPlan;

  /// Locks the plan in, or unlocks it when [isLocked].
  final VoidCallback onLockToggle;

  /// Room an icon button takes.
  static const _iconButtonWidth = 48.0;

  /// What an outlined button with an icon adds around its label: padding,
  /// the icon and the gap after it.
  static const _labeledButtonChrome = 16.0 + 18 + 8 + 24;

  /// Space kept between the title and the buttons.
  static const _gap = 16.0;

  double _widthOf(BuildContext context, String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (label, icon) = isLocked
        ? ('Edit plan', Icons.lock_open_outlined)
        : ('Lock', Icons.lock_outline);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth =
            _widthOf(context, title, textTheme.headlineMedium) +
            _gap +
            (isLocked ? 0 : _iconButtonWidth) +
            _widthOf(context, label, textTheme.labelLarge) +
            _labeledButtonChrome;
        final collapsed = fullWidth > constraints.maxWidth;

        return Row(
          children: [
            Expanded(child: Text(title, style: textTheme.headlineMedium)),
            const SizedBox(width: _gap),
            if (!isLocked)
              IconButton(
                tooltip: "Copy last month's plan",
                icon: const Icon(Icons.content_copy_outlined),
                onPressed: onCopyPlan,
              ),
            if (collapsed)
              IconButton.outlined(
                tooltip: label,
                icon: Icon(icon),
                onPressed: onLockToggle,
              )
            else
              OutlinedButton.icon(
                onPressed: onLockToggle,
                icon: Icon(icon),
                label: Text(label),
              ),
          ],
        );
      },
    );
  }
}

/// Invites the user to plan the month step by step.
class _GuidedPlanningCard extends StatelessWidget {
  const _GuidedPlanningCard();

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: c.sproutTint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_outlined, color: c.onSproutTint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Plan step by step',
                    style: textTheme.titleMedium?.copyWith(
                      color: c.onSproutTint,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'How it works',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.info_outline, color: c.onSproutTint),
                  onPressed: () => showGuidedPlanningHelp(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Go through your income, giving, the essentials, savings and '
              'everything else, one step at a time. You can always fine-tune your plan later on this plan tab.',
              style: textTheme.bodyMedium?.copyWith(color: c.onSproutTint),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => startGuidedPlanning(context),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Start planning'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Corrects the month's carryover, returning it in cents.
class _CarryOverDialog extends StatefulWidget {
  const _CarryOverDialog({
    required this.carryOverCents,
    required this.leftCents,
  });

  final int carryOverCents;

  /// What last month left, which the carryover is without corrections.
  final int leftCents;

  @override
  State<_CarryOverDialog> createState() => _CarryOverDialogState();
}

class _CarryOverDialogState extends State<_CarryOverDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: formatAmount(widget.carryOverCents.abs()),
  );
  // Number keyboards on phones often have no minus key, so overspending is a
  // switch instead.
  late var _isOverspent = widget.carryOverCents < 0;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cents = parseAmountToCents(_amount.text)!;
    Navigator.of(context).pop(_isOverspent ? -cents : cents);
  }

  void _useLeftCents() => setState(() {
    _amount.text = formatAmount(widget.leftCents.abs());
    _isOverspent = widget.leftCents < 0;
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Carried over'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last month left ${formatCents(widget.leftCents)}, and this '
              "follows any changes to it. Correct it if it doesn't match "
              'what was actually left; the correction is kept on top.',
            ),
            if (widget.carryOverCents != widget.leftCents)
              TextButton(
                onPressed: _useLeftCents,
                child: const Text('Remove correction'),
              ),
            AmountField(
              controller: _amount,
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Overspent'),
              subtitle: const Text(
                'Last month went over, so this is taken off this month.',
              ),
              value: _isOverspent,
              onChanged: (value) => setState(() => _isOverspent = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
