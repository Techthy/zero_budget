import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'debug/month_travel_bar.dart';
import 'savings/savings_goal_sheet.dart';
import 'spending/add_expense_screen.dart';
import 'settings/settings_providers.dart';
import 'settings/settings_screen.dart';
import 'spending/spending_screen.dart';
import 'planning/planning_providers.dart';
import 'planning/planning_screen.dart';
import 'widgets/month_switcher.dart';

enum _Tab { plan, track }

/// Plan the month, then track spending against it, with a button in between
/// to quickly add an expense.
///
/// The plan is edited until it's locked in; tracking pauses while it's
/// unlocked for editing again. A few days before a month ends, both tabs
/// offer to move on to the next one.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _tab = _Tab.plan;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // A new day, and maybe a new month, may have started in the background.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(todayProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _addExpense(bool isLocked) {
    if (!isLocked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Lock in your plan to start tracking expenses.'),
          ),
        );
      return;
    }
    openAddExpense(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLockedProvider = currentMonthProvider.select(
      (month) => month.value?.lockedAt != null,
    );
    final isLocked = ref.watch(isLockedProvider);
    // A month that's locked in opens on tracking, one still being planned on
    // the plan: when the app opens and when switching months. Locking or
    // unlocking the month at hand stays on the tab it was done on.
    ref.listen(
      currentMonthProvider.select(
        (month) => (
          id: month.value?.id,
          isLocked: month.value?.lockedAt != null,
        ),
      ),
      (previous, next) {
        if (next.id == null || next.id == previous?.id) return;
        setState(() => _tab = next.isLocked ? _Tab.track : _Tab.plan);
      },
    );

    Widget body = IndexedStack(
      index: _tab.index,
      children: const [PlanningScreen(), SpendingScreen()],
    );
    final showDebugBar = ref.watch(
      settingsProvider.select((settings) => settings.value?.showDebugBar),
    );
    if (kDebugMode && (showDebugBar ?? false)) {
      body = Column(
        children: [
          const MonthTravelBar(),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const MonthSwitcher(),
        actions: const [SavingsPlantButton(), SettingsButton()],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: switch (_tab) {
          _Tab.plan => 0,
          _Tab.track => 2,
        },
        onDestinationSelected: (index) => switch (index) {
          0 => setState(() => _tab = _Tab.plan),
          2 => setState(() => _tab = _Tab.track),
          _ => _addExpense(isLocked),
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: _AddExpenseIcon(),
            label: 'Add',
            tooltip: 'Add expense',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Track',
          ),
        ],
      ),
    );
  }
}

/// A filled plus, so adding an expense stands out from the tabs beside it.
class _AddExpenseIcon extends StatelessWidget {
  const _AddExpenseIcon();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.add, color: colors.onPrimary),
    );
  }
}
