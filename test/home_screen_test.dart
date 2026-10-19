import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/home_screen.dart';
import 'package:zero_budget/theme/budget_theme.dart';
import 'package:zero_budget/welcome/welcome_providers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Opens the app in October 2026, with a plan ready to lock in, locked in
  /// already when [locked].
  Future<void> pumpApp(WidgetTester tester, {bool locked = false}) async {
    // Drift needs real time to run its queries outside the app, and writes
    // from here would wait on the app's streams, so set up first.
    await tester.runAsync(() async {
      const october = (year: 2026, month: 10);
      await db.selectMonth(october, calendar: october);
      final month = await db.getOrCreateMonth(2026, 10);
      await db.addIncome(month.id, 'Job', 250000);
      await db.addBudget(month.id, 'Rent', 250000, isFixed: true);
      if (locked) await db.lockMonth(month.id);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(DateTime(2026, 10, 1)),
        ],
        child: MaterialApp(
          theme: budgetTheme(Brightness.light),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Unmounts the app while the test still runs, so the database streams it
  /// closes can finish.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Runs the timers drift starts when its streams close.
    await tester.pump(Duration.zero);
  }

  int selectedTab(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('a locked in month opens on tracking', (tester) async {
    await pumpApp(tester, locked: true);

    expect(selectedTab(tester), 2);
    await unmount(tester);
  });

  testWidgets('locking in stays on the plan', (tester) async {
    await pumpApp(tester);
    expect(selectedTab(tester), 0);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            (widget is Text && widget.data == 'Lock') ||
            (widget is Tooltip && widget.message == 'Lock'),
      ),
    );
    await tester.pumpAndSettle();

    final month = (await tester.runAsync(() => db.getOrCreateMonth(2026, 10)))!;
    expect(month.lockedAt, isNotNull);
    expect(selectedTab(tester), 0);
    await unmount(tester);
  });
}
