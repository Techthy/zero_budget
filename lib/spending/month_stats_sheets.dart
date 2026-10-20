import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../money.dart';
import '../planning/planning_providers.dart';
import '../settings/buffer_dialog.dart';
import '../theme/budget_theme.dart';
import 'month_stats.dart';
import 'spending_providers.dart';

// The details behind the tiles of the MonthStatsCard, each in a sheet from
// the bottom. They follow the month as it changes while they're open.

/// Explains the expected bank balance and lets the buffer be changed.
Future<void> showBankBalanceSheet(BuildContext context) =>
    _showSheet(context, (data) => _BankBalanceDetails(data: data));

/// Shows which budgets are over or almost used up.
Future<void> showOnTrackSheet(BuildContext context) =>
    _showSheet(context, (data) => _OnTrackDetails(data: data));

/// Shows what each sinking fund holds and how it got there.
Future<void> showSinkingFundsSheet(BuildContext context) =>
    _showSheet(context, (data) => _SinkingFundsDetails(data: data));

/// The current month's plan and spending, with its stats.
typedef _MonthData = ({
  Month month,
  List<Budget> budgets,
  Map<int, int> spent,
  int bufferCents,
  MonthStats stats,
});

Future<void> _showSheet(
  BuildContext context,
  Widget Function(_MonthData data) builder,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _MonthDataSheet(builder: builder),
);

/// Loads the current month for one of the sheets.
class _MonthDataSheet extends ConsumerWidget {
  const _MonthDataSheet({required this.builder});

  final Widget Function(_MonthData data) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider).value;
    final budgets = ref.watch(currentBudgetsProvider).value;
    final expenses = ref.watch(currentExpensesProvider).value;
    final bufferCents = ref.watch(bufferCentsProvider).value;
    if (month == null ||
        budgets == null ||
        expenses == null ||
        bufferCents == null) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: builder((
          month: month,
          budgets: budgets,
          spent: spentByBudget(expenses),
          bufferCents: bufferCents,
          stats: MonthStats.of(
            month: month,
            budgets: budgets,
            expenses: expenses,
            bufferCents: bufferCents,
          ),
        )),
      ),
    );
  }
}

/// A sheet's heading: an icon, a title and the number it's about.
class _Heading extends StatelessWidget {
  const _Heading({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: c.inkMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(color: c.inkMuted),
              ),
              Text(
                value,
                style: textTheme.headlineSmall?.copyWith(color: valueColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A line of a breakdown: what it is, and its amount on the right.
class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.amount,
    this.caption,
    this.isTotal = false,
    this.amountColor,
    this.trailing,
  });

  final String label;
  final String amount;
  final String? caption;
  final bool isTotal;
  final Color? amountColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final style = isTotal ? textTheme.titleMedium : textTheme.bodyLarge;
    final caption = this.caption;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style),
                if (caption != null)
                  Text(
                    caption,
                    style: textTheme.bodySmall?.copyWith(color: c.inkMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(amount, style: style?.copyWith(color: amountColor)),
          ?trailing,
        ],
      ),
    );
  }
}

/// A short explanation in muted text.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.budgetColors.inkMuted),
  );
}

class _BankBalanceDetails extends ConsumerWidget {
  const _BankBalanceDetails({required this.data});

  final _MonthData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:month, :budgets, :bufferCents, :stats, spent: _) = data;
    final assignedCents = budgets.fold(0, (sum, b) => sum + b.amountCents);
    // Money with no job yet is in the account too.
    final unassignedCents =
        month.incomeCents + month.carryOverCents - assignedCents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          icon: Icons.account_balance_outlined,
          title: 'Bank balance',
          value: formatCents(stats.bankBalanceCents),
        ),
        const SizedBox(height: 16),
        const _Note(
          'Zero Budget treats all your money as being in one bank account. '
          "So what should be in it right now is what's left to spend, plus "
          'the buffer you always keep.',
        ),
        const SizedBox(height: 16),
        _Line(
          label: stats.leftCents < 0 ? 'Over budget' : 'Left to spend',
          amount: formatCents(stats.leftCents),
          caption: 'Across all budgets, sinking funds included',
        ),
        if (unassignedCents != 0)
          _Line(
            label: 'Not assigned yet',
            amount: formatCents(unassignedCents),
            caption: 'Money in your plan without a job',
          ),
        _Line(
          label: 'Buffer',
          amount: formatCents(bufferCents),
          caption: 'Always kept on top of your plan',
          trailing: IconButton(
            tooltip: 'Change buffer',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => editBuffer(context, ref, bufferCents),
          ),
        ),
        const Divider(),
        _Line(
          label: 'Expected balance',
          amount: formatCents(stats.bankBalanceCents),
          isTotal: true,
        ),
        const SizedBox(height: 16),
        const _Note(
          "This assumes all of this month's income has come in. If your "
          'real balance is different, an expense may not be entered yet, or '
          "the money carried over from last month needs a correction on "
          'the Plan tab.',
        ),
      ],
    );
  }
}

