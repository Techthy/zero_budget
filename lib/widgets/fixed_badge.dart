import 'package:flutter/material.dart';

/// Marks a budget that is always spent in full.
class FixedBadge extends StatelessWidget {
  const FixedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Badge(
      label: 'Fixed',
      background: colors.tertiaryContainer,
      foreground: colors.onTertiaryContainer,
    );
  }
}

/// Marks a budget that saves up over several months.
class SinkingFundBadge extends StatelessWidget {
  const SinkingFundBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Badge(
      label: 'Sinking fund',
      background: colors.secondaryContainer,
      foreground: colors.onSecondaryContainer,
    );
  }
}

/// Marks a budget that counts towards the savings goal.
class SavingsBadge extends StatelessWidget {
  const SavingsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Badge(
      label: 'Savings',
      background: colors.primaryContainer,
      foreground: colors.onPrimaryContainer,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}
