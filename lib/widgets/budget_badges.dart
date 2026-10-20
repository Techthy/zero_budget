import 'package:flutter/material.dart';

import '../data/database.dart';
import '../theme/budget_theme.dart';

/// A budget's name with its badges after it, which go on the next line when
/// they don't fit.
class BudgetNameWithBadges extends StatelessWidget {
  const BudgetNameWithBadges(this.budget, {super.key});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(budget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ...budgetBadges(budget),
      ],
    );
  }
}

/// The badges that describe [budget]: how it's spent, and what it's for.
List<Widget> budgetBadges(Budget budget) => [
  if (budget.isFixed) const _FixedBadge(),
  if (budget.isSinkingFund) const _SinkingFundBadge(),
  if (budget.category != BudgetCategory.other) _CategoryBadge(budget.category),
];

/// Marks a budget that is always spent in full.
class _FixedBadge extends StatelessWidget {
  const _FixedBadge();

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
class _SinkingFundBadge extends StatelessWidget {
  const _SinkingFundBadge();

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

/// What [BudgetCategory] is called in the app.
String categoryLabel(BudgetCategory category) => switch (category) {
  BudgetCategory.giving => 'Giving',
  BudgetCategory.essential => 'Essential',
  BudgetCategory.savings => 'Savings',
  BudgetCategory.other => 'Other',
};

/// Marks what a budget is for. Outlined, unlike the badges for how a budget
/// behaves, and left out for [BudgetCategory.other].
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge(this.category)
    : assert(category != BudgetCategory.other);

  final BudgetCategory category;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    return _Badge(
      label: categoryLabel(category),
      icon: switch (category) {
        BudgetCategory.giving => Icons.volunteer_activism_outlined,
        BudgetCategory.essential => Icons.home_outlined,
        BudgetCategory.savings ||
        BudgetCategory.other => Icons.savings_outlined,
      },
      background: Colors.transparent,
      foreground: c.forestDeep,
      border: c.border,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final border = this.border;
    final icon = this.icon;
    final text = Text(
      label,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: foreground),
    );
    return Container(
      // The border takes the place of the padding, so all badges are the
      // same height.
      padding: border == null
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: border == null ? null : Border.all(color: border),
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: foreground),
                const SizedBox(width: 4),
                text,
              ],
            ),
    );
  }
}
