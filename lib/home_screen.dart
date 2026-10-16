import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database_provider.dart';
import 'dates.dart';
import 'debug/month_travel_bar.dart';
import 'savings/savings_goal_sheet.dart';
import 'spending/add_expense_screen.dart';
import 'settings/settings_providers.dart';
import 'settings/settings_screen.dart';
import 'spending/spending_screen.dart';
import 'welcome/welcome_providers.dart';
import 'welcome/welcome_screen.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/month_switcher.dart';

enum _Tab { plan, track }

/// Plan the month, then track spending against it, with a button in between
/// to quickly add an expense.
///
/// The plan is edited until it's locked in; tracking pauses while it's
/// unlocked for editing again. Once a new month starts, the user is asked
/// whether to move on to it.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _tab = _Tab.plan;
  late final AppLifecycleListener _lifecycle;

  /// The month the user is or was last asked to move on to, so they're
  /// asked only once.
  YearMonth? _offeredMonth;

  @override
  void initState() {
    super.initState();
    // A new day, and maybe a new month, may have started in the background.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(todayProvider),
    );
    ref.listenManual(
      monthToOfferProvider,
      (_, month) {
        // Not while reloading, which still has the month from before.
        if (month case AsyncData(value: final month?)) _offerMonth(month);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _offerMonth(YearMonth month) async {
    if (month == _offeredMonth) return;
    _offeredMonth = month;
    // Dialogs can't be shown while building.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final monthName = formatMonth(month.year, month.month);
    final start = await showConfirmDialog(
      context,
      title: '$monthName has started',
      message: 'Do you want to start planning $monthName? You can switch '
          'months at the top any time.',
      confirmLabel: 'Start planning',
      cancelLabel: 'Not yet',
    );
    if (!mounted) return;
    final db = ref.read(appDatabaseProvider);
    if (start) {
      setState(() => _tab = _Tab.plan);
      await db.selectMonth(month, calendar: month);
    } else {
      await db.declineMonth(month);
    }
  }

  void _addExpense(bool isLocked) {
    // A snack bar from the last expense would cover the button to add one.
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (!isLocked) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lock in your plan to start tracking expenses.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const AddExpenseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLockedProvider = currentMonthProvider.select(
      (month) => month.value?.lockedAt != null,
    );
    final isLocked = ref.watch(isLockedProvider);
    // Locking the plan in starts tracking, and an unlocked plan needs work,
    // so follow along. This also picks the tab the app opens on.
    ref.listen(
      isLockedProvider,
      (_, isLocked) => setState(() => _tab = isLocked ? _Tab.track : _Tab.plan),
    );

    Widget body = IndexedStack(
      index: _tab.index,
      children: const [WelcomeScreen(), SpendingScreen()],
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
