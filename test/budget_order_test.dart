import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/budget_order.dart';
import 'package:zero_budget/data/database.dart';

Budget _budget(int id, String name, {bool isSavings = false}) => Budget(
  id: id,
  monthId: 1,
  name: name,
  amountCents: 1000,
  isFixed: false,
  isSinkingFund: false,
  savedCents: 0,
  isSavings: isSavings,
);

void main() {
  final budgets = [
    _budget(1, 'phone'),
    _budget(2, 'Groceries'),
    _budget(3, 'ETF', isSavings: true),
    _budget(4, 'Rent'),
    _budget(5, 'Car'),
    _budget(6, 'giving'),
    _budget(7, 'Bank savings', isSavings: true),
    _budget(8, 'Utilities'),
    _budget(9, 'Car'),
  ];

  List<String> namesOf(List<Budget> sorted) => [
    for (final budget in sorted) '${budget.name}#${budget.id}',
  ];

  test('by category: giving, the essentials, savings, then A to Z', () {
    expect(namesOf(sortBudgets(budgets, BudgetOrder.category)), [
      'giving#6',
      'Rent#4',
      'Utilities#8',
      'Groceries#2',
      'Bank savings#7',
      'ETF#3',
      'Car#5',
      'Car#9',
      'phone#1',
    ]);
  });

  test('alphabetical ignores case and keeps the same names in order', () {
    expect(namesOf(sortBudgets(budgets, BudgetOrder.alphabetical)), [
      'Bank savings#7',
      'Car#5',
      'Car#9',
      'ETF#3',
      'giving#6',
      'Groceries#2',
      'phone#1',
      'Rent#4',
      'Utilities#8',
    ]);
  });
}
