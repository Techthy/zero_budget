import 'database.dart';

// What a month's plan and spending add up to, from the rows in the database.
// All amounts are in cents.

/// What a month's plan says about itself.
extension MonthPlan on Month {
  /// Whether the plan is locked in to track spending against it.
  bool get isLocked => lockedAt != null;

  /// All the money the plan gives a job: the income plus what was carried
  /// over.
  int get assignableCents => incomeCents + carryOverCents;
}

/// What can be spent from [budget] this month, including a sinking fund's
/// savings.
int availableCents(Budget budget) => budget.amountCents + budget.savedCents;

/// What [budgets] are assigned, without sinking funds' earlier savings.
int totalAssignedCents(Iterable<Budget> budgets) =>
    budgets.fold(0, (sum, budget) => sum + budget.amountCents);

/// What [budgets] can spend this month, sinking funds' savings included.
int totalPlannedCents(Iterable<Budget> budgets) =>
    budgets.fold(0, (sum, budget) => sum + availableCents(budget));

/// What [month] still has to give a job once [budgets] got theirs; negative
/// when more was assigned than there is.
int leftToAssignCents(Month month, Iterable<Budget> budgets) =>
    month.assignableCents - totalAssignedCents(budgets);

/// What [expenses] add up to.
int totalSpentCents(Iterable<Expense> expenses) =>
    expenses.fold(0, (sum, expense) => sum + expense.amountCents);

/// What a sinking fund has saved once [spentCents] came out of it this month.
int fundBalanceCents(Budget budget, int spentCents) =>
    availableCents(budget) - spentCents;

/// What's left of the month's money at its end, which carries over to the
/// next month.
///
/// Sinking funds count as spent in full: their money stays in the fund.
int monthBalanceCents(
  Month month,
  List<Budget> budgets,
  Map<int, int> spentByBudget,
) {
  var balanceCents = month.assignableCents;
  for (final budget in budgets) {
    balanceCents -= budget.isSinkingFund
        ? budget.amountCents
        : spentByBudget[budget.id] ?? 0;
  }
  return balanceCents;
}

/// What should be in the bank account right now: the buffer, plus the
/// month's income and carryover and whatever sinking funds saved before, minus
/// everything spent so far.
///
/// Assumes all of the month's income has come in already.
int expectedBankBalanceCents(
  Month month,
  List<Budget> budgets,
  Iterable<Expense> expenses, {
  required int bufferCents,
}) {
  var balanceCents = bufferCents + month.assignableCents;
  for (final budget in budgets) {
    balanceCents += budget.savedCents;
  }
  for (final expense in expenses) {
    balanceCents -= expense.amountCents;
  }
  return balanceCents;
}

/// Groups [expenses] by the id of the budget they came out of.
Map<int, List<Expense>> groupByBudget(Iterable<Expense> expenses) {
  final grouped = <int, List<Expense>>{};
  for (final expense in expenses) {
    (grouped[expense.budgetId] ??= []).add(expense);
  }
  return grouped;
}

/// Sums [expenses] per budget id.
Map<int, int> spentByBudget(Iterable<Expense> expenses) {
  final spent = <int, int>{};
  for (final expense in expenses) {
    spent.update(
      expense.budgetId,
      (sum) => sum + expense.amountCents,
      ifAbsent: () => expense.amountCents,
    );
  }
  return spent;
}
