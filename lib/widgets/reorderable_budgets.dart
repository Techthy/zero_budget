import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../theme/budget_theme.dart';

/// A sliver of budget cards that can be put in any order: long press one and
/// drag it. Dropping it keeps the order on screen as the custom order, see
/// [AppDatabase.setCustomBudgetOrder].
class ReorderableBudgetsSliver extends ConsumerStatefulWidget {
  const ReorderableBudgetsSliver({
    super.key,
    required this.budgets,
    required this.itemBuilder,
  });

  /// The budgets in the order they're shown.
  final List<Budget> budgets;

  /// Builds the card for a budget.
  final Widget Function(BuildContext context, Budget budget) itemBuilder;

  @override
  ConsumerState<ReorderableBudgetsSliver> createState() =>
      _ReorderableBudgetsSliverState();
}

class _ReorderableBudgetsSliverState
    extends ConsumerState<ReorderableBudgetsSliver> {
  /// The order just dropped, shown until the budgets come back in it, so the
  /// list doesn't jump back while it's saved.
  List<int>? _dropped;

  List<int> get _ids => [for (final budget in widget.budgets) budget.id];

  List<Budget> get _shown {
    final dropped = _dropped;
    if (dropped == null) return widget.budgets;
    final byId = {for (final budget in widget.budgets) budget.id: budget};
    return [for (final id in dropped) byId[id]!];
  }

  @override
  void didUpdateWidget(ReorderableBudgetsSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dropped = _dropped;
    if (dropped == null) return;
    final ids = _ids;
    // Saved, or budgets were added or removed meanwhile.
    if (listEquals(ids, dropped) || !setEquals(ids.toSet(), dropped.toSet())) {
      _dropped = null;
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex == oldIndex) return;
    final ids = [for (final budget in _shown) budget.id];
    ids.insert(newIndex, ids.removeAt(oldIndex));
    setState(() => _dropped = ids);
    ref.read(appDatabaseProvider).setCustomBudgetOrder(ids).catchError((_) {
      if (mounted) setState(() => _dropped = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;

    return SliverReorderableList(
      itemCount: shown.length,
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorderItem: _onReorder,
      // The picked up card floats above the others.
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Stack(
          children: [
            Positioned.fill(
              // Cards keep a margin of 4 around them.
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Opacity(
                  opacity: Curves.easeOut.transform(animation.value),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BudgetRadius.md,
                      boxShadow: context.budgetShadows.lg,
                    ),
                  ),
                ),
              ),
            ),
            child!,
          ],
        ),
        child: child,
      ),
      itemBuilder: (context, index) {
        final budget = shown[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(budget.id),
          index: index,
          child: widget.itemBuilder(context, budget),
        );
      },
    );
  }
}
