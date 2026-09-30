import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dates.dart';
import '../welcome/welcome_providers.dart';

/// Moves the app to earlier or later months, for testing how months carry
/// over. Only shown in debug builds.
class MonthTravelBar extends ConsumerWidget {
  const MonthTravelBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final (:year, :month) = ref.watch(currentYearMonthProvider);
    final offset = ref.watch(monthOffsetProvider);
    final notifier = ref.read(monthOffsetProvider.notifier);

    return Material(
      color: colors.surfaceContainerHighest,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
              onPressed: notifier.previous,
            ),
            Text(
              'Debug: ${formatMonth(year, month)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            IconButton(
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
              onPressed: notifier.next,
            ),
            TextButton(
              onPressed: offset == 0 ? null : notifier.reset,
              child: const Text('Today'),
            ),
          ],
        ),
      ),
    );
  }
}
