import '../data/database.dart';

/// The numbers shown at the top of the tracking screen, worked out from a
/// month's plan and what was spent so far.
class MonthStats {
  MonthStats._({
    required this.plannedCents,
    required this.spentCents,
    required this.bankBalanceCents,
    required this.savingsPlannedCents,
    required this.savedCents,
    required this.hasSavings,
    required this.fundsCents,
    required this.hasFunds,
    required this.budgetCount,
    required this.overspentCount,
    required this.everydayLeftCents,
    required this.hasEverydayBudgets,
    required this.daysLeft,
  });

  /// Works the stats out for [month] as of [today].
  factory MonthStats.of({
    required Month month,
    required List<Budget> budgets,
    required List<Expense> expenses,
    required int bufferCents,
    required DateTime today,
  }) {
    final spent = spentByBudget(expenses);
    var plannedCents = 0;
    var savingsPlannedCents = 0;
    var savedCents = 0;
    var fundsCents = 0;
    var overspentCount = 0;
    var everydayLeftCents = 0;
    var hasSavings = false;
    var hasFunds = false;
    var hasEverydayBudgets = false;

    for (final budget in budgets) {
      final spentCents = spent[budget.id] ?? 0;
      final leftCents = availableCents(budget) - spentCents;
      plannedCents += availableCents(budget);
      if (leftCents < 0) overspentCount++;
      if (budget.isSavings) {
        hasSavings = true;
        savingsPlannedCents += budget.amountCents;
        savedCents += spentCents;
      }
      if (budget.isSinkingFund) {
        hasFunds = true;
        fundsCents += fundBalanceCents(budget, spentCents);
      }
      if (!budget.isFixed && !budget.isSinkingFund && !budget.isSavings) {
        hasEverydayBudgets = true;
        // An overspent budget doesn't take from the others.
        if (leftCents > 0) everydayLeftCents += leftCents;
      }
    }

    return MonthStats._(
      plannedCents: plannedCents,
      spentCents: expenses.fold(0, (sum, e) => sum + e.amountCents),
      bankBalanceCents: expectedBankBalanceCents(
        month,
        budgets,
        expenses,
        bufferCents: bufferCents,
      ),
      savingsPlannedCents: savingsPlannedCents,
      savedCents: savedCents,
      hasSavings: hasSavings,
      fundsCents: fundsCents,
      hasFunds: hasFunds,
      budgetCount: budgets.length,
      overspentCount: overspentCount,
      everydayLeftCents: everydayLeftCents,
      hasEverydayBudgets: hasEverydayBudgets,
      daysLeft: daysLeftIn(month.year, month.month, today),
    );
  }

  /// What all budgets have to spend, sinking funds' savings included.
  final int plannedCents;

  /// Everything spent so far, fixed costs included.
  final int spentCents;

  /// Left to spend across all budgets; negative when over budget.
  int get leftCents => plannedCents - spentCents;

  /// What should be in the bank account right now, buffer included.
  final int bankBalanceCents;

  /// What savings budgets plan to save, and what they saved so far.
  final int savingsPlannedCents;
  final int savedCents;
  final bool hasSavings;

  /// What all sinking funds hold right now.
  final int fundsCents;
  final bool hasFunds;

  final int budgetCount;

  /// Budgets that spent more than they had.
  final int overspentCount;

  /// What's left in everyday budgets: not fixed, not a sinking fund, not
  /// savings. Overspent ones count as 0.
  final int everydayLeftCents;
  final bool hasEverydayBudgets;

  /// Days left in the month, today included; null once it's over.
  final int? daysLeft;

  /// What can be spent from everyday budgets each day for the rest of the
  /// month; null once it's over, or without everyday budgets.
  int? get perDayCents => switch (daysLeft) {
    final days? when days > 0 && hasEverydayBudgets =>
      everydayLeftCents ~/ days,
    _ => null,
  };
}

/// Days left in [year]/[month] as of [today], today included: all of them
/// before it starts, and null once it's over.
int? daysLeftIn(int year, int month, DateTime today) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final day = DateTime(today.year, today.month, today.day);
  if (day.isBefore(DateTime(year, month))) return daysInMonth;
  if (!day.isBefore(DateTime(year, month + 1))) return null;
  return daysInMonth - day.day + 1;
}
