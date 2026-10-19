import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/budget_order.dart';
import 'package:zero_budget/data/database.dart';

Budget _budget(
  int id,
  String name, {
  bool isSavings = false,
  int position = 0,
}) => Budget(
  id: id,
  monthId: 1,
  name: name,
  amountCents: 1000,
  isFixed: false,
  isSinkingFund: false,
  savedCents: 0,
  isSavings: isSavings,
  position: position,
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

  test('custom follows the positions, then the order they were added', () {
    final custom = [
      _budget(1, 'Rent', position: 2),
      _budget(2, 'Fun', position: 0),
      _budget(3, 'Giving', position: 1),
      _budget(4, 'Car', position: 1),
    ];
    expect(namesOf(sortBudgets(custom, BudgetOrder.custom)), [
      'Fun#2',
      'Giving#3',
      'Car#4',
      'Rent#1',
    ]);
  });
}
