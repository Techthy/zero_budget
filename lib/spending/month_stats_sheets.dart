import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../money.dart';
import '../month/month_providers.dart';
import '../settings/buffer_dialog.dart';
import '../settings/settings_providers.dart';
import '../theme/budget_theme.dart';
import '../widgets/app_sheet.dart';
import 'month_stats.dart';

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
) => showAppSheet<void>(context, (_) => _MonthDataSheet(builder: builder));

/// Loads the current month for one of the sheets.
class _MonthDataSheet extends ConsumerWidget {
  const _MonthDataSheet({required this.builder});

  final Widget Function(_MonthData data) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(currentMonthDetailsProvider).value;
    final bufferCents = ref.watch(bufferCentsProvider).value;
    if (details == null || bufferCents == null) return const SheetLoading();
    final (:month, :budgets, :expenses, incomes: _) = details;
    return SheetBody(
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
    // Money with no job yet is in the account too.
    final unassignedCents = leftToAssignCents(month, budgets);

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

    final over = <_BudgetUse>[];
    final almost = <_BudgetUse>[];
    for (final budget in budgets) {
      final use = _BudgetUse.of(budget, spent[budget.id] ?? 0);
      if (use.leftCents < 0) {
        over.add(use);
      } else if (!budget.isFixed &&
          !budget.isSinkingFund &&
          budget.category != BudgetCategory.savings &&
          use.plannedCents > 0 &&
          use.spentCents >= use.plannedCents * _almostUsedUp) {
        almost.add(use);
      }
    }
    // The most over, or the closest to it, first.
    int byLeft(_BudgetUse a, _BudgetUse b) =>
        a.leftCents.compareTo(b.leftCents);
    over.sort(byLeft);
    almost.sort(byLeft);

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
                : '${over.length} budgets are over',
            style: textTheme.titleSmall?.copyWith(color: c.danger),
          ),
          for (final use in over)
            _Line(
              label: use.budget.name,
              amount: formatLeftCents(use.leftCents),
              amountColor: c.danger,
              caption: use.spentOfPlanned,
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
          for (final use in almost)
            _Line(
              label: use.budget.name,
              amount: formatLeftCents(use.leftCents),
              caption: use.spentOfPlanned,
            ),
        ],
      ],
    );
  }
}

/// What was spent from a budget, against what it has this month.
class _BudgetUse {
  _BudgetUse.of(this.budget, this.spentCents)
    : plannedCents = availableCents(budget);

  final Budget budget;
  final int spentCents;

  /// What the budget has to spend, a sinking fund's savings included.
  final int plannedCents;

  /// Negative when the budget is over.
  int get leftCents => plannedCents - spentCents;

  /// Like "50,00€ spent of 40,00€".
  String get spentOfPlanned =>
      '${formatCents(spentCents)} spent of ${formatCents(plannedCents)}';
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
