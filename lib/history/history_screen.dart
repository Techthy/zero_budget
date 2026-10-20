import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../dates.dart';
import '../money.dart';
import '../widgets/async_view.dart';
import '../widgets/leaf_background.dart';
import 'history_providers.dart';
import 'month_history_screen.dart';

/// Past months, to look back at what was planned and spent.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: LeafBackground(
        child: AsyncView(
          value: ref.watch(pastMonthsProvider),
          data: (months) => months.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "No past months yet. Once a month is over, you'll find "
                      'it here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final summary in months)
                          _MonthTile(summary: summary),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (:month, :plannedCents, :spentCents) = summary;
    final leftCents = plannedCents - spentCents;

    return Card(
      child: ListTile(
        title: Text(formatMonth(month.year, month.month)),
        subtitle: Text(
          '${formatCents(spentCents)} spent of '
          '${formatCents(plannedCents)} planned',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatLeftCents(leftCents),
              style: TextStyle(color: leftCents < 0 ? colors.error : null),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MonthHistoryScreen(monthId: month.id),
          ),
        ),
      ),
    );
  }
}
