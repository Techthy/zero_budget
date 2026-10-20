import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/month_math.dart';
import '../dates.dart';
import '../money.dart';
import '../month/month_providers.dart';
import '../spending/spending_widgets.dart';
import '../widgets/async_view.dart';
import '../widgets/budget_sankey.dart';
import '../widgets/leaf_background.dart';

/// A read-only look back at one month's plan and spending.
class MonthHistoryScreen extends ConsumerWidget {
  const MonthHistoryScreen({super.key, required this.monthId});

  final int monthId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(monthDetailsProvider(monthId));

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (details.value?.month) {
          final month? => formatMonth(month.year, month.month),
          null => 'History',
        }),
      ),
      body: LeafBackground(
        child: AsyncView(
          value: details,
          data: (details) => _MonthReview(
            month: details.month,
            incomes: details.incomes,
            budgets: details.budgets,
            expenses: details.expenses,
          ),
        ),
      ),
    );
  }
}

class _MonthReview extends StatelessWidget {
  const _MonthReview({
    required this.month,
    required this.incomes,
    required this.budgets,
    required this.expenses,
  });

  final Month month;
  final List<Income> incomes;
  final List<Budget> budgets;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    if (incomes.length > 1)
                      for (final income in incomes)
                        _AmountRow(
                          label: income.name,
                          cents: income.amountCents,
                        ),
                    _AmountRow(
                      label: incomes.length > 1 ? 'Total income' : 'Income',
                      cents: month.incomeCents,
                    ),
                    if (month.carryOverCents != 0)
                      _AmountRow(
                        label: 'Carried over',
                        cents: month.carryOverCents,
                      ),
                    _AmountRow(
                      label: 'Planned',
                      cents: totalAssignedCents(budgets),
                    ),
                    _AmountRow(
                      label: 'Balance at month end',
                      cents: monthBalanceCents(
                        month,
                        budgets,
                        spentByBudget(expenses),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SpendingTotal(budgets: budgets, expenses: expenses),
            if (month.notes case final notes?) ...[
              const SizedBox(height: 24),
              Text('Notes', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(notes, style: textTheme.bodyMedium),
                ),
              ),
            ],
            if (budgets.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Where the money went', style: textTheme.titleLarge),
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
            Text('Budgets', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            if (budgets.isEmpty)
              Text(
                'Nothing was planned this month.',
                style: textTheme.bodyMedium,
              )
            else
              BudgetSpendingList(budgets: budgets, expenses: expenses),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.cents});

  final String label;
  final int cents;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        formatCents(cents),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
