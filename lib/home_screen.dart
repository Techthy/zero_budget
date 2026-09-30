import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'debug/month_travel_bar.dart';
import 'spending/add_expense_screen.dart';
import 'spending/spending_screen.dart';
import 'welcome/welcome_providers.dart';
import 'welcome/welcome_screen.dart';

enum _Tab { plan, track }

/// Plan the month, then track spending against it, with a button in between
/// to quickly add an expense.
///
/// The plan is edited until it's locked in; tracking pauses while it's
/// unlocked for editing again.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _tab = _Tab.plan;

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
    if (kDebugMode) {
      body = Column(
        children: [
          const MonthTravelBar(),
          Expanded(
            // The bar already keeps clear of the status bar.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: body,
            ),
          ),
        ],
      );
    }

    return Scaffold(
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
