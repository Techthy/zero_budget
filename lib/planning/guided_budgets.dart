import 'package:flutter/widgets.dart';

import '../budget_order.dart';
import '../data/database.dart';
import '../data/month_math.dart';
import '../money.dart';

/// An amount the guided planning asks for by name, for a budget of its own:
/// giving, one of the essentials, or savings.
///
/// It stands for the month's first budget with the same name, ignoring case,
/// see [AppDatabase.setBudgetByName]. Giving and savings stand for the first
/// budget of their category first, whatever it's called.
class GuidedBudget {
  GuidedBudget(
    this.name, {
    required this.category,
    required this.isFixed,
    required this.helperText,
  });

  final String name;
  final BudgetCategory category;

  /// Whether it's added as a fixed budget, when it's new.
  final bool isFixed;

  final String helperText;
  final controller = TextEditingController();

  /// The amount entered so far; 0 while it's empty.
  int get cents => parseAmountToCents(controller.text) ?? 0;

  /// The month's budget this one stands for, if there's one yet.
  Budget? matchIn(List<Budget> budgets) {
    // There's one of each essential, but one budget can stand for all giving
    // or savings.
    if (category != BudgetCategory.essential) {
      for (final budget in budgets) {
        if (budget.category == category) return budget;
      }
    }
    final lower = name.toLowerCase();
    for (final budget in budgets) {
      if (budget.name.toLowerCase() == lower) return budget;
    }
    return null;
  }

  /// Saves the amount to the month [monthId], see
  /// [AppDatabase.setBudgetByName]. A budget matched by its category keeps its
  /// own name.
  Future<void> saveTo(AppDatabase db, int monthId, List<Budget> budgets) =>
      db.setBudgetByName(
        monthId,
        matchIn(budgets)?.name ?? name,
        cents,
        isFixed: isFixed,
        category: category,
      );
}

/// Everything the guided planning asks for by name, see [GuidedBudget].
class GuidedBudgets {
  final giving = GuidedBudget(
    givingBudgetName,
    category: BudgetCategory.giving,
    isFixed: false,
    helperText: 'Leave empty to skip.',
  );
  final rent = GuidedBudget(
    rentBudgetName,
    category: BudgetCategory.essential,
    isFixed: true,
    helperText: 'Rent or mortgage payment.',
  );
  final utilities = GuidedBudget(
    utilitiesBudgetName,
    category: BudgetCategory.essential,
    isFixed: false,
    helperText: 'Electricity, heating, water, internet and your phone plan.',
  );
  final groceries = GuidedBudget(
    groceriesBudgetName,
    category: BudgetCategory.essential,
    isFixed: false,
    helperText: 'Food and other daily needs.',
  );
  final transportation = GuidedBudget(
    transportationBudgetName,
    category: BudgetCategory.essential,
    isFixed: false,
    helperText:
        'A transit pass, fuel or other costs of getting to work. Leave empty '
        "if you don't need any.",
  );
  final savings = GuidedBudget(
    savingsBudgetName,
    category: BudgetCategory.savings,
    isFixed: true,
    helperText:
        'Fixed, so it counts towards your savings goal in full once you lock '
        'your plan in. Leave empty to skip.',
  );

  /// The essentials, in the order they're asked for.
  List<GuidedBudget> get essentials => [
    rent,
    utilities,
    groceries,
    transportation,
  ];

  List<GuidedBudget> get _all => [giving, ...essentials, savings];

  /// Starts from the amounts of the budgets that are there already.
  void fillFrom(List<Budget> budgets) {
    for (final guided in _all) {
      final budget = guided.matchIn(budgets);
      if (budget != null && budget.amountCents > 0) {
        guided.controller.text = formatAmount(budget.amountCents);
      }
    }
  }

  /// What's left to assign in [month], counting the amounts as they're
  /// entered, before they're saved.
  int leftToAssignCents(Month month, List<Budget> budgets) {
    final standIns = _matchedIds(budgets);
    var assignedCents = 0;
    for (final guided in _all) {
      assignedCents += guided.cents;
    }
    for (final budget in budgets) {
      if (!standIns.contains(budget.id)) assignedCents += budget.amountCents;
    }
    return month.assignableCents - assignedCents;
  }

  /// The budgets none of these stand for: everything else.
  List<Budget> othersIn(List<Budget> budgets) {
    final standIns = _matchedIds(budgets);
    return [
      for (final budget in budgets)
        if (!standIns.contains(budget.id)) budget,
    ];
  }

  Set<int> _matchedIds(List<Budget> budgets) => {
    for (final guided in _all)
      if (guided.matchIn(budgets) case final budget?) budget.id,
  };

  void dispose() {
    for (final guided in _all) {
      guided.controller.dispose();
    }
  }
}
