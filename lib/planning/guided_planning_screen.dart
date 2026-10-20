import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../data/database.dart';
import '../data/database_provider.dart';
import '../data/month_math.dart';
import '../dates.dart';
import '../money.dart';
import '../month/month_providers.dart';
import '../settings/settings_providers.dart';
import '../theme/budget_theme.dart';
import '../widgets/leaf_background.dart';
import 'guided_budgets.dart';
import 'guided_planning_steps.dart';
import 'left_to_assign.dart';

/// Opens the guided planning for the current month.
Future<void> startGuidedPlanning(BuildContext context) =>
    Navigator.of(context).push(guidedPlanningRoute());

/// The route of the guided planning, for when the context that opens it
/// goes away first.
Route<void> guidedPlanningRoute() => MaterialPageRoute<void>(
  fullscreenDialog: true,
  builder: (_) => const GuidedPlanningScreen(),
);

enum _Step { balance, income, giving, essentials, savings, everythingElse }

/// Walks through planning the current month one step at a time: the starting
/// balance (only before there's a month to carry money over from), income,
/// giving, the essentials, savings, and everything else.
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
  final _balance = TextEditingController();
  final _buffer = TextEditingController();
  final _budgets = GuidedBudgets();

  /// Null until the month's plan is loaded.
  List<_Step>? _steps;
  var _index = 0;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _balance.dispose();
    _buffer.dispose();
    _budgets.dispose();
    super.dispose();
  }

  /// Fills the steps in from the month's plan as it is.
  Future<void> _start() async {
    final month = await _load(currentMonthProvider.future);
    final budgets = await _load(currentBudgetsProvider.future);
    final settings = await _load(settingsProvider.future);
    final hasMonthBefore = await ref
        .read(appDatabaseProvider)
        .hasMonthBefore(month.id);
    if (!mounted) return;

    setState(() {
      _buffer.text = formatAmount(settings.bufferCents);
      // The first month starts from what was in the account; without an
      // earlier month, the carryover is all of it above the buffer.
      final balanceCents = settings.bufferCents + month.carryOverCents;
      if (month.carryOverCents != 0 && balanceCents >= 0) {
        _balance.text = formatAmount(balanceCents);
      }
      _budgets.fillFrom(budgets);
      _steps = [
        if (!hasMonthBefore) _Step.balance,
        _Step.income,
        _Step.giving,
        _Step.essentials,
        _Step.savings,
        _Step.everythingElse,
      ];
    });
  }

  /// What [provider] has once it's loaded, kept alive while waiting for it.
  Future<T> _load<T>(ProviderListenable<Future<T>> provider) async {
    final subscription = ref.listenManual(provider, (_, _) {});
    try {
      return await subscription.read();
    } finally {
      subscription.close();
    }
  }

  /// Shows what was typed, like in what's left to assign.
  void _refresh() => setState(() {});

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
    switch (step) {
      case _Step.balance:
        await _saveBalance(month);
      case _Step.giving:
        await _saveBudgets([_budgets.giving], month);
      case _Step.essentials:
        await _saveBudgets(_budgets.essentials, month);
      case _Step.savings:
        await _saveBudgets([_budgets.savings], month);
      case _Step.income || _Step.everythingElse:
        // Saved as they're changed.
        break;
    }
  }

  /// Keeps the buffer, and starts the month with the balance above it.
  Future<void> _saveBalance(Month month) async {
    final db = ref.read(appDatabaseProvider);
    final balanceCents = parseAmountToCents(_balance.text)!;
    final bufferCents = parseAmountToCents(_buffer.text)!;
    await db.setBufferCents(bufferCents);
    await db.setCarryOverCents(month.id, balanceCents - bufferCents);
  }

  Future<void> _saveBudgets(List<GuidedBudget> guided, Month month) async {
    final db = ref.read(appDatabaseProvider);
    final budgets = await ref.read(currentBudgetsProvider.future);
    for (final budget in guided) {
      await budget.saveTo(db, month.id, budgets);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(currentMonthDetailsProvider).value;
    final steps = _steps;

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (details?.month) {
          final month? => 'Plan ${formatMonth(month.year, month.month)}',
          null => 'Plan your month',
        }),
      ),
      body: LeafBackground(
        child: steps == null || details == null
            ? const Center(child: CircularProgressIndicator())
            : _buildStep(steps, details),
      ),
    );
  }

  Widget _buildStep(List<_Step> steps, MonthDetails details) {
    final textTheme = Theme.of(context).textTheme;
    final step = steps[_index];
    final month = details.month;
    final (title, intro) = _titleAndIntro(
      step,
      formatMonth(month.year, month.month),
    );

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
                        _content(step, details),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (step != _Step.balance)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: LeftToAssign.compact(
                  leftCents: _budgets.leftToAssignCents(month, details.budgets),
                  assignableCents: month.assignableCents,
                ),
              ),
            ),
          _StepButtons(
            canGoBack: _index > 0,
            isLast: _index == steps.length - 1,
            isSaving: _saving,
            onBack: _back,
            onNext: () => _next(month),
          ),
        ],
      ),
    );
  }

  Widget _content(_Step step, MonthDetails details) {
    final month = details.month;
    return switch (step) {
      _Step.balance => BalanceStep(
        balance: _balance,
        buffer: _buffer,
        monthName: formatMonth(month.year, month.month),
        onChanged: _refresh,
      ),
      _Step.income => IncomeStep(month: month, incomes: details.incomes),
      _Step.giving => GuidedAmountField(
        _budgets.giving,
        autofocus: true,
        onChanged: _refresh,
        onSubmitted: () => _next(month),
      ),
      _Step.essentials => EssentialsStep(
        essentials: _budgets.essentials,
        onChanged: _refresh,
      ),
      _Step.savings => SavingsStep(
        savings: _budgets.savings,
        month: month,
        onChanged: _refresh,
        onSubmitted: () => _next(month),
      ),
      _Step.everythingElse => EverythingElseStep(
        month: month,
        others: _budgets.othersIn(details.budgets),
        expenses: details.expenses,
      ),
    };
  }
}

(String, String) _titleAndIntro(_Step step, String monthName) => switch (step) {
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
  _Step.savings => (
    'Pay yourself',
    'What do you want to put aside this month? It counts towards your '
        'savings goal.',
  ),
  _Step.everythingElse => (
    'Everything else',
    'Give the rest of your money a job: insurance, subscriptions, or '
        'money for fun.',
  ),
};

/// Back and Next, or Finish on the last step. Both wait while a step is
/// saved.
class _StepButtons extends StatelessWidget {
  const _StepButtons({
    required this.canGoBack,
    required this.isLast,
    required this.isSaving,
    required this.onBack,
    required this.onNext,
  });

  final bool canGoBack;
  final bool isLast;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: [
          if (canGoBack)
            OutlinedButton(
              onPressed: isSaving ? null : onBack,
              child: const Text('Back'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: isSaving ? null : onNext,
            child: Text(isLast ? 'Finish' : 'Next'),
          ),
        ],
      ),
    );
  }
}
