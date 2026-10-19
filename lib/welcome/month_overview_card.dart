import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../money.dart';
import '../theme/budget_theme.dart';
import 'plan_editing.dart';
import 'welcome_providers.dart';
import 'zero_based_help.dart';

/// The month's money in one card: what's left to assign on top, then where it
/// comes from and the notes. Income and notes open in a sheet from the
/// bottom.
class MonthOverviewCard extends ConsumerWidget {
  const MonthOverviewCard({
    super.key,
    required this.month,
    required this.incomes,
    required this.budgets,
    required this.onEditCarryOver,
  });

  final Month month;
  final List<Income> incomes;
  final List<Budget> budgets;

  /// Corrects what's carried over; only offered while planning.
  final VoidCallback onEditCarryOver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A locked in plan is read only until it's unlocked for editing.
    final isLocked = month.lockedAt != null;
    final assignedCents = budgets.fold(0, (sum, b) => sum + b.amountCents);
    final availableCents = month.incomeCents + month.carryOverCents;
    final leftCents = availableCents - assignedCents;
    // Nothing left from last month, like in the first month: what's there
    // was entered as the balance to start from.
    final isStartingBalance =
        month.carryOverAdjustmentCents != 0 &&
        month.carryOverCents == month.carryOverAdjustmentCents;

    final rows = [
      _OverviewRow(
        icon: Icons.payments_outlined,
        title: 'Income',
        subtitle: switch (incomes) {
          [] when isLocked => 'No income this month',
          [] => 'Tap to add your income',
          [final income] => income.name,
          _ => '${incomes.length} sources',
        },
        amount: formatCents(month.incomeCents),
        onTap: () => showIncomeSheet(context),
      ),
      // Shown while planning even when it's 0, so it can be corrected.
      if (month.carryOverCents != 0 || !isLocked)
        _OverviewRow(
          icon: Icons.update_outlined,
          title: isStartingBalance ? 'Starting balance' : 'Carried over',
          subtitle: switch (month.carryOverAdjustmentCents) {
            _ when isStartingBalance => 'Your balance above the buffer',
            0 => 'Left from last month',
            final correction =>
              'Left from last month, incl. '
                  '${formatSignedCents(correction)} correction',
          },
          amount: formatSignedCents(month.carryOverCents),
          onTap: isLocked ? null : onEditCarryOver,
        ),
      _OverviewRow(
        icon: Icons.pie_chart_outline,
        title: 'Assigned to budgets',
        subtitle: switch (budgets.length) {
          0 => 'No budgets yet',
          1 => '1 budget',
          final count => '$count budgets',
        },
        amount: formatCents(assignedCents),
      ),
      // Notes stay editable once locked in, for reminders that come up
      // during the month.
      _OverviewRow(
        icon: Icons.sticky_note_2_outlined,
        title: 'Notes',
        subtitle:
            month.notes ?? 'Goals for this month, or things to take care of.',
        onTap: () => _editNotes(context, ref),
      ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LeftToAssign(availableCents: availableCents, leftCents: leftCents),
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 52),
            row,
          ],
        ],
      ),
    );
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final notes = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NotesSheet(notes: month.notes),
    );
    if (notes != null) {
      await ref.read(appDatabaseProvider).updateMonthNotes(month.id, notes);
    }
  }
}

/// Opens the month's incomes in a sheet from the bottom.
Future<void> showIncomeSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _IncomeSheet(),
    );

/// What's left to assign, colored by whether it's all assigned.
class _LeftToAssign extends StatelessWidget {
  const _LeftToAssign({required this.availableCents, required this.leftCents});

  /// Income plus whatever was carried over from last month.
  final int availableCents;
  final int leftCents;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (background, foreground, message) = switch (leftCents) {
      0 when availableCents == 0 => (
        c.surfaceSunken,
        c.inkMuted,
        'Start by adding your income for this month.',
      ),
      0 => (c.sproutTint, c.onSproutTint, 'Every ${currency.unitName} has a job.'),
      > 0 => (
        c.highlight,
        c.onHighlight,
        'Give this money a job by adding budgets.',
      ),
      _ => (
        colors.error,
        colors.onError,
        "You've assigned more than you have this month.",
      ),
    };

    return Container(
      color: background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  leftCents < 0 ? 'Over-assigned' : 'Left to assign',
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
            message,
            style: textTheme.bodyMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// A line of the overview: an icon, a title with a short explanation, and an
/// amount. Rows with [onTap] show a chevron.
class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.amount,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final amount = this.amount;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(icon, color: c.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyLarge),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            if (amount != null) ...[
              const SizedBox(width: 8),
              Text(amount, style: textTheme.labelLarge),
            ],
            SizedBox(
              width: 32,
              child: onTap == null
                  ? null
                  : Icon(Icons.chevron_right, color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// The month's incomes, which can be changed while planning.
class _IncomeSheet extends ConsumerWidget {
  const _IncomeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final c = context.budgetColors;
    final month = ref.watch(currentMonthProvider).value;
    final incomes = ref.watch(currentIncomesProvider).value;
    if (month == null || incomes == null) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final isLocked = month.lockedAt != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Income this month', style: textTheme.titleLarge),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                formatCents(month.incomeCents),
                style: textTheme.headlineMedium,
              ),
            ),
            if (isLocked)
              Text(
                'Your plan is locked in. Unlock it to change your income.',
                style: textTheme.bodySmall?.copyWith(color: c.inkMuted),
              ),
            const SizedBox(height: 8),
            if (incomes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No income yet. Add every source of money coming in this '
                  'month, like your salary.',
                  style: textTheme.bodyMedium,
                ),
              ),
            for (final income in incomes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(income.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(formatCents(income.amountCents)),
                onTap: isLocked
                    ? null
                    : () => promptEditIncome(context, ref, income),
                trailing: isLocked
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit ${income.name}',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                promptEditIncome(context, ref, income),
                          ),
                          IconButton(
                            tooltip: 'Delete ${income.name}',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref
                                .read(appDatabaseProvider)
                                .deleteIncome(income.id),
                          ),
                        ],
                      ),
              ),
            if (!isLocked) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => promptAddIncome(context, ref, month.id),
                icon: const Icon(Icons.add),
                label: const Text('Add income'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows the month's [notes], with a pen to edit them; returns the new text
/// once saved. Without notes yet, it starts out editing.
class _NotesSheet extends StatefulWidget {
  const _NotesSheet({this.notes});

  final String? notes;

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  late final _notes = TextEditingController(text: widget.notes);
  late var _editing = widget.notes == null;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _cancel() {
    if (widget.notes == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _notes.text = widget.notes!;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final notes = widget.notes;

    return SafeArea(
      child: Padding(
        // Stays above the keyboard.
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Notes', style: textTheme.titleLarge)),
                if (!_editing)
                  IconButton(
                    tooltip: 'Edit notes',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => setState(() => _editing = true),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Goals for this month, or things to take care of.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (!_editing && notes != null)
              // Long notes scroll within the sheet.
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(notes, style: textTheme.bodyLarge),
                ),
              )
            else ...[
              TextField(
                controller: _notes,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Save for the holiday, cancel the gym membership',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                minLines: 4,
                maxLines: 10,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _cancel, child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_notes.text),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
