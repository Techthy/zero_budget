import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../history/history_screen.dart';
import '../money.dart';
import '../spending/spending_providers.dart';
import '../widgets/amount_field.dart';
import '../widgets/budget_sankey.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/fixed_badge.dart';
import 'welcome_providers.dart';

typedef _IncomeInput = ({String name, int amountCents});
typedef _BudgetInput = ({
  String name,
  int amountCents,
  bool isFixed,
  bool isSinkingFund,
});

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final incomes = ref.watch(currentIncomesProvider);
    final budgets = ref.watch(currentBudgetsProvider);
    final expenses = ref.watch(currentExpensesProvider);

    return Scaffold(
      body: SafeArea(
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

  Future<void> _addIncome(BuildContext context, WidgetRef ref) async {
    final income = await showDialog<_IncomeInput>(
      context: context,
      builder: (_) => const _IncomeDialog(),
    );
    if (income != null) {
      await ref
          .read(appDatabaseProvider)
          .addIncome(month.id, income.name, income.amountCents);
    }
  }

  Future<void> _editIncome(
    BuildContext context,
    WidgetRef ref,
    Income income,
  ) async {
    final edited = await showDialog<_IncomeInput>(
      context: context,
      builder: (_) => _IncomeDialog(income: income),
    );
    if (edited != null) {
      await ref.read(appDatabaseProvider).updateIncome(
            income.id,
            name: edited.name,
            amountCents: edited.amountCents,
          );
    }
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) async {
    final edited = await showDialog<_BudgetInput>(
      context: context,
      builder: (_) => _BudgetDialog(budget: budget),
    );
    if (edited != null) {
      await ref.read(appDatabaseProvider).updateBudget(
            budget.id,
            name: edited.name,
            amountCents: edited.amountCents,
            isFixed: edited.isFixed,
            isSinkingFund: edited.isSinkingFund,
          );
    }
  }

  Future<void> _addBudget(BuildContext context, WidgetRef ref) async {
    final budget = await showDialog<_BudgetInput>(
      context: context,
      builder: (_) => const _BudgetDialog(),
    );
    if (budget != null) {
      await ref.read(appDatabaseProvider).addBudget(
            month.id,
            budget.name,
            budget.amountCents,
            isFixed: budget.isFixed,
            isSinkingFund: budget.isSinkingFund,
          );
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

  Future<void> _deleteBudget(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) async {
    final tracked = expenses.where((e) => e.budgetId == budget.id).toList();
    if (tracked.isNotEmpty || budget.savedCents != 0) {
      final spentCents = tracked.fold(0, (sum, e) => sum + e.amountCents);
      final confirmed = await showConfirmDialog(
        context,
        title: 'Delete ${budget.name}?',
        message: [
          if (tracked.isNotEmpty)
            'This also deletes its ${tracked.length} tracked '
                '${tracked.length == 1 ? 'expense' : 'expenses'} '
                '(${formatCents(spentCents)} spent).',
          if (budget.savedCents != 0)
            'Its ${formatCents(budget.savedCents)} saved goes back into '
                'this month.',
        ].join(' '),
        confirmLabel: 'Delete',
      );
      if (!confirmed) return;
    }
    await ref.read(appDatabaseProvider).deleteBudget(budget.id);
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
                              if (month.carryOverCents != 0)
                                Text(
                                  '${month.carryOverCents > 0 ? '+' : ''}'
                                  '${formatCents(month.carryOverCents)} '
                                  'carried over from last month',
                                  style: textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                        if (!isLocked)
                          FilledButton.tonal(
                            onPressed: () => _addIncome(context, ref),
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
                            : () => _editIncome(context, ref, income),
                        trailing: isLocked
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit ${income.name}',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _editIncome(context, ref, income),
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
                    onPressed: () => _addBudget(context, ref),
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
                        : () => _editBudget(context, ref, budget),
                    trailing: isLocked
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit ${budget.name}',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _editBudget(context, ref, budget),
                              ),
                              IconButton(
                                tooltip: 'Delete ${budget.name}',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    _deleteBudget(context, ref, budget),
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

/// Adds a new income, or edits [income] when one is given.
class _IncomeDialog extends StatefulWidget {
  const _IncomeDialog({this.income});

  final Income? income;

  @override
  State<_IncomeDialog> createState() => _IncomeDialogState();
}

class _IncomeDialogState extends State<_IncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.income?.name);
  late final _amount = TextEditingController(
    text: switch (widget.income) {
      final income? => formatCents(income.amountCents),
      null => '',
    },
  );

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final _IncomeInput income = (
      name: _name.text.trim(),
      amountCents: parseAmountToCents(_amount.text)!,
    );
    Navigator.of(context).pop(income);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.income == null;

    return AlertDialog(
      title: Text(isNew ? 'New income' : 'Edit income'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: isNew,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Salary',
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Give this income a name'
                  : null,
            ),
            AmountField(controller: _amount, onSubmitted: (_) => _submit()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(isNew ? 'Add' : 'Save')),
      ],
    );
  }
}

/// Adds a new budget, or edits [budget] when one is given.
class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({this.budget});

  final Budget? budget;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.budget?.name);
  late final _amount = TextEditingController(
    text: switch (widget.budget) {
      final budget? => formatCents(budget.amountCents),
      null => '',
    },
  );
  late var _isFixed = widget.budget?.isFixed ?? false;
  late var _isSinkingFund = widget.budget?.isSinkingFund ?? false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final _BudgetInput budget = (
      name: _name.text.trim(),
      amountCents: parseAmountToCents(_amount.text)!,
      isFixed: _isFixed,
      isSinkingFund: _isSinkingFund,
    );
    Navigator.of(context).pop(budget);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.budget == null;
    final savedCents = widget.budget?.savedCents ?? 0;

    return AlertDialog(
      title: Text(isNew ? 'New budget' : 'Edit budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: isNew,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Rent',
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Give this budget a name'
                  : null,
            ),
            AmountField(controller: _amount, onSubmitted: (_) => _submit()),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fixed cost'),
              subtitle: const Text(
                'Always spent in full, like rent or a phone plan.',
              ),
              value: _isFixed,
              onChanged: (value) => setState(() {
                _isFixed = value;
                if (value) _isSinkingFund = false;
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sinking fund'),
              subtitle: Text(switch (savedCents) {
                != 0 when !_isSinkingFund =>
                  'Its ${formatCents(savedCents)} saved goes back into this '
                      'month.',
                _ => 'Saves up for costs that don\'t come every month, like '
                    'a yearly insurance fee. What you don\'t spend carries '
                    'over.',
              }),
              value: _isSinkingFund,
              onChanged: (value) => setState(() {
                _isSinkingFund = value;
                if (value) _isFixed = false;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(isNew ? 'Add' : 'Save')),
      ],
    );
  }
}
