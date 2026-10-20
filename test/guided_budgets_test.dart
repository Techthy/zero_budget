import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/planning/guided_budgets.dart';

const _october = Month(
  id: 1,
  year: 2026,
  month: 10,
  incomeCents: 300000,
  carryOverCents: 0,
  carryOverAdjustmentCents: 0,
  needsSetUp: false,
);

Budget _budget(
  int id,
  String name,
  int amountCents, {
  BudgetCategory category = BudgetCategory.other,
  bool isSinkingFund = false,
}) => Budget(
  id: id,
  monthId: _october.id,
  name: name,
  amountCents: amountCents,
  isFixed: false,
  isSinkingFund: isSinkingFund,
  savedCents: 0,
  category: category,
  position: id,
);

void main() {
  late GuidedBudgets guided;

  setUp(() => guided = GuidedBudgets());
  tearDown(() => guided.dispose());

  final budgets = [
    _budget(1, 'rent', 90000),
    _budget(2, 'Church', 5000, category: BudgetCategory.giving),
    _budget(3, 'ETF', 20000, category: BudgetCategory.savings),
    _budget(4, 'Gym', 3000),
    // Named like savings, but the ETF stands for savings already.
    _budget(5, 'Savings', 1000),
  ];

  test('essentials stand for budgets of their name, ignoring case', () {
    expect(guided.rent.matchIn(budgets)?.id, 1);
    expect(guided.groceries.matchIn(budgets), isNull);
  });

  test('giving and savings stand for a budget of their category first', () {
    expect(guided.giving.matchIn(budgets)?.name, 'Church');
    expect(guided.savings.matchIn(budgets)?.name, 'ETF');
    expect(
      guided.savings.matchIn([_budget(6, 'savings', 2000)])?.id,
      6,
      reason: 'Without a savings budget, the name is matched.',
    );
  });

  test('starts from the amounts of the budgets there already', () {
    guided.fillFrom(budgets);

    expect(guided.rent.controller.text, '900.00');
    expect(guided.giving.controller.text, '50.00');
    expect(guided.savings.controller.text, '200.00');
    expect(guided.groceries.controller.text, isEmpty);
  });

  test('counts amounts as they are typed in what is left to assign', () {
    guided.fillFrom(budgets);
    // 900,00€ rent, 50,00€ giving, 200,00€ savings, and the gym and the
    // other savings budget, which nothing stands for.
    expect(guided.leftToAssignCents(_october, budgets), 300000 - 119000);

    guided.rent.controller.text = '950';
    guided.groceries.controller.text = '400';
    expect(guided.leftToAssignCents(_october, budgets), 300000 - 164000);
  });

  test('everything else is what none of them stand for', () {
    expect(guided.othersIn(budgets).map((b) => b.name), ['Gym', 'Savings']);
  });
}
