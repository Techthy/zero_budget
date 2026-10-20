import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../month/month_providers.dart';
import '../widgets/budget_order_button.dart';
import '../widgets/budget_sankey.dart';
import '../widgets/leaf_background.dart';
import '../widgets/new_month_card.dart';
import 'expense_screen.dart';
import 'month_stats_card.dart';
import 'spending_widgets.dart';

/// Tracks spending against the month's plan.
class SpendingScreen extends ConsumerWidget {
  const SpendingScreen({super.key});

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
              _SpendingOverview(
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

class _SpendingOverview extends ConsumerWidget {
  const _SpendingOverview({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  Text('Your budget overview', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (!month.isLocked) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: colors.secondaryContainer,
                      child: ListTile(
                        leading: Icon(
                          Icons.lock_open_outlined,
                          color: colors.onSecondaryContainer,
                        ),
                        title: Text(
                          'Tracking is paused while you edit your plan. Lock '
                          'it in on the Plan tab to keep tracking.',
                          style: TextStyle(color: colors.onSecondaryContainer),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  MonthStatsCard(
                    month: month,
                    budgets: budgets,
                    expenses: expenses,
                  ),
                  if (budgets.isNotEmpty)
                    _SankeyCard(
                      month: month,
                      incomes: incomes,
                      budgets: budgets,
                      expenses: expenses,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Budgets', style: textTheme.titleLarge),
                      ),
                      const BudgetOrderButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (budgets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No budgets yet. Plan your budgets first, then track '
                        'what you actually spend here.',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
            // Long press a budget to move it.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: ReorderableBudgetSpendingList(
                budgets: budgets,
                expenses: expenses,
                onDeleteExpense: (expense) =>
                    ref.read(appDatabaseProvider).deleteExpense(expense.id),
                onEditExpense: (expense) => openEditExpense(context, expense),
                // Expenses are only added while tracking.
                onAddExpense: month.isLocked
                    ? (budget) => openAddExpense(context, budgetId: budget.id)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the month's money goes, folded away until it's wanted.
class _SankeyCard extends StatelessWidget {
  const _SankeyCard({
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.account_tree_outlined),
        title: Text(
          'Where your money goes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          BudgetSankey(
            incomes: incomes,
            carryOverCents: month.carryOverCents,
            budgets: budgets,
            spentByBudget: spentByBudget(expenses),
          ),
        ],
      ),
    );
  }
}
