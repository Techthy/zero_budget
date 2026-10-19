import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../money.dart';
import '../theme/budget_theme.dart';
import '../widgets/amount_field.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/fixed_badge.dart';

// Adding and changing the incomes and budgets of a month's plan, shared by
// the plan screen and the guided planning.

typedef _IncomeInput = ({String name, int amountCents});
typedef _BudgetInput = ({
  String name,
  int amountCents,
  bool isFixed,
  bool isSinkingFund,
  BudgetCategory category,
});

/// Asks for a new income and adds it to the month [monthId].
Future<void> promptAddIncome(
  BuildContext context,
  WidgetRef ref,
  int monthId,
) async {
  final income = await showDialog<_IncomeInput>(
    context: context,
    builder: (_) => const _IncomeDialog(),
  );
  if (income != null) {
    await ref
        .read(appDatabaseProvider)
        .addIncome(monthId, income.name, income.amountCents);
  }
}

/// Edits [income] in a dialog.
Future<void> promptEditIncome(
  BuildContext context,
  WidgetRef ref,
  Income income,
) async {
  final edited = await showDialog<_IncomeInput>(
    context: context,
    builder: (_) => _IncomeDialog(income: income),
  );
  if (edited != null) {
    await ref
        .read(appDatabaseProvider)
        .updateIncome(
          income.id,
          name: edited.name,
          amountCents: edited.amountCents,
        );
  }
}

/// Asks for a new budget and adds it to the month [monthId].
Future<void> promptAddBudget(
  BuildContext context,
  WidgetRef ref,
  int monthId,
) async {
  final budget = await showDialog<_BudgetInput>(
    context: context,
    builder: (_) => const _BudgetDialog(),
  );
  if (budget != null) {
    await ref
        .read(appDatabaseProvider)
        .addBudget(
          monthId,
          budget.name,
          budget.amountCents,
          isFixed: budget.isFixed,
          isSinkingFund: budget.isSinkingFund,
          category: budget.category,
        );
  }
}

/// Edits [budget] in a dialog.
Future<void> promptEditBudget(
  BuildContext context,
  WidgetRef ref,
  Budget budget,
) async {
  final edited = await showDialog<_BudgetInput>(
    context: context,
    builder: (_) => _BudgetDialog(budget: budget),
  );
  if (edited != null) {
    await ref
        .read(appDatabaseProvider)
        .updateBudget(
          budget.id,
          name: edited.name,
          amountCents: edited.amountCents,
          isFixed: edited.isFixed,
          isSinkingFund: edited.isSinkingFund,
          category: edited.category,
        );
  }
}

/// Deletes [budget], first asking to confirm if it has tracked [expenses]
/// or holds savings.
Future<void> confirmDeleteBudget(
  BuildContext context,
  WidgetRef ref,
  Budget budget,
  List<Expense> expenses,
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
      final income? => formatAmount(income.amountCents),
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
      final budget? => formatAmount(budget.amountCents),
      null => '',
    },
  );
  late var _isFixed = widget.budget?.isFixed ?? false;
  late var _isSinkingFund = widget.budget?.isSinkingFund ?? false;
  late var _category = widget.budget?.category ?? BudgetCategory.other;

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
      category: _category,
    );
    Navigator.of(context).pop(budget);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final isNew = widget.budget == null;
    final savedCents = widget.budget?.savedCents ?? 0;

    return AlertDialog(
      scrollable: true,
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
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('Category', style: textTheme.titleSmall),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in BudgetCategory.values)
                    ChoiceChip(
                      label: Text(categoryLabel(category)),
                      selected: _category == category,
                      onSelected: (_) => setState(() {
                        _category = category;
                        if (category == BudgetCategory.savings) {
                          _isSinkingFund = false;
                        }
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              switch (_category) {
                BudgetCategory.giving =>
                  'Given away, like to a charity or your church. Comes first '
                      'in your plan.',
                BudgetCategory.essential =>
                  'Needed to live and work, like rent, groceries or getting '
                      'to work.',
                BudgetCategory.savings =>
                  'Counts towards your savings goal, like a transfer to your '
                      'savings account. Make it fixed to count it in full.',
                BudgetCategory.other =>
                  'Everything else, like insurance, subscriptions or money '
                      'for fun.',
              },
              style: textTheme.bodySmall?.copyWith(color: c.inkMuted),
            ),
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
                _ =>
                  'Saves up for costs that don\'t come every month, like '
                      'a yearly insurance fee. What you don\'t spend carries '
                      'over.',
              }),
              value: _isSinkingFund,
              onChanged: (value) => setState(() {
                _isSinkingFund = value;
                if (value) {
                  _isFixed = false;
                  if (_category == BudgetCategory.savings) {
                    _category = BudgetCategory.other;
                  }
                }
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
