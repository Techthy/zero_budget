import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../dates.dart';
import '../money.dart';
import '../settings/settings_providers.dart';
import '../spending/spending_providers.dart';
import '../theme/budget_theme.dart';
import '../widgets/amount_field.dart';
import '../widgets/fixed_badge.dart';
import '../widgets/leaf_background.dart';
import 'plan_editing.dart';
import 'welcome_providers.dart';

/// Opens the guided planning for the current month.
Future<void> startGuidedPlanning(BuildContext context) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const GuidedPlanningScreen(),
      ),
    );

enum _Step { balance, income, giving, essentials, everythingElse }

/// A budget the guided planning asks for by name: giving and the essentials.
///
/// It's matched to the month's first budget with the same name, ignoring case,
/// see [AppDatabase.setBudgetByName].
class _NamedBudget {
  _NamedBudget(this.name, {required this.isFixed, required this.helperText});

  final String name;

  /// Whether it's added as a fixed budget, when it's new.
  final bool isFixed;

  final String helperText;
  final controller = TextEditingController();

  int get cents => parseAmountToCents(controller.text) ?? 0;

  Budget? matchIn(List<Budget> budgets) {
    final lower = name.toLowerCase();
    for (final budget in budgets) {
      if (budget.name.toLowerCase() == lower) return budget;
    }
    return null;
  }
}

/// Walks through planning the current month one step at a time: the starting
/// balance (only before there's a month to carry money over from), income,
/// giving, the essentials, and everything else.
///
/// Each step is saved to the month's plan when moving on, so leaving halfway
/// keeps what was entered so far.
class GuidedPlanningScreen extends ConsumerStatefulWidget {
  const GuidedPlanningScreen({super.key});

  @override
  ConsumerState<GuidedPlanningScreen> createState() =>
      _GuidedPlanningScreenState();
}

