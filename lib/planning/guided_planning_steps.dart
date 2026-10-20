import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../money.dart';
import '../savings/savings_providers.dart';
import '../theme/budget_theme.dart';
import '../widgets/amount_field.dart';
import '../widgets/budget_badges.dart';
import 'guided_budgets.dart';
import 'plan_editing.dart';

// The content of each step of the guided planning, below its title. Amounts
// are typed into the planning's own controllers, which call onChanged so the
// planning can keep what's left to assign up to date.

/// The account balance and the buffer, for the first month only.
class BalanceStep extends StatelessWidget {
  const BalanceStep({
    super.key,
    required this.balance,
    required this.buffer,
    required this.monthName,
    required this.onChanged,
  });

  final TextEditingController balance;
  final TextEditingController buffer;
  final String monthName;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final balanceCents = parseAmountToCents(balance.text);
    final bufferCents = parseAmountToCents(buffer.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmountField(
          controller: balance,
          labelText: 'Account balance',
          helperText:
              "What's in your account right now. Leave out this "
              "month's income if it came in already; that's next.",
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 16),
        AmountField(
          controller: buffer,
          labelText: 'Buffer',
          helperText:
              'Always stays in your account as a safety net. You can '
              'change it later in Settings.',
          onChanged: (_) => onChanged(),
        ),
        if (balanceCents != null && bufferCents != null) ...[
          const SizedBox(height: 24),
          Text(
            balanceCents >= bufferCents
                ? 'You start $monthName with '
                      '${formatCents(balanceCents - bufferCents)} to plan, on '
                      'top of your income.'
                : 'Your balance is ${formatCents(bufferCents - balanceCents)} '
                      'below your buffer, so that comes off your plan for '
                      '$monthName.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ],
    );
  }
}

/// The month's incomes, saved as they're changed.
class IncomeStep extends ConsumerWidget {
  const IncomeStep({super.key, required this.month, required this.incomes});

  final Month month;
  final List<Income> incomes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (incomes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('No income yet.'),
          ),
        for (final income in incomes)
          Card(
            child: ListTile(
              title: Text(income.name, overflow: TextOverflow.ellipsis),
              subtitle: Text(formatCents(income.amountCents)),
              onTap: () => promptEditIncome(context, ref, income),
              trailing: IconButton(
                tooltip: 'Delete ${income.name}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    ref.read(appDatabaseProvider).deleteIncome(income.id),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            onPressed: () => promptAddIncome(context, ref, month.id),
            icon: const Icon(Icons.add),
            label: const Text('Add income'),
          ),
        ),
      ],
    );
  }
}

/// The field for one of the amounts asked for by name, see [GuidedBudget].
class GuidedAmountField extends StatelessWidget {
  const GuidedAmountField(
    this.budget, {
    super.key,
    required this.onChanged,
    this.autofocus = false,
    this.onSubmitted,
  });

  final GuidedBudget budget;
  final VoidCallback onChanged;
  final bool autofocus;

  /// Called when the field is the last one of its step and is submitted.
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final onSubmitted = this.onSubmitted;
    return AmountField(
      controller: budget.controller,
      labelText: budget.name,
      helperText: budget.helperText,
      isRequired: false,
      autofocus: autofocus,
      textInputAction: onSubmitted == null ? TextInputAction.next : null,
      onChanged: (_) => onChanged(),
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
    );
  }
}

/// Rent, utilities, groceries and transportation.
class EssentialsStep extends StatelessWidget {
  const EssentialsStep({
    super.key,
    required this.essentials,
    required this.onChanged,
  });

  final List<GuidedBudget> essentials;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, essential) in essentials.indexed) ...[
          GuidedAmountField(essential, autofocus: i == 0, onChanged: onChanged),
          const SizedBox(height: 16),
        ],
        Text(
          'Rent is a fixed cost: once you lock your plan in, it counts as '
          'spent in full. The others are flexible: you track what you spend.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.budgetColors.inkMuted),
        ),
      ],
    );
  }
}

/// What to put aside this month, with how it gets the savings goal reached.
class SavingsStep extends ConsumerWidget {
  const SavingsStep({
    super.key,
    required this.savings,
    required this.month,
    required this.onChanged,
    required this.onSubmitted,
  });

  final GuidedBudget savings;
  final Month month;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(savingsProgressProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GuidedAmountField(
          savings,
          autofocus: true,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
        const SizedBox(height: 24),
        if (progress != null)
          _GoalHint(
            progress: progress,
            month: (year: month.year, month: month.month),
            savings: savings,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

/// How this month's savings get the goal reached, or how to set a goal.
class _GoalHint extends StatelessWidget {
  const _GoalHint({
    required this.progress,
    required this.month,
    required this.savings,
    required this.onChanged,
  });

  final SavingsProgress progress;
  final YearMonth month;
  final GuidedBudget savings;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final goalCents = progress.goalCents;
    final suggestion = suggestMonthlySavings(progress, month);
    if (goalCents == null || suggestion == null) {
      return Text(
        'Set a savings goal with the plant at the top of the app to see how '
        'each month gets you there.',
        style: textTheme.bodyMedium?.copyWith(color: c.inkMuted),
      );
    }

    final (:savedBeforeCents, :perMonthCents, :monthsLeft) = suggestion;
    final monthsLeftText = monthsLeft == 1
        ? 'the last month'
        : 'the $monthsLeft months left';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.sproutTint,
        borderRadius: BudgetRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your goal for ${progress.periodName}: ${formatCents(goalCents)}',
            style: textTheme.titleMedium?.copyWith(color: c.onSproutTint),
          ),
          const SizedBox(height: 4),
          Text(
            perMonthCents == 0
                ? "You've reached it already. Anything you save now is a "
                      'bonus.'
                : '${formatCents(savedBeforeCents)} saved so far. To reach '
                      'it, put aside about ${formatCents(perMonthCents)} a '
                      'month for $monthsLeftText.',
            style: textTheme.bodyMedium?.copyWith(color: c.onSproutTint),
          ),
          if (perMonthCents > 0 && savings.cents != perMonthCents) ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                savings.controller.text = formatAmount(perMonthCents);
                onChanged();
              },
              child: Text('Use ${formatCents(perMonthCents)}'),
            ),
          ],
        ],
      ),
    );
  }
}

/// The budgets that aren't asked for by name, which can be added and changed
/// here.
class EverythingElseStep extends ConsumerWidget {
  const EverythingElseStep({
    super.key,
    required this.month,
    required this.others,
    required this.expenses,
  });

  final Month month;
  final List<Budget> others;

  /// The month's expenses, to say what deleting a budget takes with it.
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (others.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('No other budgets yet.'),
          ),
        for (final budget in others)
          Card(
            child: ListTile(
              title: BudgetNameWithBadges(budget),
              subtitle: Text(formatCents(budget.amountCents)),
              onTap: () => promptEditBudget(context, ref, budget),
              trailing: IconButton(
                tooltip: 'Delete ${budget.name}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    confirmDeleteBudget(context, ref, budget, expenses),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            onPressed: () => promptAddBudget(context, ref, month.id),
            icon: const Icon(Icons.add),
            label: const Text('Add budget'),
          ),
        ),
      ],
    );
  }
}
