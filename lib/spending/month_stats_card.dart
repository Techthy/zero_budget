import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../money.dart';
import '../theme/budget_theme.dart';
import '../welcome/welcome_providers.dart';
import 'month_stats.dart';
import 'spending_providers.dart';
import 'spending_widgets.dart';

/// The month at a glance: what's left to spend, then a few numbers that help
/// keep on track.
class MonthStatsCard extends ConsumerWidget {
  const MonthStatsCard({
    super.key,
    required this.month,
    required this.budgets,
    required this.expenses,
  });

  final Month month;
  final List<Budget> budgets;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final bufferCents = ref.watch(bufferCentsProvider).value;
    final stats = MonthStats.of(
      month: month,
      budgets: budgets,
      expenses: expenses,
      bufferCents: bufferCents ?? 0,
      today: ref.watch(todayProvider),
    );
    final overBudget = stats.leftCents < 0;

    final tiles = [
      // Showing a balance without the right buffer would be misleading.
      if (bufferCents != null)
        _StatTile(
          icon: Icons.account_balance_outlined,
          label: 'Bank balance',
          value: formatCents(stats.bankBalanceCents),
          caption: 'Expected now, incl. ${formatCents(bufferCents)} buffer',
        ),
      if (stats.perDayCents case final perDayCents?)
        _StatTile(
          icon: Icons.today_outlined,
          label: 'Per day',
          value: formatCents(perDayCents),
          caption: switch (stats.daysLeft) {
            1 => 'Left in everyday budgets for today',
            final days => 'Left in everyday budgets for $days days',
          },
        ),
      if (stats.hasSavings)
        _StatTile(
          icon: Icons.savings_outlined,
          label: 'Saved',
          value: formatCents(stats.savedCents),
          caption: 'of ${formatCents(stats.savingsPlannedCents)} planned',
        ),
      if (stats.budgetCount > 0)
        _StatTile(
          icon: stats.overspentCount == 0
              ? Icons.check_circle_outline
              : Icons.warning_amber_rounded,
          label: 'On track',
          value:
              '${stats.budgetCount - stats.overspentCount} of '
              '${stats.budgetCount}',
          valueColor: stats.overspentCount == 0 ? null : c.danger,
          caption: switch (stats.overspentCount) {
            0 => 'No budget is over',
            1 => '1 budget is over',
            final count => '$count budgets are over',
          },
        ),
      if (stats.hasFunds)
        _StatTile(
          icon: Icons.inventory_2_outlined,
          label: 'Sinking funds',
          value: formatCents(stats.fundsCents),
          caption: 'Set aside for costs to come',
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              overBudget ? 'Over budget' : 'Left to spend',
              style: textTheme.titleMedium?.copyWith(color: c.inkMuted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                formatCents(stats.leftCents.abs()),
                style: textTheme.headlineMedium?.copyWith(
                  color: overBudget ? c.danger : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SpentVsPlanned(
              plannedCents: stats.plannedCents,
              spentCents: stats.spentCents,
            ),
            if (tiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              _TileGrid(tiles: tiles),
            ],
          ],
        ),
      ),
    );
  }
}

/// Two tiles a row, or one on narrow screens. An odd last tile takes the full
/// row.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 280 ? 2 : 1;
        return Column(
          children: [
            for (var i = 0; i < tiles.length; i += columns) ...[
              if (i > 0) const SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var j = i;
                      j < i + columns && j < tiles.length;
                      j++
                    ) ...[
                      if (j > i) const SizedBox(width: gap),
                      Expanded(child: tiles[j]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BudgetRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: c.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: textTheme.titleLarge?.copyWith(color: valueColor),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
