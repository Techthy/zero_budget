import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../history/history_screen.dart';
import '../welcome/welcome_providers.dart';
import '../widgets/budget_sankey.dart';
import 'spending_providers.dart';
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
      body: SafeArea(
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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget ${formatMonth(month.year, month.month)}',
                        style: textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                const HistoryButton(),
              ],
            ),
            if (month.lockedAt == null) ...[
              const SizedBox(height: 16),
              Card(
                color: colors.secondaryContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.lock_open_outlined,
                    color: colors.onSecondaryContainer,
                  ),
                  title: Text(
                    'Tracking is paused while you edit your plan. Lock it in '
                    'on the Plan tab to keep tracking.',
                    style: TextStyle(color: colors.onSecondaryContainer),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SpendingTotalWidget(budgets: budgets, expenses: expenses),
                    if (budgets.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      BudgetSankey(
                        incomes: incomes,
                        carryOverCents: month.carryOverCents,
                        budgets: budgets,
                        spentByBudget: spentByBudget(expenses),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Budgets', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            if (budgets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No budgets yet. Plan your budgets first, then track what '
                  'you actually spend here.',
                  style: textTheme.bodyMedium,
                ),
              )
            else
              BudgetSpendingList(
                budgets: budgets,
                expenses: expenses,
                onDeleteExpense: (expense) =>
                    ref.read(appDatabaseProvider).deleteExpense(expense.id),
              ),
          ],
        ),
      ),
    );
  }
}
