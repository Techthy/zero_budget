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

  MonthStats statsOn(DateTime today, {List<Budget>? only}) => MonthStats.of(
    month: _october,
    budgets: only ?? budgets,
    expenses: expenses,
    bufferCents: 100000,
    today: today,
  );

  test('sums up the month', () {
    final stats = statsOn(DateTime(2026, 10, 20));

    expect(stats.plannedCents, 206000);
    expect(stats.spentCents, 142000);
    expect(stats.leftCents, 64000);
    // Buffer, income, carryover and the fund's savings, minus all spending.
    expect(stats.bankBalanceCents, 338000);
    expect((stats.savedCents, stats.savingsPlannedCents), (20000, 20000));
    expect(stats.fundsCents, 35000);
    expect((stats.overspentCount, stats.budgetCount), (1, 6));
  });

  test('spreads what everyday budgets have left over the days left', () {
    final stats = statsOn(DateTime(2026, 10, 20));

    // Groceries and transport; the overspent budget doesn't count against
    // them.
    expect(stats.everydayLeftCents, 31000);
    expect(stats.daysLeft, 12);
    expect(stats.perDayCents, 31000 ~/ 12);
  });

  test('has no daily amount once the month is over or without everyday '
      'budgets', () {
    expect(statsOn(DateTime(2026, 11, 1)).perDayCents, isNull);
    expect(
      statsOn(DateTime(2026, 10, 20), only: [budgets.first]).perDayCents,
      isNull,
    );
  });

  test('daysLeftIn counts today and the days after it', () {
    expect(daysLeftIn(2026, 10, DateTime(2026, 9, 29)), 31);
    expect(daysLeftIn(2026, 10, DateTime(2026, 10, 1)), 31);
    expect(daysLeftIn(2026, 10, DateTime(2026, 10, 31, 23, 59)), 1);
    expect(daysLeftIn(2026, 10, DateTime(2026, 11, 1)), isNull);
    expect(daysLeftIn(2028, 2, DateTime(2028, 2, 10)), 20);
  });
}
