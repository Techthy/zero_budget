import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../history/history_screen.dart';
import '../money.dart';
import '../spending/spending_providers.dart';
import '../theme/budget_theme.dart';
import '../widgets/amount_field.dart';
import '../widgets/budget_sankey.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/fixed_badge.dart';
import '../widgets/leaf_background.dart';
import 'guided_planning_screen.dart';
import 'plan_editing.dart';
import 'welcome_providers.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

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
            ) =>
              Center(child: Text('Something went wrong: $error')),
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

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => _NotesDialog(notes: month.notes),
    );
    if (notes != null) {
      await ref.read(appDatabaseProvider).updateMonthNotes(month.id, notes);
    }
  }

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
    final copied =
        await ref.read(appDatabaseProvider).copyPlanFromMonthBefore(month.id);
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

  Future<void> _editPlan(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Edit your plan?',
      message: 'Tracking pauses while you edit. Your expenses are kept, and '
          "you lock the plan in again when you're done.",
      confirmLabel: 'Edit plan',
    );
    if (confirmed) {
      await ref.read(appDatabaseProvider).unlockMonth(month.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final assignedCents = budgets.fold(0, (sum, b) => sum + b.amountCents);
    final availableCents = month.incomeCents + month.carryOverCents;
    final leftCents = availableCents - assignedCents;
    final monthName = formatMonth(month.year, month.month);
    // A locked in plan is read only until it's unlocked for editing.
    final isLocked = month.lockedAt != null;
    // Nothing left from last month, like in the first month: what's there
    // was entered as the balance to start from.
    final isStartingBalance = month.carryOverAdjustmentCents != 0 &&
        month.carryOverCents == month.carryOverAdjustmentCents;
    final carryOverText = isStartingBalance
        ? '${formatSignedCents(month.carryOverCents)} starting balance'
        : [
            '${formatSignedCents(month.carryOverCents)} carried over from '
                'last month',
            if (month.carryOverAdjustmentCents != 0)
              '(incl. ${formatSignedCents(month.carryOverAdjustmentCents)} '
                  'correction)',
          ].join(' ');
    // Tracked expenses mean the plan was locked in before and is being edited.
    final isEditing = expenses.isNotEmpty;
    final (title, intro) = switch ((isLocked, isEditing)) {
      (true, _) => (
          'Your plan',
          '$monthName is locked in. Unlock it to make changes.',
        ),
      (false, true) => (
          'Edit your plan',
          'Make your changes, then lock $monthName in again to keep '
              'tracking.',
        ),
      (false, false) => ('Welcome!', "Let's plan $monthName."),
    };
    final spent = spentByBudget(expenses);
    final lockBlocker = switch (leftCents) {
      _ when availableCents == 0 || budgets.isEmpty =>
        'Add your income and budgets before locking in.',
      > 0 =>
        'Assign the remaining ${formatCents(leftCents)} before locking in.',
      < 0 => 'Take ${formatCents(-leftCents)} off your budgets before locking '
          'in.',
      _ => null,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: textTheme.headlineMedium),
                ),
                const HistoryButton(),
                if (!isLocked)
                  IconButton(
                    tooltip: "Copy last month's plan",
                    icon: const Icon(Icons.content_copy_outlined),
                    onPressed: () => _copyPlanFromMonthBefore(context, ref),
                  ),
                if (isLocked)
                  OutlinedButton.icon(
                    onPressed: () => _editPlan(context, ref),
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Edit plan'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(intro, style: textTheme.bodyLarge),
            const SizedBox(height: 24),
            if (!isLocked) const _GuidedPlanningCard(),
            // Notes stay editable once locked in, for reminders that come up
            // during the month.
            _NotesCard(
              notes: month.notes,
              onEdit: () => _editNotes(context, ref),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Income this month',
                                style: textTheme.labelLarge,
                              ),
                              Text(
                                formatCents(month.incomeCents),
                                style: textTheme.headlineSmall,
                              ),
                              // Shown while editing even when it's 0, so it can
                              // be corrected.
                              if (month.carryOverCents != 0 || !isLocked)
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        carryOverText,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ),
                                    if (!isLocked)
                                      IconButton(
                                        tooltip: 'Correct carryover',
                                        visualDensity: VisualDensity.compact,
                                        iconSize: 18,
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () =>
                                            _editCarryOver(context, ref),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (!isLocked)
                          FilledButton.tonal(
                            onPressed: () =>
                                promptAddIncome(context, ref, month.id),
                            child: const Text('Add income'),
                          ),
                      ],
                    ),
                    for (final income in incomes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          income.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(formatCents(income.amountCents)),
                        onTap: isLocked
                            ? null
                            : () => promptEditIncome(context, ref, income),
                        trailing: isLocked
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit ${income.name}',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        promptEditIncome(context, ref, income),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete ${income.name}',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => ref
                                        .read(appDatabaseProvider)
                                        .deleteIncome(income.id),
                                  ),
                                ],
                              ),
                      ),
                  ],
                ),
              ),
            ),
            _LeftToAssignCard(
              availableCents: availableCents,
              leftCents: leftCents,
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
                Expanded(child: Text('Budgets', style: textTheme.titleLarge)),
                if (!isLocked)
                  FilledButton.icon(
                    onPressed: () => promptAddBudget(context, ref, month.id),
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
                  'No budgets yet. Add one for everything your income needs '
                  'to cover, like rent, groceries or savings.',
                  style: textTheme.bodyMedium,
                ),
              )
            else
              for (final budget in budgets)
                Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            budget.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (budget.isFixed) ...[
                          const SizedBox(width: 8),
                          const FixedBadge(),
                        ],
                        if (budget.isSinkingFund) ...[
                          const SizedBox(width: 8),
                          const SinkingFundBadge(),
                        ],
                        if (budget.isSavings) ...[
                          const SizedBox(width: 8),
                          const SavingsBadge(),
                        ],
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
                                onPressed: () =>
                                    confirmDeleteBudget(
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
            if (!isLocked) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: lockBlocker == null
                    ? () => ref.read(appDatabaseProvider).lockMonth(month.id)
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.lock_outline),
                label: Text(isEditing ? 'Lock in changes' : 'Lock in budget'),
              ),
              const SizedBox(height: 8),
              Text(
                lockBlocker ??
                    'Once locked in, fixed budgets count as spent in full and '
                        'you track the rest of your spending for the month.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
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
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Go through your income, giving, the essentials and everything '
              'else, one step at a time.',
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

class _LeftToAssignCard extends StatelessWidget {
  const _LeftToAssignCard({
    required this.availableCents,
    required this.leftCents,
  });

  /// Income plus whatever was carried over from last month.
  final int availableCents;
  final int leftCents;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (background, foreground, message) = switch (leftCents) {
      0 when availableCents == 0 => (
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
          'Start by adding your income for this month.',
        ),
      0 => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
          'Every bit of your income has a job.',
        ),
      > 0 => (
          colors.secondaryContainer,
          colors.onSecondaryContainer,
          'Give this money a job by adding budgets.',
        ),
      _ => (
          colors.errorContainer,
          colors.onErrorContainer,
          "You've budgeted more than you earn this month.",
        ),
    };

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Left to assign',
                style: textTheme.labelLarge?.copyWith(color: foreground),
              ),
              Text(
                formatCents(leftCents),
                style: textTheme.headlineSmall?.copyWith(color: foreground),
              ),
              const SizedBox(height: 4),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}

/// The month's notes, or a prompt to add some.
class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes, required this.onEdit});

  final String? notes;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final notes = this.notes;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.sticky_note_2_outlined),
        title: Text(notes == null ? 'Add notes' : 'Notes'),
        subtitle: Text(
          notes ?? 'Goals for this month, or things to take care of.',
        ),
        onTap: onEdit,
        trailing: IconButton(
          tooltip: notes == null ? 'Add notes' : 'Edit notes',
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

/// Edits the month's [notes], returning the new text.
class _NotesDialog extends StatefulWidget {
  const _NotesDialog({this.notes});

  final String? notes;

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  late final _notes = TextEditingController(text: widget.notes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notes'),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _notes,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Save for the holiday, cancel the gym membership',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          minLines: 4,
          maxLines: 10,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_notes.text),
          child: const Text('Save'),
        ),
      ],
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
