import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../money.dart';
import '../planning/planning_providers.dart';
import '../theme/budget_theme.dart';
import '../widgets/amount_field.dart';
import '../widgets/leaf_background.dart';
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
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final progress = ref.watch(savingsProgressProvider).value;
    // Until the budgets load, don't suggest adding a savings budget.
    final hasSavingsBudget = ref.watch(
      currentBudgetsProvider.select(
        (budgets) =>
            budgets.value?.any((b) => b.category == BudgetCategory.savings) ??
            true,
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

    return LeafBackground(
      expand: false,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Center(
                    child: SavingsPlant(growth: progress.fraction, size: 120),
                  ),
                  if (goalCents != null)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: IconButton(
                        tooltip: 'Change goal',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editGoal(context, ref, progress),
                      ),
                    ),
                ],
              ),
              if (goalCents != null) ...[
                const SizedBox(height: 8),
                Center(child: _GrowthStage(fraction: progress.fraction)),
              ],
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
                  'Set a goal for the quarter or the year, and watch your '
                  'plant grow with everything you put aside.',
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
                _GrowthVine(fraction: progress.fraction),
                const SizedBox(height: 8),
                Text(
                  savedCents >= goalCents
                      ? 'Goal reached. Well done!'
                      : '${formatCents(goalCents - savedCents)} to go',
                  textAlign: TextAlign.center,
                ),
              ],
              if (progress.months.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('What you planted', style: textTheme.titleSmall),
                const SizedBox(height: 4),
                for (final (:month, :savedCents) in progress.months)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.eco_outlined, color: c.sproutStrong),
                    minLeadingWidth: 24,
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
                  color: c.sproutTint,
                  child: ListTile(
                    leading: Icon(Icons.spa_outlined, color: c.onSproutTint),
                    title: Text(
                      'Give a budget the Savings category on the Plan tab, '
                      'like a transfer to your savings account. What you put '
                      'aside with it helps your plant grow.',
                      style: TextStyle(color: c.onSproutTint),
                    ),
                  ),
                ),
              ],
              if (goalCents == null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _editGoal(context, ref, progress),
                  icon: const Icon(Icons.spa_outlined),
                  label: const Text('Set a goal'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// How far the plant has grown, named like a stage in a garden.
class _GrowthStage extends StatelessWidget {
  const _GrowthStage({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final (label, icon) = switch (fraction) {
      >= 1 => ('In full bloom', Icons.local_florist_outlined),
      >= 0.75 => ('Almost in bloom', Icons.local_florist_outlined),
      >= 0.4 => ('Growing strong', Icons.eco_outlined),
      > 0 => ('Sprouting', Icons.spa_outlined),
      _ => ('A seed in the soil', Icons.grass_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.sproutTint,
        borderRadius: BudgetRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.onSproutTint),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: c.onSproutTint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress towards the goal as a vine growing along the soil, with leaves
/// along it and a sprout at its tip. Changes are animated, like the plant.
class _GrowthVine extends StatelessWidget {
  const _GrowthVine({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    return Semantics(
      label: '${(fraction * 100).round()}% of the goal',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fraction.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (_, fraction, _) => CustomPaint(
          size: const Size.fromHeight(28),
          painter: _VinePainter(
            fraction: fraction,
            soil: c.progressTrack,
            stem: c.sproutStrong,
            leaf: c.sprout,
          ),
        ),
      ),
    );
  }
}

class _VinePainter extends CustomPainter {
  _VinePainter({
    required this.fraction,
    required this.soil,
    required this.stem,
    required this.leaf,
  });

  final double fraction;
  final Color soil;
  final Color stem;
  final Color leaf;

  /// Room between the leaves along the vine.
  static const _leafSpacing = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final track = RRect.fromLTRBR(0, y - 4, size.width, y + 4,
        const Radius.circular(4));
    canvas.drawRRect(track, Paint()..color = soil);
    if (fraction <= 0) return;

    final end = size.width * fraction;
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 4, end, y + 4, const Radius.circular(4)),
      Paint()..color = stem,
    );
    // Leaves on alternating sides, then a sprout at the tip.
    var side = -1.0;
    for (var x = _leafSpacing; x < end - _leafSpacing / 2; x += _leafSpacing) {
      _paintLeaf(canvas, Offset(x, y), side * 0.9 - 0.35, 9);
      side = -side;
    }
    _paintLeaf(canvas, Offset(end, y), -1.9, 12);
    _paintLeaf(canvas, Offset(end, y), -0.9, 12);
  }

  void _paintLeaf(Canvas canvas, Offset base, double angle, double length) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final width = length * 0.4;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(length * 0.3, -width, length * 0.8, -width * 0.6, length, 0)
        ..cubicTo(length * 0.8, width * 0.6, length * 0.3, width, 0, 0)
        ..close(),
      Paint()..color = leaf,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VinePainter old) =>
      old.fraction != fraction ||
      old.soil != soil ||
      old.stem != stem ||
      old.leaf != leaf;
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
