import 'package:flutter/material.dart';

import '../money.dart';
import '../theme/budget_theme.dart';

/// Opens the explanation of zero-based budgeting in a sheet from the bottom.
Future<void> showZeroBasedHelp(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, controller) =>
            _ZeroBasedHelp(controller: controller),
      ),
    );

typedef _Section = ({IconData icon, String title, String text});

List<_Section> get _sections => [
  (
    icon: Icons.work_outline,
    title: 'Every ${currency.unitName} gets a job',
    text:
        'Before the month starts, you split all the money you have for it, '
        'your income plus what last month left, into budgets: giving, rent, '
        'groceries, savings, fun. When nothing is left to assign, every '
        '${currency.unitName} has a job.',
  ),
  (
    icon: Icons.savings_outlined,
    title: "Zero doesn't mean spending it all",
    text:
        'Saving is a job too. Money you want to keep goes into savings or a '
        'sinking fund, not into what is left over. Your buffer stays in your '
        'account on top of the plan, as a safety net.',
  ),
  (
    icon: Icons.balance_outlined,
    title: 'Reading left to assign',
    text:
        'Above 0, some money has no job yet: add a budget or raise one. '
        'Below 0, you planned more than you have: take some off a budget. At '
        'exactly 0, your plan is balanced and you can lock it in.',
  ),
  (
    icon: Icons.explore_outlined,
    title: 'Plan ahead instead of looking back',
    text:
        'You decide where your money goes before you spend it, instead of '
        'tracking expenses that were already too high. You are in charge of '
        'your money, and you start thinking ahead.',
  ),
  (
    icon: Icons.swap_horiz,
    title: 'When the month goes differently',
    text:
        'Spent more on one budget? Unlock your plan and move money from '
        'another one. The total stays the same, and every '
        '${currency.unitName} still has a job.',
  ),
];

class _ZeroBasedHelp extends StatelessWidget {
  const _ZeroBasedHelp({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text('How a zero-based budget works', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.sproutTint,
              borderRadius: BudgetRadius.md,
            ),
            child: Column(
              children: [
                Text(
                  'Income + carried over − budgets = 0',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(color: c.onSproutTint),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan every ${currency.unitName} before you spend it.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: c.onSproutTint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final section in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(section.icon, color: c.forestDeep),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(section.text, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
