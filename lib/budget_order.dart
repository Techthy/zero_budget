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
/// By category, the essentials the guided planning asks for come in its
/// order, recognized by their names, before any others. Names are compared
/// ignoring case.
List<Budget> sortBudgets(Iterable<Budget> budgets, BudgetOrder order) {
  int byName(Budget a, Budget b) {
    final names = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return names != 0 ? names : a.id.compareTo(b.id);
  }

  return switch (order) {
    BudgetOrder.alphabetical => budgets.toList()..sort(byName),
    BudgetOrder.custom =>
      budgets.toList()..sort((a, b) {
        final positions = a.position.compareTo(b.position);
        return positions != 0 ? positions : a.id.compareTo(b.id);
      }),
    BudgetOrder.category =>
      budgets.toList()..sort((a, b) {
        final categories = a.category.index.compareTo(b.category.index);
        if (categories != 0) return categories;
        final essentials = _essentialRank(a).compareTo(_essentialRank(b));
        return essentials != 0 ? essentials : byName(a, b);
      }),
  };
}

/// Where an essential goes among the essentials: the ones the guided planning
/// asks for in its order, then the rest.
int _essentialRank(Budget budget) {
  if (budget.category != BudgetCategory.essential) return 0;
  final name = budget.name.toLowerCase();
  final index = essentialBudgetNames.indexWhere(
    (essential) => essential.toLowerCase() == name,
  );
  return index >= 0 ? index : essentialBudgetNames.length;
}
