import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../money.dart';
import '../welcome/welcome_providers.dart';
import '../widgets/amount_field.dart';
import 'savings_plant.dart';
import 'savings_providers.dart';

/// A [SavingsPlant] that grows towards the savings goal. Tapping it shows
/// the [SavingsGoalSheet].
class SavingsPlantButton extends ConsumerWidget {
  const SavingsPlantButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growth = ref.watch(
      savingsProgressProvider.select((progress) => progress.value?.fraction),
    );

    return IconButton(
      tooltip: 'Savings goal',
      iconSize: 32,
      icon: SavingsPlant(growth: growth ?? 0),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const SavingsGoalSheet(),
      ),
    );
  }
}

/// How far the savings goal is, month by month, with a way to change it.
class SavingsGoalSheet extends ConsumerWidget {
  const SavingsGoalSheet({super.key});

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    SavingsProgress progress,
  ) async {
    final goal = await showDialog<_GoalInput>(
      context: context,
      builder: (_) => _GoalDialog(
        goalCents: progress.goalCents,
        period: progress.period,
      ),
    );
    if (goal != null) {
      await ref
          .read(appDatabaseProvider)
          .setSavingsGoal(goal.goalCents, goal.period);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final progress = ref.watch(savingsProgressProvider).value;
    // Until the budgets load, don't suggest adding a savings budget.
    final hasSavingsBudget = ref.watch(
      currentBudgetsProvider.select(
        (budgets) => budgets.value?.any((b) => b.isSavings) ?? true,
      ),
    );
    if (progress == null) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final goalCents = progress.goalCents;
    final savedCents = progress.savedCents;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: SavingsPlant(growth: progress.fraction, size: 120)),
            const SizedBox(height: 16),
            Text(
              goalCents == null
                  ? 'Grow your savings'
                  : 'Savings goal ${progress.periodName}',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (goalCents == null)
              Text(
                'Set a goal for the quarter or the year, and watch your plant '
                'grow with everything you put aside.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              )
            else ...[
              Text(
                '${formatCents(savedCents)} of ${formatCents(goalCents)} '
                'saved',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress.fraction),
              const SizedBox(height: 8),
              Text(
                savedCents >= goalCents
                    ? 'Goal reached. Well done!'
                    : '${formatCents(goalCents - savedCents)} to go',
                textAlign: TextAlign.center,
              ),
            ],
            if (progress.months.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final (:month, :savedCents) in progress.months)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatMonth(month.year, month.month)),
                  trailing: Text(
                    formatCents(savedCents),
                    style: textTheme.bodyMedium,
                  ),
                ),
            ],
            if (!hasSavingsBudget) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text(
                    'Mark a budget as savings on the Plan tab, like a transfer '
                    'to your savings account. What you put aside with it '
                    'counts towards your goal.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => _editGoal(context, ref, progress),
              child: Text(goalCents == null ? 'Set a goal' : 'Change goal'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A savings goal; no [goalCents] removes it.
typedef _GoalInput = ({int? goalCents, SavingsPeriod period});

/// Sets the savings goal, starting from [goalCents] and [period].
class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.goalCents, required this.period});

  final int? goalCents;
  final SavingsPeriod period;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: switch (widget.goalCents) {
      final cents? => formatAmount(cents),
      null => '',
    },
  );
  late var _period = widget.period;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final _GoalInput goal = (
      goalCents: parseAmountToCents(_amount.text)!,
      period: _period,
    );
    Navigator.of(context).pop(goal);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Savings goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How much do you want to put aside? Your plant starts over '
              'each period.',
            ),
            const SizedBox(height: 16),
            SegmentedButton<SavingsPeriod>(
              segments: const [
                ButtonSegment(
                  value: SavingsPeriod.quarter,
                  label: Text('Per quarter'),
                ),
                ButtonSegment(
                  value: SavingsPeriod.year,
                  label: Text('Per year'),
                ),
              ],
              selected: {_period},
              onSelectionChanged: (selected) =>
                  setState(() => _period = selected.single),
            ),
            AmountField(
              controller: _amount,
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.goalCents != null)
          TextButton(
            onPressed: () {
              final _GoalInput goal = (goalCents: null, period: _period);
              Navigator.of(context).pop(goal);
            },
            child: const Text('Remove goal'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
