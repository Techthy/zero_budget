import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../settings/settings_providers.dart';

/// Picks how budgets are listed, on the plan and while tracking alike.
class BudgetOrderButton extends ConsumerWidget {
  const BudgetOrderButton({super.key, this.showMoveHint = true});

  /// Whether to say that budgets can be moved by long pressing them, on
  /// screens where they can.
  final bool showMoveHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(budgetOrderProvider);

    return PopupMenuButton<BudgetOrder>(
      tooltip: 'Sort budgets',
      // Keeps the highlighted choice inside the rounded corners.
      clipBehavior: Clip.antiAlias,
      icon: const Icon(Icons.sort),
      initialValue: order,
      onSelected: ref.read(appDatabaseProvider).setBudgetOrder,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: BudgetOrder.category,
          checked: order == BudgetOrder.category,
          child: const Text('By category'),
        ),
        CheckedPopupMenuItem(
          value: BudgetOrder.alphabetical,
          checked: order == BudgetOrder.alphabetical,
          child: const Text('A to Z'),
        ),
        CheckedPopupMenuItem(
          value: BudgetOrder.custom,
          checked: order == BudgetOrder.custom,
          child: const Text('Custom'),
        ),
        if (showMoveHint) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            enabled: false,
            child: Text('Long press a budget to move it'),
          ),
        ],
      ],
    );
  }
}
