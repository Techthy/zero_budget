import 'data/database.dart';

/// The budget the guided planning asks for first.
const givingBudgetName = 'Giving';

const rentBudgetName = 'Rent';
const utilitiesBudgetName = 'Utilities';
const groceriesBudgetName = 'Groceries';
const transportationBudgetName = 'Transportation';

/// The essentials the guided planning asks for, in its order.
const essentialBudgetNames = [
  rentBudgetName,
  utilitiesBudgetName,
  groceriesBudgetName,
  transportationBudgetName,
];

/// The budget the guided planning adds for savings, when there's none yet.
const savingsBudgetName = 'Savings';

/// Sorts [budgets] for listing them, see [BudgetOrder].
///
/// By category, giving and the essentials are recognized by their names, like
/// in the guided planning, and savings by being savings budgets. Names are
/// compared ignoring case.
List<Budget> sortBudgets(Iterable<Budget> budgets, BudgetOrder order) {
  int byName(Budget a, Budget b) {
    final names = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return names != 0 ? names : a.id.compareTo(b.id);
  }

  return switch (order) {
    BudgetOrder.alphabetical => budgets.toList()..sort(byName),
    BudgetOrder.category =>
      budgets.toList()..sort((a, b) {
        final groups = _categoryRank(a).compareTo(_categoryRank(b));
        return groups != 0 ? groups : byName(a, b);
      }),
  };
}

/// Where a budget goes by category: giving, then each essential, then
/// savings, then the rest.
int _categoryRank(Budget budget) {
  final name = budget.name.toLowerCase();
  if (name == givingBudgetName.toLowerCase()) return 0;
  final essential = essentialBudgetNames.indexWhere(
    (essential) => essential.toLowerCase() == name,
  );
  if (essential >= 0) return 1 + essential;
  if (budget.isSavings) return 1 + essentialBudgetNames.length;
  return 2 + essentialBudgetNames.length;
}
