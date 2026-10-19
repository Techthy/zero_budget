import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../dates.dart';
import '../money.dart';
import '../theme/budget_theme.dart';
import '../welcome/welcome_providers.dart';

/// Asks to move on to the next month, from [planAheadDays] before it starts
/// so it can be planned ahead, until the user moves on or says not yet.
/// Shows nothing otherwise.
///
/// A card rather than a dialog, so it stays at hand until it's answered.
class NewMonthCard extends ConsumerWidget {
  const NewMonthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthToOfferProvider).value;
    if (month == null) return const SizedBox.shrink();

    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final monthName = formatMonth(month.year, month.month);
    final daysToStart = DateTime.utc(month.year, month.month)
        .difference(DateTime.utc(today.year, today.month, today.day))
        .inDays;
    final db = ref.read(appDatabaseProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        color: c.highlight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_outlined, color: c.onHighlight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      switch (daysToStart) {
                        <= 0 => '$monthName has started',
                        1 => '$monthName starts tomorrow',
                        _ => '$monthName starts in $daysToStart days',
                      },
                      style: textTheme.titleMedium?.copyWith(
                        color: c.onHighlight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                daysToStart <= 0
                    ? 'Move on to plan it. You can switch back at the top any '
                          'time, to track what is left of this month.'
                    : 'Plan it ahead, so every ${currency.unitName} has a '
                          'job from day one. You can switch back at the top '
                          'any time.',
                style: textTheme.bodyMedium?.copyWith(color: c.onHighlight),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    // Moving to a month still being planned opens the plan.
                    onPressed: () =>
                        db.selectMonth(month, calendar: yearMonthOf(today)),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('Plan $monthName'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: c.onHighlight,
                    ),
                    onPressed: () => db.declineMonth(month),
                    child: const Text('Not yet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
