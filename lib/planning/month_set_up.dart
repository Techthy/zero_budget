import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../budget_order.dart';
import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../money.dart';
import '../settings/settings_providers.dart';
import '../theme/budget_theme.dart';
import '../widgets/fixed_badge.dart';
import 'guided_planning_screen.dart';

/// The first look at a month copied from the month before, see
/// [Months.needsSetUp]: the user picks which budgets to keep, then plans
/// step by step or goes straight to the plan.
class MonthSetUp extends ConsumerStatefulWidget {
  const MonthSetUp({super.key, required this.month, required this.budgets});

  final Month month;
  final List<Budget> budgets;

  @override
  ConsumerState<MonthSetUp> createState() => _MonthSetUpState();
}

class _MonthSetUpState extends ConsumerState<MonthSetUp> {
  /// All budgets are kept until unticked.
  final _unticked = <int>{};
  var _saving = false;

  Future<void> _setUp({required bool stepByStep}) async {
    // This screen goes away once the month is set up.
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(appDatabaseProvider).setUpMonth(widget.month.id, {
        for (final budget in widget.budgets)
          if (!_unticked.contains(budget.id)) budget.id,
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (stepByStep) navigator.push(guidedPlanningRoute());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final month = widget.month;
    final budgetOrder =
        ref.watch(
          settingsProvider.select((settings) => settings.value?.budgetOrder),
        ) ??
        BudgetOrder.category;
    final budgets = sortBudgets(widget.budgets, budgetOrder);
    final keptCount = budgets.length - _unticked.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Welcome to ${formatMonth(month.year, month.month)}',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              budgets.isEmpty
                  ? 'Your income is copied from last month. How do you want '
                        'to plan this one?'
                  : "Your plan starts as a copy of last month's. Untick the "
                        "budgets you don't need this month; your income is "
                        'kept as it was.',
              style: textTheme.bodyLarge,
            ),
            if (budgets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Keeping $keptCount of ${budgets.length} budgets',
                style: textTheme.labelLarge?.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final budget in budgets)
                      _BudgetTile(
                        budget: budget,
                        kept: !_unticked.contains(budget.id),
                        onChanged: _saving
                            ? null
                            : (kept) => setState(() {
                                if (kept) {
                                  _unticked.remove(budget.id);
                                } else {
                                  _unticked.add(budget.id);
                                }
                              }),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('How do you want to plan?', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _Option(
              icon: Icons.route_outlined,
              title: 'Plan step by step',
              description:
                  'Go through your income, giving, the essentials, savings '
                  'and everything else again, one step at a time.',
              highlighted: true,
              onTap: _saving ? null : () => _setUp(stepByStep: true),
            ),
            const SizedBox(height: 8),
            _Option(
              icon: Icons.edit_note_outlined,
              title: 'Go to my plan',
              description:
                  'Adjust what you need on the plan and lock it in straight '
                  'away.',
              onTap: _saving ? null : () => _setUp(stepByStep: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// A budget to keep or not, with its amount and kind.
class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.budget,
    required this.kept,
    required this.onChanged,
  });

  final Budget budget;
  final bool kept;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: kept,
      onChanged: onChanged == null ? null : (value) => onChanged!(value!),
      controlAffinity: ListTileControlAffinity.leading,
      // Badges go on the next line when they don't fit.
      title: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(budget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (budget.isFixed) const FixedBadge(),
          if (budget.isSinkingFund) const SinkingFundBadge(),
          if (budget.category != BudgetCategory.other)
            CategoryBadge(budget.category),
        ],
      ),
      subtitle: Text(switch (budget.savedCents) {
        0 => formatCents(budget.amountCents),
        final savedCents when !kept =>
          'Its ${formatCents(savedCents)} saved goes back into this month.',
        final savedCents =>
          '${formatCents(budget.amountCents)} · '
              '${formatCents(savedCents)} saved',
      }),
    );
  }
}

/// One way to go on from setting up the month.
class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  /// Whether it's the suggested way, shown in the plan's green.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final foreground = highlighted ? c.onSproutTint : null;
    return Card(
      color: highlighted ? c.sproutTint : null,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: foreground),
        title: Text(title, style: TextStyle(color: foreground)),
        subtitle: Text(description, style: TextStyle(color: foreground)),
        trailing: Icon(Icons.arrow_forward, color: foreground),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
