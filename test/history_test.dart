import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/history/history_screen.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Opens the history while October 2026 is the month being worked in,
  /// after [seed] filled in the database.
  Future<void> pumpHistory(
    WidgetTester tester, {
    Future<void> Function()? seed,
  }) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await seed?.call();
      const october = (year: 2026, month: 10);
      await db.selectMonth(october, calendar: october);
    });
    await tester.pumpWidget(
      testApp(db, const HistoryScreen(), today: DateTime(2026, 10, 1)),
    );
    await settleQueries(tester);
  }

  testWidgets('without past months, it says where they will be', (
    tester,
  ) async {
    await pumpHistory(tester);

    expect(find.textContaining('No past months yet.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('past months show what was spent, and open to look back', (
    tester,
  ) async {
    await pumpHistory(
      tester,
      seed: () async {
        final september = await db.getOrCreateMonth(2026, 9);
        await db.addIncome(september.id, 'Salary', 250000);
        await db.updateMonthNotes(september.id, 'Holiday in Italy');
        final food = await db.addBudget(september.id, 'Food', 40000);
        await db.addExpense(food, 50000, title: 'Market');
      },
    );

    // October is the month being worked in, so only September is past.
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('October 2026'), findsNothing);
    expect(find.text('500,00€ spent of 400,00€ planned'), findsOneWidget);
    expect(find.text('100,00€ over'), findsOneWidget);

    await tester.tap(find.text('September 2026'));
    await settleQueries(tester);
    expect(find.widgetWithText(AppBar, 'September 2026'), findsOneWidget);
    expect(find.text('Holiday in Italy'), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('400,00€'), findsWidgets);
    // 2500,00€ income less the 500,00€ spent.
    expect(find.text('Balance at month end'), findsOneWidget);
    expect(find.text('2000,00€'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    await unmount(tester);
  });
}
