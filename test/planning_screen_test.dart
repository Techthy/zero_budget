import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/planning/planning_screen.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Opens the plan for October 2026, tall enough to show all of it.
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(
      () => db.selectMonth(
        (year: 2026, month: 10),
        calendar: (year: 2026, month: 10),
      ),
    );
    await tester.pumpWidget(
      testApp(db, const PlanningScreen(), today: DateTime(2026, 10, 1)),
    );
    await settleQueries(tester);
  }

  Finder lockInButton() => find.widgetWithText(FilledButton, 'Lock in budget');

  bool isEnabled(WidgetTester tester, Finder button) =>
      tester.widget<ButtonStyleButton>(button).onPressed != null;

  /// Adds a budget with the dialog, as [category] and fixed when [isFixed].
  Future<void> addBudget(
    WidgetTester tester,
    String name,
    String amount, {
    String category = 'Other',
    bool isFixed = false,
  }) async {
    await tapAndSettle(tester, find.text('Add budget'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), name);
    await enterAmount(tester, 'Amount', amount);
    await tapAndSettle(tester, find.widgetWithText(ChoiceChip, category));
    if (isFixed) await tapAndSettle(tester, find.text('Fixed cost'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await settleQueries(tester);
  }

  testWidgets('a first plan is filled in and locked in once it adds up', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Welcome!'), findsOneWidget);
    expect(
      find.text('Add your income and budgets before locking in.'),
      findsOneWidget,
    );
    expect(isEnabled(tester, lockInButton()), isFalse);

    await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 10);
      await db.addIncome(month.id, 'Salary', 250000);
    });
    await settleQueries(tester);

    await addBudget(
      tester,
      'Rent',
      '900',
      category: 'Essential',
      isFixed: true,
    );
    final rent = find.ancestor(
      of: find.text('Rent'),
      matching: find.byType(ListTile),
    );
    for (final badge in ['Fixed', 'Essential']) {
      expect(
        find.descendant(of: rent, matching: find.text(badge)),
        findsOneWidget,
      );
    }
    expect(
      find.text('Assign the remaining 1600,00€ before locking in.'),
      findsOneWidget,
    );

    await addBudget(tester, 'Fun', '1700');
    expect(
      find.text('Take 100,00€ off your budgets before locking in.'),
      findsOneWidget,
    );
    expect(isEnabled(tester, lockInButton()), isFalse);

    // Taking it off the budget that went over balances the plan.
    await tapAndSettle(tester, find.text('Fun'));
    expect(find.text('Edit budget'), findsOneWidget);
    await enterAmount(tester, 'Amount', '1600');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settleQueries(tester);
    expect(find.text('Every euro has a job.'), findsOneWidget);
    expect(isEnabled(tester, lockInButton()), isTrue);

    await tester.tap(lockInButton());
    await settleQueries(tester);
    expect(find.text('Planned budget'), findsOneWidget);
    expect(lockInButton(), findsNothing);

    // Locking in spends fixed budgets in full.
    final (month, expenses) = (await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 10);
      return (month, await db.watchExpenses(month.id).first);
    }))!;
    expect(month.lockedAt, isNotNull);
    expect(expenses.map((e) => (e.amountCents, e.isFixed)), [(90000, true)]);
    await unmount(tester);
  });
}
