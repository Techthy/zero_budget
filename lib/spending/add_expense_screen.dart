import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../money.dart';
import '../welcome/welcome_providers.dart';
import '../widgets/amount_field.dart';
import '../widgets/leaf_background.dart';
import 'spending_providers.dart';

/// Notes down an expense quickly: what it was, the amount, a tap on its
/// budget, done.
class AddExpenseScreen extends ConsumerWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(currentBudgetsProvider);
    final expenses = ref.watch(currentExpensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New expense')),
      body: LeafBackground(
        child: switch ((budgets, expenses)) {
          (AsyncData(value: final budgets), AsyncData(value: final expenses)) =>
            _ExpenseForm(
              // Fixed budgets are spent in full when the plan is locked in.
              budgets: budgets.where((b) => !b.isFixed).toList(),
              spent: spentByBudget(expenses),
            ),
          (AsyncError(:final error), _) ||
          (_, AsyncError(:final error)) =>
            Center(child: Text('Something went wrong: $error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({required this.budgets, required this.spent});

  final List<Budget> budgets;

  /// Cents spent so far per budget id.
  final Map<int, int> spent;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late int? _budgetId =
      widget.budgets.length == 1 ? widget.budgets.single.id : null;
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

    final db = ref.read(appDatabaseProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final budget = widget.budgets.firstWhere((b) => b.id == _budgetId);
    final amountCents = parseAmountToCents(_amount.text)!;
    final note = _note.text.trim();
    final id = await db.addExpense(
      budget.id,
      amountCents,
      title: _title.text.trim(),
      note: note.isEmpty ? null : note,
    );

    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Added ${formatCents(amountCents)} to ${budget.name}.'),
          persist: false,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => db.deleteExpense(id),
          ),
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
                    TextFormField(
                      controller: _title,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Expense title',
                        hintText: 'e.g. Weekly groceries',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: 100,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Say what this was for'
                          : null,
                    ),
                    AmountField(
                      controller: _amount,
                      style: textTheme.headlineMedium,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    Text('Spent from', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
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
                  label: const Text('Add expense'),
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

  String _leftText(Budget budget) => _isOverspent(budget)
      ? '${formatCents(-_leftCents(budget))} over'
      : '${formatCents(_leftCents(budget))} left';
}
