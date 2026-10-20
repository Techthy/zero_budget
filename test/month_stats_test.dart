import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/spending/month_stats.dart';

const _october = Month(
  id: 1,
  year: 2026,
  month: 10,
  incomeCents: 300000,
  carryOverCents: 50000,
  carryOverAdjustmentCents: 0,
  needsSetUp: false,
);

Budget _budget(
  int id,
  int amountCents, {
  bool isFixed = false,
  bool isSinkingFund = false,
  BudgetCategory category = BudgetCategory.other,
  int savedCents = 0,
}) => Budget(
  id: id,
  monthId: _october.id,
  name: 'Budget $id',
  amountCents: amountCents,
  isFixed: isFixed,
  isSinkingFund: isSinkingFund,
  savedCents: savedCents,
  category: category,
  position: id,
);

Expense _expense(int budgetId, int amountCents) => Expense(
  id: budgetId * 100 + amountCents,
  budgetId: budgetId,
  amountCents: amountCents,
  spentAt: DateTime(2026, 10, 5),
  isFixed: false,
);

void main() {
  final budgets = [
    _budget(1, 90000, isFixed: true), // Rent
    _budget(2, 40000), // Groceries
    _budget(3, 10000), // Fun, overspent
    _budget(4, 20000, isFixed: true, category: BudgetCategory.savings),
    _budget(5, 10000, isSinkingFund: true, savedCents: 30000),
    _budget(6, 6000), // Transport, nothing spent yet
  ];
  final expenses = [
    _expense(1, 90000),
    _expense(2, 15000),
    _expense(3, 12000),
    _expense(4, 20000),
    _expense(5, 5000),
  ];

  MonthStats statsOf() => MonthStats.of(
    month: _october,
    budgets: budgets,
    expenses: expenses,
    bufferCents: 100000,
  );

  test('sums up the month', () {
    final stats = statsOf();

    expect(stats.plannedCents, 206000);
    expect(stats.spentCents, 142000);
    expect(stats.leftCents, 64000);
    // Buffer, income, carryover and the fund's savings, minus all spending.
    expect(stats.bankBalanceCents, 338000);
    expect((stats.savedCents, stats.savingsPlannedCents), (20000, 20000));
    expect(stats.fundsCents, 35000);
    expect((stats.overspentCount, stats.budgetCount), (1, 6));
  });
}
