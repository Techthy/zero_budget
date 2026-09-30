import 'package:flutter/material.dart';

import '../data/database.dart';
import '../dates.dart';
import '../money.dart';
import '../widgets/fixed_badge.dart';

/// Everything spent against everything planned across [budgets].
class SpendingTotalWidget extends StatelessWidget {
  const SpendingTotalWidget({
    super.key,
    required this.budgets,
    required this.expenses,
  });

  final List<Budget> budgets;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final spentCents = expenses.fold(0, (sum, e) => sum + e.amountCents);

    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     // Flexible lets the texts wrap instead of overflowing when the
            //     // card is narrow.
            //     Flexible(
            //       child: Text(
            //         '${formatCents(budgets.fold(0, (sum, b) => sum + availableCents(b)))} available',
            //         style: textTheme.bodyLarge?.copyWith(
            //           color: Theme.of(context).colorScheme.primary,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //     const SizedBox(width: 8),
            //     Flexible(
            //       child: Text(
            //         '${formatCents(spentCents)} spent',
            //         textAlign: TextAlign.end,
            //         style: textTheme.bodyLarge?.copyWith(
            //           color: Theme.of(context).colorScheme.error,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 12),
            SpentVsPlanned(
              plannedCents: budgets.fold(
                0,
                (sum, b) => sum + availableCents(b),
              ),
              spentCents: spentCents,
            ),
          ],
        ),
      ),
    );
  }
}

/// An expandable card per budget showing what was spent from it.
///
/// Expenses get a delete button when [onDeleteExpense] is set.
class BudgetSpendingList extends StatelessWidget {
  const BudgetSpendingList({
    super.key,
    required this.budgets,
    required this.expenses,
    this.onDeleteExpense,
  });

  final List<Budget> budgets;
  final List<Expense> expenses;
  final ValueChanged<Expense>? onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    final expensesByBudget = <int, List<Expense>>{};
    for (final expense in expenses) {
      (expensesByBudget[expense.budgetId] ??= []).add(expense);
    }

    return Column(
      children: [
        for (final budget in budgets)
          _BudgetSpendingCard(
            key: ValueKey(budget.id),
            budget: budget,
            expenses: expensesByBudget[budget.id] ?? const [],
            onDeleteExpense: onDeleteExpense,
          ),
      ],
    );
  }
}

/// Shows how much of [plannedCents] has been spent, and what's left or over.
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
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final leftCents = plannedCents - spentCents;
    final overspent = leftCents < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            //   child: Text(
            //     '${formatCents(spentCents)} of ${formatCents(plannedCents)}',
            //     style: textTheme.bodyMedium,
            //   ),
            // ),
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${formatCents(spentCents)}',
                    textAlign: TextAlign.end,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(' of ', style: textTheme.bodyMedium),
                  Text(
                    '${formatCents(plannedCents)}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              overspent
                  ? '${formatCents(-leftCents)} over'
                  : '${formatCents(leftCents)} left',
              style: textTheme.labelLarge?.copyWith(
                color: overspent ? colors.error : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: plannedCents == 0
              ? (spentCents > 0 ? 1 : 0)
              : (spentCents / plannedCents).clamp(0.0, 1.0),
          color: overspent ? colors.error : null,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _BudgetSpendingCard extends StatelessWidget {
  const _BudgetSpendingCard({
    super.key,
    required this.budget,
    required this.expenses,
    this.onDeleteExpense,
  });

  final Budget budget;
  final List<Expense> expenses;
  final ValueChanged<Expense>? onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    final onDelete = onDeleteExpense;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Flexible(child: Text(budget.name, overflow: TextOverflow.ellipsis)),
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SpentVsPlanned(
                plannedCents: availableCents(budget),
                spentCents: expenses.fold(0, (sum, e) => sum + e.amountCents),
              ),
              if (budget.savedCents != 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Includes ${formatCents(budget.savedCents)} saved in '
                  'earlier months.',
                ),
              ],
            ],
          ),
        ),
        children: [
          if (expenses.isEmpty)
            const ListTile(title: Text('Nothing spent.'))
          else
            for (final expense in expenses)
              ListTile(
                title: Text(
                  expense.title ?? (expense.isFixed ? 'Fixed cost' : 'Expense'),
                ),
                subtitle: Text(
                  [formatDay(expense.spentAt), ?expense.note].join(' · '),
                ),
                // Fixed expenses follow their budget, so they can't be deleted.
                trailing: onDelete == null || expense.isFixed
                    ? Text(formatCents(expense.amountCents))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(formatCents(expense.amountCents)),
                          IconButton(
                            tooltip: 'Delete expense',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => onDelete(expense),
                          ),
                        ],
                      ),
              ),
        ],
      ),
    );
  }
}
