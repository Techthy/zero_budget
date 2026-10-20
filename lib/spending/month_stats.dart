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
  });

  /// Works the stats out for [month].
  factory MonthStats.of({
    required Month month,
    required List<Budget> budgets,
    required List<Expense> expenses,
    required int bufferCents,
  }) {
    final spent = spentByBudget(expenses);
    var plannedCents = 0;
    var savingsPlannedCents = 0;
    var savedCents = 0;
    var fundsCents = 0;
    var overspentCount = 0;
    var hasSavings = false;
    var hasFunds = false;

    for (final budget in budgets) {
      final spentCents = spent[budget.id] ?? 0;
      final leftCents = availableCents(budget) - spentCents;
      plannedCents += availableCents(budget);
      if (leftCents < 0) overspentCount++;
      final isSavings = budget.category == BudgetCategory.savings;
      if (isSavings) {
        hasSavings = true;
        savingsPlannedCents += budget.amountCents;
        savedCents += spentCents;
      }
      if (budget.isSinkingFund) {
        hasFunds = true;
        fundsCents += fundBalanceCents(budget, spentCents);
      }
    }

    return MonthStats._(
      plannedCents: plannedCents,
      spentCents: totalSpentCents(expenses),
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
}
