import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../budget_order.dart';
import '../data/database.dart';
import '../data/month_math.dart';
import '../dates.dart';
import '../money.dart';
import '../settings/settings_providers.dart';
import '../theme/budget_theme.dart';
import '../widgets/budget_badges.dart';
import '../widgets/reorderable_budgets.dart';

/// Everything spent against everything planned across [budgets].
class SpendingTotal extends StatelessWidget {
  const SpendingTotal({
    super.key,
    required this.budgets,
    required this.expenses,
  });

  final List<Budget> budgets;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final spentCents = totalSpentCents(expenses);
    final plannedCents = totalPlannedCents(budgets);
    final leftCents = plannedCents - spentCents;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            leftCents < 0 ? 'Over budget' : 'Left to spend',
            style: textTheme.titleMedium?.copyWith(color: c.inkMuted),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              formatCents(leftCents.abs()),
              style: textTheme.headlineMedium?.copyWith(
                color: leftCents < 0 ? c.danger : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SpentVsPlanned(plannedCents: plannedCents, spentCents: spentCents),
        ],
      ),
    );
  }
}

/// A card per budget showing what was spent from it, which opens up to list
/// its expenses, to look back at. Budgets are listed in the order picked in
/// the settings, see [BudgetOrder].
class BudgetSpendingList extends ConsumerWidget {
  const BudgetSpendingList({
    super.key,
    required this.budgets,
    required this.expenses,
  });

  final List<Budget> budgets;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(budgetOrderProvider);
    final expensesByBudget = groupByBudget(expenses);

    return Column(
      children: [
        for (final budget in sortBudgets(budgets, order))
          _BudgetSpendingCard(
            key: ValueKey(budget.id),
            budget: budget,
            expenses: expensesByBudget[budget.id] ?? const [],
          ),
      ],
    );
  }
}

/// Like [BudgetSpendingList], for the month being tracked: a sliver whose
/// budgets can be moved by long pressing one and dragging it, see
/// [ReorderableBudgetsSliver].
///
/// Expenses get an edit button when [onEditExpense] is set and a delete
/// button when [onDeleteExpense] is set, and budgets that take expenses get a
/// button to add one when [onAddExpense] is set. Fixed expenses follow their
/// budget, so they get neither.
class ReorderableBudgetSpendingList extends ConsumerWidget {
  const ReorderableBudgetSpendingList({
    super.key,
    required this.budgets,
    required this.expenses,
    this.onDeleteExpense,
    this.onEditExpense,
    this.onAddExpense,
  });

  final List<Budget> budgets;
  final List<Expense> expenses;
  final ValueChanged<Expense>? onDeleteExpense;
  final ValueChanged<Expense>? onEditExpense;
  final ValueChanged<Budget>? onAddExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(budgetOrderProvider);
    final expensesByBudget = groupByBudget(expenses);

    return ReorderableBudgetsSliver(
      budgets: sortBudgets(budgets, order),
      itemBuilder: (context, budget) => _BudgetSpendingCard(
        budget: budget,
        expenses: expensesByBudget[budget.id] ?? const [],
        onDeleteExpense: onDeleteExpense,
        onEditExpense: onEditExpense,
        onAddExpense: onAddExpense,
      ),
    );
  }
}

/// A bar of how much of [plannedCents] has been spent, with what was spent
/// below it on the left and the total on the right.
class SpentVsPlanned extends StatelessWidget {
  const SpentVsPlanned({
    super.key,
    required this.plannedCents,
    required this.spentCents,
  });

  final int plannedCents;
  final int spentCents;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final overspent = spentCents > plannedCents;
    final caption = textTheme.bodySmall?.copyWith(color: c.inkMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: plannedCents == 0
              ? (spentCents > 0 ? 1 : 0)
              : (spentCents / plannedCents).clamp(0.0, 1.0),
          color: overspent ? c.danger : null,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '${formatCents(spentCents)} spent',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: overspent ? caption?.copyWith(color: c.danger) : caption,
              ),
            ),
            const SizedBox(width: 8),
            Text('of ${formatCents(plannedCents)}', style: caption),
          ],
        ),
      ],
    );
  }
}

/// A budget's name, what's left in it and its kind, and how much of it was
/// spent. Tapping it lists its expenses.
class _BudgetSpendingCard extends StatefulWidget {
  const _BudgetSpendingCard({
    super.key,
    required this.budget,
    required this.expenses,
    this.onDeleteExpense,
    this.onEditExpense,
    this.onAddExpense,
  });

  final Budget budget;
  final List<Expense> expenses;
  final ValueChanged<Expense>? onDeleteExpense;
  final ValueChanged<Expense>? onEditExpense;
  final ValueChanged<Budget>? onAddExpense;

  @override
  State<_BudgetSpendingCard> createState() => _BudgetSpendingCardState();
}

class _BudgetSpendingCardState extends State<_BudgetSpendingCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final budget = widget.budget;
    final expenses = widget.expenses;
    final onDelete = widget.onDeleteExpense;
    final onEdit = widget.onEditExpense;
    final onAdd = widget.onAddExpense;
    final plannedCents = availableCents(budget);
    final spentCents = totalSpentCents(expenses);
    final leftCents = plannedCents - spentCents;

    final (leftText, leftColor) = switch (leftCents) {
      < 0 => (formatLeftCents(leftCents), c.danger),
      // Fixed costs are spent in full once the plan is locked in.
      0 when budget.isFixed && plannedCents > 0 => ('Paid in full', c.inkMuted),
      _ => (formatLeftCents(leftCents), c.forestDeep),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          budget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more, color: c.inkMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          leftText,
                          style: textTheme.labelLarge?.copyWith(
                            color: leftColor,
                          ),
                        ),
                        ...budgetBadges(budget),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: SpentVsPlanned(
                      plannedCents: plannedCents,
                      spentCents: spentCents,
                    ),
                  ),
                  if (budget.savedCents != 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Includes ${formatCents(budget.savedCents)} saved in '
                      'earlier months',
                      style: textTheme.bodySmall?.copyWith(color: c.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1),
                      if (expenses.isEmpty)
                        const ListTile(title: Text('Nothing spent yet.'))
                      else
                        for (final expense in expenses)
                          ListTile(
                            title: Text(
                              expense.title ??
                                  (expense.isFixed ? 'Fixed cost' : 'Expense'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                formatDay(expense.spentAt),
                                ?expense.note,
                              ].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: onEdit == null || expense.isFixed
                                ? null
                                : () => onEdit(expense),
                            // Fixed expenses follow their budget, so they
                            // can't be changed.
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatCents(expense.amountCents)),
                                if (onEdit != null && !expense.isFixed)
                                  IconButton(
                                    tooltip: 'Edit expense',
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => onEdit(expense),
                                  ),
                                if (onDelete != null && !expense.isFixed)
                                  IconButton(
                                    tooltip: 'Delete expense',
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => onDelete(expense),
                                  ),
                              ],
                            ),
                          ),
                      // Fixed costs are tracked for you.
                      if (onAdd != null && !budget.isFixed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: OutlinedButton.icon(
                              onPressed: () => onAdd(budget),
                              icon: const Icon(Icons.add),
                              label: const Text('Add expense'),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
