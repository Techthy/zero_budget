import 'package:flutter/material.dart';

import '../budget_order.dart';
import '../theme/budget_theme.dart';

/// Opens the explanation of the guided planning in a sheet from the bottom.
Future<void> showGuidedPlanningHelp(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, controller) =>
            _GuidedPlanningHelp(controller: controller),
      ),
    );

typedef _HelpStep = ({String title, String text});

/// The steps of the guided planning in order, and how what's entered ends up
/// in the plan.
const List<_HelpStep> _steps = [
  (
    title: 'Where you start',
    text:
        "Only in your first month, when there's no month before to carry "
        'money over from. Enter what is in your account right now, without '
        "this month's income, and the buffer you always want to keep. "
        'Everything above the buffer is extra money to plan with. You can '
        'change the buffer later in Settings.',
  ),
  (
    title: 'Your income',
    text:
        'Add every source of money coming in this month, like your salary or '
        'a side job. Together with what last month left, this is what you '
        'give a job to in the next steps.',
  ),
  (
    title: 'Giving first',
    text:
        'What you want to give to a charity, your church or people you care '
        'about. It is added as a flexible "$givingBudgetName" budget, so it '
        'counts as you give.',
  ),
  (
    title: 'The essentials',
    text:
        '$rentBudgetName is a fixed cost: once you lock your plan in, it '
        'counts as spent in full. $utilitiesBudgetName, $groceriesBudgetName '
        'and $transportationBudgetName are flexible: you track what you spend '
        'on them. Leave any you don\'t need empty.',
  ),
  (
    title: 'Pay yourself',
    text:
        'What you put aside this month. It is a fixed savings budget, so once '
        'you lock your plan in it counts towards your savings goal in full. '
        'With a goal set, you see how much to save each month to reach it. '
        'A savings budget you already have is used, whatever it is called.',
  ),
  (
    title: 'Everything else',
    text:
        'Add the rest, like insurance, subscriptions or money for fun. Each '
        'budget can be fixed or a sinking fund that saves up for '
        "costs that don't come every month, and has a category: giving, "
        'essential, savings or other.',
  ),
];

/// General rules, shown after the steps.
const List<String> _goodToKnow = [
  'Each step is saved when you tap Next. You can stop at any time and keep '
      'what you entered.',
  'The steps start from your current plan. A new month begins as a copy of '
      'the month before, so you mostly check and adjust.',
  'Left to assign shows what still needs a job. Aim for 0: every euro gets a '
      'job.',
  'Giving and the essentials are found by their names. Keep the names to '
      'have them filled in next time.',
  'Leaving an amount empty skips it, and removes a budget there already, '
      'unless you tracked expenses on it.',
  'When you are done, lock your plan in. Fixed budgets then count as spent '
      'in full, and you track the rest of your spending for the month.',
];

class _GuidedPlanningHelp extends StatelessWidget {
  const _GuidedPlanningHelp({required this.controller});

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
          Text('How step by step works', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'The app walks you through your month in this order:',
            style: textTheme.bodyMedium?.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: 16),
          for (final (i, step) in _steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: c.sproutTint,
                    child: Text(
                      '${i + 1}',
                      style: textTheme.labelLarge?.copyWith(
                        color: c.onSproutTint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(step.text, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text('Good to know', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final point in _goodToKnow)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: c.forestDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(point, style: textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
