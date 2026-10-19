import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/budget_order.dart';
import 'package:zero_budget/data/database.dart';

Budget _budget(
  int id,
  String name, {
  BudgetCategory category = BudgetCategory.other,
  int position = 0,
}) => Budget(
  id: id,
  monthId: 1,
  name: name,
  amountCents: 1000,
  isFixed: false,
  isSinkingFund: false,
  savedCents: 0,
  category: category,
  position: position,
);

void main() {
  final budgets = [
    _budget(1, 'phone', category: BudgetCategory.essential),
    _budget(2, 'Groceries', category: BudgetCategory.essential),
    _budget(3, 'ETF', category: BudgetCategory.savings),
    _budget(4, 'Rent', category: BudgetCategory.essential),
    _budget(5, 'Car'),
    _budget(6, 'giving', category: BudgetCategory.giving),
    _budget(7, 'Bank savings', category: BudgetCategory.savings),
    _budget(8, 'Utilities', category: BudgetCategory.essential),
    _budget(9, 'Car'),
    // Named like an essential, but not one.
    _budget(10, 'Transportation'),
  ];

  List<String> namesOf(List<Budget> sorted) => [
    for (final budget in sorted) '${budget.name}#${budget.id}',
  ];

  test('by category: giving, the essentials, savings, then the rest', () {
    // The essentials the guided planning asks for come in its order.
    expect(namesOf(sortBudgets(budgets, BudgetOrder.category)), [
      'giving#6',
      'Rent#4',
      'Utilities#8',
      'Groceries#2',
      'phone#1',
      'Bank savings#7',
      'ETF#3',
      'Car#5',
      'Car#9',
      'Transportation#10',
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
      'Transportation#10',
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
