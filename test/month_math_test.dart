import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/month_math.dart';

/// 3000,00€ income and 500,00€ carried over.
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
  int savedCents = 0,
}) => Budget(
  id: id,
  monthId: _october.id,
  name: 'Budget $id',
  amountCents: amountCents,
  isFixed: isFixed,
  isSinkingFund: isSinkingFund,
  savedCents: savedCents,
  category: BudgetCategory.other,
  position: id,
);

Expense _expense(int id, int budgetId, int amountCents) => Expense(
  id: id,
  budgetId: budgetId,
  amountCents: amountCents,
  spentAt: DateTime(2026, 10, 5),
  isFixed: false,
);

void main() {
  final rent = _budget(1, 90000, isFixed: true);
  final groceries = _budget(2, 40000);
  // Had 300,00€ saved before October.
  final fund = _budget(3, 10000, isSinkingFund: true, savedCents: 30000);
  final budgets = [rent, groceries, fund];
  final expenses = [
    _expense(1, rent.id, 90000),
    _expense(2, groceries.id, 15000),
    _expense(3, groceries.id, 5000),
    _expense(4, fund.id, 12000),
  ];

  test('a month is locked once its plan is locked in', () {
    expect(_october.isLocked, isFalse);
    expect(
      _october.copyWith(lockedAt: Value(DateTime(2026, 10, 1))).isLocked,
      isTrue,
    );
  });

  test('adds up what the plan assigns, can spend and spent', () {
    expect(_october.assignableCents, 350000);
    expect(totalAssignedCents(budgets), 140000);
    // The fund's savings from before can be spent too.
    expect(availableCents(fund), 40000);
    expect(totalPlannedCents(budgets), 170000);
    expect(leftToAssignCents(_october, budgets), 210000);
    expect(leftToAssignCents(_october, [_budget(4, 400000)]), -50000);
    expect(totalSpentCents(expenses), 122000);
  });

  test('sums and groups expenses per budget', () {
    expect(spentByBudget(expenses), {1: 90000, 2: 20000, 3: 12000});
    expect(groupByBudget(expenses)[groceries.id]?.map((e) => e.id), [2, 3]);
    expect(groupByBudget(expenses)[4], isNull);
  });

  test('a sinking fund keeps what is not spent from it', () {
    expect(fundBalanceCents(fund, 12000), 28000);
  });

  test('a month leaves what was not spent, sinking funds in full', () {
    // 3500,00€ minus rent and groceries as spent, and the fund's 100,00€
    // paid in full, whatever came out of it.
    expect(
      monthBalanceCents(_october, budgets, spentByBudget(expenses)),
      350000 - 90000 - 20000 - 10000,
    );
  });

  test('the bank holds the buffer, the plan and earlier savings, less '
      'everything spent', () {
    expect(
      expectedBankBalanceCents(
        _october,
        budgets,
        expenses,
        bufferCents: 100000,
      ),
      100000 + 350000 + 30000 - 122000,
    );
  });
}
