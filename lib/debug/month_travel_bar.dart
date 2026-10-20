import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dates.dart';
import '../planning/planning_providers.dart';

/// Moves today to earlier or later days, for testing how months carry over
/// and start. Only shown in debug builds.
class MonthTravelBar extends ConsumerWidget {
  const MonthTravelBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final today = ref.watch(todayProvider);
    final offset = ref.watch(dayOffsetProvider);
    final notifier = ref.read(dayOffsetProvider.notifier);

    return Material(
      color: colors.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Start of previous month',
            icon: const Icon(Icons.keyboard_double_arrow_left),
            onPressed: () => notifier.shiftToMonthStart(-1),
          ),
          IconButton(
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => notifier.shiftDays(-1),
          ),
          Text(
            'Debug: ${formatDay(today)} ${today.year}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          IconButton(
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => notifier.shiftDays(1),
          ),
          IconButton(
            tooltip: 'Start of next month',
            icon: const Icon(Icons.keyboard_double_arrow_right),
            onPressed: () => notifier.shiftToMonthStart(1),
          ),
          TextButton(
            onPressed: offset == 0 ? null : notifier.reset,
            child: const Text('Today'),
          ),
        ],
      ),
    );
  }
}
