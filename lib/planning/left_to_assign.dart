import 'package:flutter/material.dart';

import '../money.dart';
import '../theme/budget_theme.dart';
import 'zero_based_help.dart';

/// What's still without a job in the month's plan, coloured by how the plan
/// stands: nothing to assign yet, every bit assigned, some left, or more
/// assigned than there is.
class LeftToAssign extends StatelessWidget {
  /// The full banner, with what to do next and a link to how a zero-based
  /// budget works.
  const LeftToAssign({
    super.key,
    required this.leftCents,
    required this.assignableCents,
  }) : _isCompact = false;

  /// A single line, to keep in view while planning step by step.
  const LeftToAssign.compact({
    super.key,
    required this.leftCents,
    required this.assignableCents,
  }) : _isCompact = true;

  /// Negative when more was assigned than there is.
  final int leftCents;

  /// Income plus whatever was carried over from last month.
  final int assignableCents;

  final bool _isCompact;

  @override
  Widget build(BuildContext context) {
    final look = _Look.of(context, _standing);
    return _isCompact
        ? _CompactBanner(look, leftCents)
        : _Banner(look, leftCents);
  }

  _Standing get _standing => switch (leftCents) {
    0 when assignableCents == 0 => _Standing.nothingYet,
    0 => _Standing.allAssigned,
    > 0 => _Standing.someLeft,
    _ => _Standing.overAssigned,
  };
}

enum _Standing { nothingYet, allAssigned, someLeft, overAssigned }

/// How a [_Standing] is shown: its colours, the banner's title and what to
/// do next, and the compact banner's single line.
class _Look {
  const _Look({
    required this.background,
    required this.foreground,
    required this.title,
    required this.message,
    String? line,
  }) : line = line ?? title;

  factory _Look.of(BuildContext context, _Standing standing) {
    final c = context.budgetColors;
    final colors = Theme.of(context).colorScheme;
    final allAssigned = 'Every ${currency.unitName} has a job.';
    return switch (standing) {
      _Standing.nothingYet => _Look(
        background: c.surfaceSunken,
        foreground: c.inkMuted,
        title: 'Left to assign',
        message: 'Start by adding your income for this month.',
      ),
      _Standing.allAssigned => _Look(
        background: c.sproutTint,
        foreground: c.onSproutTint,
        title: 'Left to assign',
        message: allAssigned,
        line: allAssigned,
      ),
      _Standing.someLeft => _Look(
        background: c.highlight,
        foreground: c.onHighlight,
        title: 'Left to assign',
        message: 'Give this money a job by adding budgets.',
      ),
      _Standing.overAssigned => _Look(
        background: colors.error,
        foreground: colors.onError,
        title: 'Over-assigned',
        message: "You've assigned more than you have this month.",
      ),
    };
  }

  final Color background;
  final Color foreground;
  final String title;
  final String message;
  final String line;
}

class _Banner extends StatelessWidget {
  const _Banner(this.look, this.leftCents);

  final _Look look;
  final int leftCents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = look.foreground;

    return Container(
      color: look.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  look.title,
                  style: textTheme.titleMedium?.copyWith(color: foreground),
                ),
              ),
              IconButton(
                tooltip: 'How a zero-based budget works',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.info_outline, color: foreground),
                onPressed: () => showZeroBasedHelp(context),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              formatCents(leftCents.abs()),
              style: textTheme.headlineMedium?.copyWith(color: foreground),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            look.message,
            style: textTheme.bodyMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _CompactBanner extends StatelessWidget {
  const _CompactBanner(this.look, this.leftCents);

  final _Look look;
  final int leftCents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: look.background,
        borderRadius: BudgetRadius.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              look.line,
              style: textTheme.bodyLarge?.copyWith(color: look.foreground),
            ),
          ),
          Text(
            formatCents(leftCents.abs()),
            style: textTheme.titleMedium?.copyWith(color: look.foreground),
          ),
        ],
      ),
    );
  }
}
