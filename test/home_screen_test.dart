import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/home_screen.dart';
import 'package:zero_budget/main.dart';
import 'package:zero_budget/money.dart';
import 'package:zero_budget/month/month_providers.dart';
import 'package:zero_budget/theme/budget_theme.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Opens the app in October 2026, with a plan ready to lock in, locked in
  /// already when [locked]. It's [today], the 1st by default.
  Future<void> pumpApp(
    WidgetTester tester, {
    bool locked = false,
    DateTime? today,
  }) async {
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
          todayProvider.overrideWithValue(today ?? DateTime(2026, 10, 1)),
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

  /// Lets the app's queries finish: watching the database from inside the
  /// app needs real time and fake time in turns.
  Future<void> settleQueries(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();
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

  testWidgets('days before it starts, both tabs offer the next month', (
    tester,
  ) async {
    await pumpApp(tester, locked: true, today: DateTime(2026, 10, 29));
    expect(selectedTab(tester), 2);
    expect(find.text('November 2026 starts in 3 days'), findsOneWidget);

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('November 2026 starts in 3 days'), findsOneWidget);

    // Moving on opens November's plan, a copy of October's.
    await tester.tap(find.text('Track'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan November 2026'));
    await settleQueries(tester);
    expect(find.text('November 2026'), findsOneWidget);
    expect(selectedTab(tester), 0);
    expect(find.text('November 2026 starts in 3 days'), findsNothing);
    final november = (await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 11);
      return db.watchBudgets(month.id).first;
    }))!;
    expect(november.map((b) => b.name), ['Rent']);
    await unmount(tester);
  });

  testWidgets('not yet stays in the month and hides the offer', (tester) async {
    await pumpApp(tester, locked: true, today: DateTime(2026, 11, 3));
    expect(find.text('November 2026 has started'), findsOneWidget);

    await tester.tap(find.text('Not yet'));
    await settleQueries(tester);
    expect(find.text('November 2026 has started'), findsNothing);
    expect(find.text('October 2026'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('choosing a currency shows every amount in it', (tester) async {
    addTearDown(() => currency = Currency.eur);
    await tester.runAsync(() async {
      const october = (year: 2026, month: 10);
      await db.selectMonth(october, calendar: october);
      final month = await db.getOrCreateMonth(2026, 10);
      await db.addIncome(month.id, 'Job', 250000);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(DateTime(2026, 10, 1)),
        ],
        child: const MainApp(),
      ),
    );
    await settleQueries(tester);
    expect(find.textContaining('2500,00€'), findsWidgets);

    await tester.runAsync(() => db.setCurrency(Currency.usd));
    await settleQueries(tester);
    expect(find.textContaining('2500,00€'), findsNothing);
    expect(find.textContaining(r'$2500.00'), findsWidgets);
    await unmount(tester);
  });
}