class _OnTrackDetails extends StatelessWidget {
  const _OnTrackDetails({required this.data});

  final _MonthData data;

  /// From how much of its money spent an everyday budget is almost used up.
  static const _almostUsedUp = 0.8;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final (:budgets, :spent, :stats, month: _, bufferCents: _) = data;

    final over = <(Budget, int)>[];
    final almost = <(Budget, int)>[];
    for (final budget in budgets) {
      final spentCents = spent[budget.id] ?? 0;
      final availableCents = budget.amountCents + budget.savedCents;
      if (spentCents > availableCents) {
        over.add((budget, spentCents));
      } else if (!budget.isFixed &&
          !budget.isSinkingFund &&
          budget.category != BudgetCategory.savings &&
          availableCents > 0 &&
          spentCents >= availableCents * _almostUsedUp) {
        almost.add((budget, spentCents));
      }
    }
    // The most over, or the closest to it, first.
    int overBy((Budget, int) entry) =>
        entry.$2 - entry.$1.amountCents - entry.$1.savedCents;
    over.sort((a, b) => overBy(b).compareTo(overBy(a)));
    almost.sort((a, b) => overBy(b).compareTo(overBy(a)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          icon: over.isEmpty
              ? Icons.check_circle_outline
              : Icons.warning_amber_rounded,
          title: 'On track',
          value: '${stats.budgetCount - over.length} of ${stats.budgetCount}',
          valueColor: over.isEmpty ? null : c.danger,
        ),
        const SizedBox(height: 16),
        if (over.isEmpty)
          const _Note(
            'No budget is over. Every budget still has money left, or is '
            'spent exactly as planned.',
          )
        else ...[
          Text(
            over.length == 1
                ? '1 budget is over'
                : '${over.length} '
                      'budgets are over',
            style: textTheme.titleSmall?.copyWith(color: c.danger),
          ),
          for (final entry in over)
            _Line(
              label: entry.$1.name,
              amount: '${formatCents(overBy(entry))} over',
              amountColor: c.danger,
              caption:
                  '${formatCents(entry.$2)} spent of '
                  '${formatCents(entry.$1.amountCents + entry.$1.savedCents)}',
            ),
          const SizedBox(height: 8),
          const _Note(
            'To cover it, unlock your plan and move money from a budget that '
            'has some left. Your total stays the same.',
          ),
        ],
        if (almost.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Almost used up', style: textTheme.titleSmall),
          for (final entry in almost)
            _Line(
              label: entry.$1.name,
              amount: '${formatCents(-overBy(entry))} left',
              caption:
                  '${formatCents(entry.$2)} spent of '
                  '${formatCents(entry.$1.amountCents + entry.$1.savedCents)}',
            ),
        ],
      ],
    );
  }
}

class _SinkingFundsDetails extends StatelessWidget {
  const _SinkingFundsDetails({required this.data});

  final _MonthData data;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final (:budgets, :spent, :stats, month: _, bufferCents: _) = data;
    final funds = [
      for (final budget in budgets)
        if (budget.isSinkingFund) budget,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          icon: Icons.inventory_2_outlined,
          title: 'Sinking funds',
          value: formatCents(stats.fundsCents),
        ),
        const SizedBox(height: 16),
        const _Note(
          "Each month, a sinking fund's amount is set aside in full. What "
          "isn't spent stays in the fund and carries over, until the cost it "
          'saves for comes.',
        ),
        const SizedBox(height: 8),
        for (final fund in funds) ...[
          const Divider(),
          Builder(
            builder: (context) {
              final spentCents = spent[fund.id] ?? 0;
              final balanceCents = fundBalanceCents(fund, spentCents);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Line(
                    label: fund.name,
                    amount: formatCents(balanceCents),
                    amountColor: balanceCents < 0 ? c.danger : null,
                    isTotal: true,
                  ),
                  Text(
                    [
                      if (fund.savedCents != 0)
                        '${formatCents(fund.savedCents)} saved before',
                      '+ ${formatCents(fund.amountCents)} this month',
                      if (spentCents != 0) '− ${formatCents(spentCents)} spent',
                    ].join('  '),
                    style: textTheme.bodySmall?.copyWith(color: c.inkMuted),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