class _GuidedPlanningScreenState extends ConsumerState<GuidedPlanningScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Null until the month's plan is loaded.
  List<_Step>? _steps;
  var _index = 0;
  var _saving = false;

  final _balance = TextEditingController();
  final _buffer = TextEditingController();

  final _giving = _NamedBudget(
    'Giving',
    isFixed: true,
    helperText: 'Leave empty to skip.',
  );
  final _rent = _NamedBudget(
    'Rent',
    isFixed: true,
    helperText: 'Rent or mortgage payment.',
  );
  final _utilities = _NamedBudget(
    'Utilities',
    isFixed: true,
    helperText: 'Electricity, heating, water and internet.',
  );
  final _groceries = _NamedBudget(
    'Groceries',
    isFixed: false,
    helperText: 'Food and other daily needs.',
  );
  final _transportation = _NamedBudget(
    'Transportation',
    isFixed: false,
    helperText: 'A transit pass, fuel or other costs of getting to work.',
  );
  var _needsTransportation = false;

  List<_NamedBudget> get _named => [
    _giving,
    _rent,
    _utilities,
    _groceries,
    _transportation,
  ];

  @override
  void dispose() {
    _balance.dispose();
    _buffer.dispose();
    for (final named in _named) {
      named.controller.dispose();
    }
    super.dispose();
  }

  /// Whether [_start] was called.
  var _started = false;

  /// Fills the steps in from the month's plan as it is, once it's loaded.
  Future<void> _start(
    Month month,
    List<Budget> budgets,
    Setting settings,
  ) async {
    _started = true;
    final db = ref.read(appDatabaseProvider);
    final hasMonthBefore = await db.hasMonthBefore(month.id);
    if (!mounted) return;

    setState(() {
      _buffer.text = formatAmount(settings.bufferCents);
      // The first month starts from what was in the account; without an
      // earlier month, the carryover is all of it above the buffer.
      final balanceCents = settings.bufferCents + month.carryOverCents;
      if (month.carryOverCents != 0 && balanceCents >= 0) {
        _balance.text = formatAmount(balanceCents);
      }
      for (final named in _named) {
        final budget = named.matchIn(budgets);
        if (budget != null && budget.amountCents > 0) {
          named.controller.text = formatAmount(budget.amountCents);
        }
      }
      _needsTransportation = _transportation.cents > 0;
      _steps = [
        if (!hasMonthBefore) _Step.balance,
        _Step.income,
        _Step.giving,
        _Step.essentials,
        _Step.everythingElse,
      ];
    });
  }

  Future<void> _next(Month month) async {
    if (!_formKey.currentState!.validate()) return;
    final steps = _steps!;
    setState(() => _saving = true);
    try {
      await _save(steps[_index], month);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    if (_index == steps.length - 1) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index++);
    }
  }

  void _back() => setState(() => _index--);

  Future<void> _save(_Step step, Month month) async {
    final db = ref.read(appDatabaseProvider);
    switch (step) {
      case _Step.balance:
        final balanceCents = parseAmountToCents(_balance.text)!;
        final bufferCents = parseAmountToCents(_buffer.text)!;
        await db.setBufferCents(bufferCents);
        await db.setCarryOverCents(month.id, balanceCents - bufferCents);
      case _Step.giving:
        await _saveNamed(month, [_giving]);
      case _Step.essentials:
        await _saveNamed(month, [_rent, _utilities, _groceries]);
        await db.setBudgetByName(
          month.id,
          _transportation.name,
          _needsTransportation ? _transportation.cents : 0,
          isFixed: _transportation.isFixed,
        );
      case _Step.income || _Step.everythingElse:
        // Saved as they're changed.
        break;
    }
  }

  Future<void> _saveNamed(Month month, List<_NamedBudget> named) async {
    final db = ref.read(appDatabaseProvider);
    for (final budget in named) {
      await db.setBudgetByName(
        month.id,
        budget.name,
        budget.cents,
        isFixed: budget.isFixed,
      );
    }
  }

  /// What's left to assign, counting giving and the essentials as they're
  /// entered, before they're saved.
  int _leftCents(Month month, List<Budget> budgets) {
    var assignedCents = 0;
    final matched = <int>{};
    for (final named in _named) {
      if (named.matchIn(budgets) case final budget?) matched.add(budget.id);
      if (named != _transportation || _needsTransportation) {
        assignedCents += named.cents;
      }
    }
    for (final budget in budgets) {
      if (!matched.contains(budget.id)) assignedCents += budget.amountCents;
    }
    return month.incomeCents + month.carryOverCents - assignedCents;
  }

  /// The budgets that aren't giving or one of the essentials.
  List<Budget> _otherBudgets(List<Budget> budgets) {
    final matched = {for (final named in _named) named.matchIn(budgets)?.id};
    return [
      for (final budget in budgets)
        if (!matched.contains(budget.id)) budget,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(currentMonthProvider).value;
    final incomes = ref.watch(currentIncomesProvider).value;
    final budgets = ref.watch(currentBudgetsProvider).value;
    final expenses = ref.watch(currentExpensesProvider).value;
    final settings = ref.watch(settingsProvider).value;
    if (!_started && month != null && budgets != null && settings != null) {
      _start(month, budgets, settings);
    }
    final steps = _steps;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          month == null
              ? 'Plan your month'
              : 'Plan ${formatMonth(month.year, month.month)}',
        ),
      ),
      body: LeafBackground(
        child: switch ((steps, month, incomes, budgets, expenses)) {
          (
            final steps?,
            final month?,
            final incomes?,
            final budgets?,
            final expenses?,
          ) =>
            _buildStep(steps, month, incomes, budgets, expenses),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _buildStep(
    List<_Step> steps,
    Month month,
    List<Income> incomes,
    List<Budget> budgets,
    List<Expense> expenses,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final step = steps[_index];
    final isLast = _index == steps.length - 1;
    final monthName = formatMonth(month.year, month.month);

    final (title, intro) = switch (step) {
      _Step.balance => (
        'Where you start',
        "Let's see what you have to plan $monthName with.",
      ),
      _Step.income => (
        'Your income',
        'What money comes in during $monthName? Add every source, like '
            'your salary or a side job.',
      ),
      _Step.giving => (
        'Giving first',
        'What do you want to give this month? To a charity, your church, '
            'or people you care about. It comes first in your plan.',
      ),
      _Step.essentials => (
        'The essentials',
        'Cover what you need to live and work before anything else. Leave '
            "any that don't apply empty.",
      ),
      _Step.everythingElse => (
        'Everything else',
        'Give the rest of your money a job: insurance, your phone, '
            'subscriptions, savings, or money for fun.',
      ),
    };

    final content = switch (step) {
      _Step.balance => _balanceStep(monthName),
      _Step.income => _incomeStep(month, incomes),
      _Step.giving => [
        AmountField(
          controller: _giving.controller,
          labelText: _giving.name,
          helperText: _giving.helperText,
          isRequired: false,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _next(month),
        ),
      ],
      _Step.essentials => _essentialsStep(month),
      _Step.everythingElse => _everythingElseStep(month, budgets, expenses),
    };

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: LinearProgressIndicator(value: (_index + 1) / steps.length),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: ListView(
                      key: ValueKey(step),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          'Step ${_index + 1} of ${steps.length}',
                          style: textTheme.labelSmall?.copyWith(
                            color: context.budgetColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(title, style: textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(intro, style: textTheme.bodyLarge),
                        const SizedBox(height: 24),
                        ...content,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (step != _Step.balance)
            _LeftToAssignBar(leftCents: _leftCents(month, budgets)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(
              children: [
                if (_index > 0)
                  OutlinedButton(
                    onPressed: _saving ? null : _back,
                    child: const Text('Back'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : () => _next(month),
                  child: Text(isLast ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _balanceStep(String monthName) {
    final balanceCents = parseAmountToCents(_balance.text);
    final bufferCents = parseAmountToCents(_buffer.text);
    return [
      AmountField(
        controller: _balance,
        labelText: 'Account balance',
        helperText:
            "What's in your account right now. Leave out this "
            "month's income if it came in already; that's next.",
        autofocus: true,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      AmountField(
        controller: _buffer,
        labelText: 'Buffer',
        helperText:
            'Always stays in your account as a safety net. You can '
            'change it later in Settings.',
        onChanged: (_) => setState(() {}),
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
    ];
  }

  List<Widget> _incomeStep(Month month, List<Income> incomes) {
    return [
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
    ];
  }

  List<Widget> _essentialsStep(Month month) {
    AmountField field(_NamedBudget named, {bool autofocus = false}) =>
        AmountField(
          controller: named.controller,
          labelText: named.name,
          helperText: named.helperText,
          isRequired: false,
          autofocus: autofocus,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        );

    return [
      field(_rent, autofocus: true),
      const SizedBox(height: 16),
      field(_utilities),
      const SizedBox(height: 16),
      field(_groceries),
      const SizedBox(height: 16),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('I need transportation for work'),
        subtitle: const Text('Getting to work costs money each month.'),
        value: _needsTransportation,
        onChanged: (value) => setState(() => _needsTransportation = value),
      ),
      if (_needsTransportation) field(_transportation),
      const SizedBox(height: 16),
      Text(
        'Rent and utilities are fixed costs: once you lock your plan in, '
        'they count as spent in full.',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: context.budgetColors.inkMuted),
      ),
    ];
  }

  List<Widget> _everythingElseStep(
    Month month,
    List<Budget> budgets,
    List<Expense> expenses,
  ) {
    final others = _otherBudgets(budgets);
    return [
      if (others.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('No other budgets yet.'),
        ),
      for (final budget in others)
        Card(
          child: ListTile(
            title: Row(
              children: [
                Flexible(
                  child: Text(budget.name, overflow: TextOverflow.ellipsis),
                ),
                if (budget.isFixed) ...[
                  const SizedBox(width: 8),
                  const FixedBadge(),
                ],
                if (budget.isSinkingFund) ...[
                  const SizedBox(width: 8),
                  const SinkingFundBadge(),
                ],
                if (budget.isSavings) ...[
                  const SizedBox(width: 8),
                  const SavingsBadge(),
                ],
              ],
            ),
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
    ];
  }
}

/// What's left to assign, kept in view while planning.
class _LeftToAssignBar extends StatelessWidget {
  const _LeftToAssignBar({required this.leftCents});

  final int leftCents;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (background, foreground, message) = switch (leftCents) {
      0 => (c.sproutTint, c.onSproutTint, 'Every euro has a job.'),
      > 0 => (c.highlight, c.onHighlight, 'Left to assign'),
      _ => (colors.error, colors.onError, 'Assigned more than you have'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BudgetRadius.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: textTheme.bodyLarge?.copyWith(color: foreground),
                ),
              ),
              Text(
                formatCents(leftCents.abs()),
                style: textTheme.titleMedium?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
