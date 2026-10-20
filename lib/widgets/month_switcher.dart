import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../dates.dart';
import '../planning/planning_providers.dart';

/// Shows the month the user works in, and lets them switch to another one.
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentYearMonthProvider).value;
    final months = ref.watch(selectableMonthsProvider).value ?? const [];
    final today = yearMonthOf(ref.watch(todayProvider));
    if (current == null) return const SizedBox.shrink();

    return PopupMenuButton<YearMonth>(
      tooltip: 'Switch month',
      initialValue: current,
      onSelected: (month) => ref
          .read(appDatabaseProvider)
          .selectMonth(month, calendar: today),
      itemBuilder: (_) => [
        for (final month in months)
          CheckedPopupMenuItem(
            value: month,
            checked: month == current,
            child: Text(
              [
                formatMonth(month.year, month.month),
                if (encodeYearMonth(month) > encodeYearMonth(today)) 'upcoming',
              ].join(' · '),
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              formatMonth(current.year, current.month),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
