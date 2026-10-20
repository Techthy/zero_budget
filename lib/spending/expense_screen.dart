import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../budget_order.dart';
import '../data/database.dart';
import '../data/database_provider.dart';
import '../money.dart';
import '../month/month_providers.dart';
import '../settings/settings_providers.dart';
import '../widgets/amount_field.dart';
import '../widgets/async_view.dart';
import '../widgets/budget_order_button.dart';
import '../widgets/leaf_background.dart';

/// Opens the screen to add an expense, with the budget [budgetId] already
/// picked when it's given.
Future<void> openAddExpense(BuildContext context, {int? budgetId}) =>
    _open(context, ExpenseScreen(budgetId: budgetId));

/// Opens the screen to change [expense].
Future<void> openEditExpense(BuildContext context, Expense expense) =>
    _open(context, ExpenseScreen(expense: expense));

Future<void> _open(BuildContext context, ExpenseScreen screen) {
  // A snack bar from the last expense would cover the button to save.
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => screen),
  );
}

/// Notes down an expense quickly: what it was, the amount, a tap on its
/// budget, done. Given an [expense], changes that one instead.
class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key, this.budgetId, this.expense});

  /// The budget picked to start with, if any.
  final int? budgetId;

  /// The expense to change, if any.
  final Expense? expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listed like everywhere else, to find the budget quickly.
    final order = ref.watch(budgetOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(expense == null ? 'New expense' : 'Edit expense'),
      ),
      body: LeafBackground(
        child: AsyncView(
          value: ref.watch(currentMonthDetailsProvider),
          data: (details) => _ExpenseForm(
            // Fixed budgets are spent in full when the plan is locked in.
            budgets: sortBudgets(
              details.budgets.where((b) => !b.isFixed),
              order,
            ),
            // What's left in each budget, as if the expense being changed
            // wasn't there.
            spent: spentByBudget(
              details.expenses.where((e) => e.id != expense?.id),
            ),
            initialBudgetId: expense?.budgetId ?? budgetId,
            expense: expense,
          ),
        ),
      ),
    );
  }
}

/// What the form says an expense is.
typedef _Entry = ({Budget budget, int amountCents, String title, String? note});

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({
    required this.budgets,
    required this.spent,
    this.initialBudgetId,
    this.expense,
  });

  final List<Budget> budgets;

  /// The expense to change, if any.
  final Expense? expense;

  /// The budget picked to start with, if it's one of [budgets].
  final int? initialBudgetId;

  /// Cents spent so far per budget id.
  final Map<int, int> spent;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.expense?.title);
  late final _amount = TextEditingController(
    text: switch (widget.expense) {
      final expense? => formatAmount(expense.amountCents),
      null => '',
    },
  );
  late final _note = TextEditingController(text: widget.expense?.note);
  late int? _budgetId = switch (widget.budgets) {
    final budgets when budgets.any((b) => b.id == widget.initialBudgetId) =>
      widget.initialBudgetId,
    [final only] => only.id,
    _ => null,
  };
  var _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final note = _note.text.trim();
    final entry = (
      budget: widget.budgets.firstWhere((b) => b.id == _budgetId),
      amountCents: parseAmountToCents(_amount.text)!,
      title: _title.text.trim(),
      note: note.isEmpty ? null : note,
    );
    final (message, undo) = switch (widget.expense) {
      final old? => await _change(old, entry),
      null => await _add(entry),
    };

    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          persist: false,
          action: SnackBarAction(label: 'Undo', onPressed: undo),
        ),
      );
  }

  /// Adds [entry] as a new expense; returns what to say, and how to undo it.
  Future<(String, VoidCallback)> _add(_Entry entry) async {
    final db = ref.read(appDatabaseProvider);
    final id = await db.addExpense(
      entry.budget.id,
      entry.amountCents,
      title: entry.title,
      note: entry.note,
    );
    return (
      'Added ${formatCents(entry.amountCents)} to ${entry.budget.name}.',
      () => db.deleteExpense(id),
    );
  }

  /// Changes [old] to [entry]; returns what to say, and how to undo it.
  Future<(String, VoidCallback)> _change(Expense old, _Entry entry) async {
    final db = ref.read(appDatabaseProvider);
    await db.updateExpense(
      old.id,
      budgetId: entry.budget.id,
      amountCents: entry.amountCents,
      title: entry.title,
      note: entry.note,
    );
    return (
      'Saved ${entry.title}.',
      () => db.updateExpense(
        old.id,
        budgetId: old.budgetId,
        amountCents: old.amountCents,
        title: old.title,
        note: old.note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (widget.budgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'All your budgets are fixed costs, which are tracked for you. '
            'Add a budget to your plan to track other spending.',
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      // Clears an error as soon as it's fixed.
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // The amount first: it's what's on the receipt.
                    AmountField(
                      controller: _amount,
                      style: textTheme.headlineMedium,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Expense title',
                        hintText: 'e.g. Weekly groceries',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 100,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Say what this was for'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Spent from',
                            style: textTheme.titleMedium,
                          ),
                        ),
                        // Budgets are moved on the plan or while tracking.
                        const BudgetOrderButton(showMoveHint: false),
                      ],
                    ),
                    _BudgetPicker(
                      budgets: widget.budgets,
                      spent: widget.spent,
                      initialValue: _budgetId,
                      onChanged: (id) => _budgetId = id,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _note,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'e.g. Paid in cash',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 100,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
              // Stays above the keyboard, so saving is always one tap away.
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.check),
                  label: Text(
                    widget.expense == null ? 'Add expense' : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One chip per budget, showing what's left in it.
class _BudgetPicker extends StatelessWidget {
  const _BudgetPicker({
    required this.budgets,
    required this.spent,
    required this.initialValue,
    required this.onChanged,
  });

  final List<Budget> budgets;
  final Map<int, int> spent;
  final int? initialValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FormField<int>(
      initialValue: initialValue,
      validator: (id) => id == null ? 'Pick the budget this came out of' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final budget in budgets)
                ChoiceChip(
                  label: Text.rich(
                    TextSpan(
                      text: budget.name,
                      children: [
                        TextSpan(
                          text: '  ${_leftText(budget)}',
                          style: TextStyle(
                            color: _isOverspent(budget)
                                ? colors.error
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: field.value == budget.id,
                  onSelected: (_) {
                    field.didChange(budget.id);
                    onChanged(budget.id);
                  },
                ),
            ],
          ),
          if (field.errorText case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ),
        ],
      ),
    );
  }

  int _leftCents(Budget budget) =>
      availableCents(budget) - (spent[budget.id] ?? 0);

  bool _isOverspent(Budget budget) => _leftCents(budget) < 0;

  String _leftText(Budget budget) => formatLeftCents(_leftCents(budget));
}
