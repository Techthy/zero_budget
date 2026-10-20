import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/savings/savings_goal_sheet.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Opens the sheet in October 2026, with [goalCents] as the yearly goal
  /// and 500.00 saved in September.
  Future<void> pumpSheet(WidgetTester tester, {int? goalCents}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Drift needs real time to run its queries outside the app.
    await tester.runAsync(() async {
      const october = (year: 2026, month: 10);
      await db.selectMonth(october, calendar: october);
      final september = await db.getOrCreateMonth(2026, 9);
      final savings = await db.addBudget(
        september.id,
        'Savings',
        50000,
        category: BudgetCategory.savings,
      );
      await db.addExpense(savings, 50000, title: 'Transfer');
      if (goalCents != null) {
        await db.setSavingsGoal(goalCents, SavingsPeriod.year);
      }
    });
    await tester.pumpWidget(
      testApp(
        db,
        const Scaffold(body: SavingsGoalSheet()),
        today: DateTime(2026, 10, 1),
      ),
    );
    await settleQueries(tester);
  }

  testWidgets('with a goal, it shows the growth and a pencil to change it', (
    tester,
  ) async {
    await pumpSheet(tester, goalCents: 200000);

    expect(find.text('Savings goal 2026'), findsOneWidget);
    expect(find.text('Growing strong'), findsNothing);
    expect(find.text('Sprouting'), findsOneWidget);
    expect(find.text('What you planted'), findsOneWidget);
    expect(find.byTooltip('Change goal'), findsOneWidget);
    expect(find.text('Set a goal'), findsNothing);

    await tester.tap(find.byTooltip('Change goal'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('without a goal, it asks to set one', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Grow your savings'), findsOneWidget);
    expect(find.byTooltip('Change goal'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Set a goal'), findsOneWidget);
    await unmount(tester);
  });
}
