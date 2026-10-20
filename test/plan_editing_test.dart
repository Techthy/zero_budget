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

  /// Opens the plan for October 2026, after [seed] filled in the database.
  Future<void> pumpPlan(
    WidgetTester tester, {
    Future<void> Function()? seed,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      const october = (year: 2026, month: 10);
      await db.selectMonth(october, calendar: october);
      await seed?.call();
    });
    await tester.pumpWidget(
      testApp(db, const PlanningScreen(), today: DateTime(2026, 10, 1)),
    );
    await settleQueries(tester);
  }

  group('the budget dialog', () {
    bool isChosen(WidgetTester tester, String category) => tester
        .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, category))
        .selected;

    bool isOn(WidgetTester tester, String setting) => tester
        .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, setting))
        .value;

    testWidgets('keeps savings, sinking funds and fixed costs apart', (
      tester,
    ) async {
      await pumpPlan(tester);
      await tapAndSettle(tester, find.text('Add budget'));
      expect(isChosen(tester, 'Other'), isTrue);

      // A sinking fund is never savings.
      await tapAndSettle(tester, find.widgetWithText(ChoiceChip, 'Savings'));
      expect(
        find.textContaining('Counts towards your savings goal'),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.text('Sinking fund'));
      expect(isOn(tester, 'Sinking fund'), isTrue);
      expect(isChosen(tester, 'Savings'), isFalse);
      expect(isChosen(tester, 'Other'), isTrue);
      await tapAndSettle(tester, find.widgetWithText(ChoiceChip, 'Savings'));
      expect(isOn(tester, 'Sinking fund'), isFalse);

      // Nor is it fixed.
      await tapAndSettle(tester, find.text('Fixed cost'));
      await tapAndSettle(tester, find.text('Sinking fund'));
      expect(isOn(tester, 'Fixed cost'), isFalse);
      await tapAndSettle(tester, find.text('Fixed cost'));
      expect(isOn(tester, 'Sinking fund'), isFalse);
      await unmount(tester);
    });

    testWidgets('asks for a name, then adds the budget as set', (tester) async {
      await pumpPlan(tester);
      await tapAndSettle(tester, find.text('Add budget'));
      await enterAmount(tester, 'Amount', '120');
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Add'));
      expect(find.text('Give this budget a name'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Insurance',
      );
      await tapAndSettle(tester, find.widgetWithText(ChoiceChip, 'Essential'));
      expect(find.textContaining('Needed to live and work'), findsOneWidget);
      await tapAndSettle(tester, find.text('Sinking fund'));
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await settleQueries(tester);

      final budget = (await tester.runAsync(() async {
        final month = await db.getOrCreateMonth(2026, 10);
        return (await db.watchBudgets(month.id).first).single;
      }))!;
      expect(
        (
          budget.name,
          budget.amountCents,
          budget.category,
          budget.isSinkingFund,
          budget.isFixed,
        ),
        ('Insurance', 12000, BudgetCategory.essential, true, false),
      );
      await unmount(tester);
    });
  });

  group('the carryover dialog', () {
    /// September leaves its 3000,00€ unspent, and October is set up.
    Future<void> carryOverFromSeptember() async {
      final september = await db.getOrCreateMonth(2026, 9);
      await db.addIncome(september.id, 'Salary', 300000);
      final october = await db.getOrCreateMonth(2026, 10);
      await db.setUpMonth(october.id, const {});
    }

    Future<Month> october(WidgetTester tester) async =>
        (await tester.runAsync(() => db.getOrCreateMonth(2026, 10)))!;

    Future<void> openDialog(WidgetTester tester) async {
      await tapAndSettle(tester, find.text('Left from last month').first);
      expect(find.widgetWithText(AlertDialog, 'Carried over'), findsOneWidget);
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settleQueries(tester);
    }

    testWidgets('corrects what last month left, and takes it back', (
      tester,
    ) async {
      await pumpPlan(tester, seed: carryOverFromSeptember);
      expect(find.text('+3000,00€'), findsOneWidget);

      await openDialog(tester);
      expect(find.textContaining('Last month left 3000,00€'), findsOneWidget);
      expect(find.text('Remove correction'), findsNothing);
      await enterAmount(tester, 'Amount', '2800');
      await save(tester);

      var month = await october(tester);
      expect(
        (month.carryOverCents, month.carryOverAdjustmentCents),
        (280000, -20000),
      );
      expect(
        find.text('Left from last month, incl. -200,00€ correction'),
        findsOneWidget,
      );

      await tapAndSettle(
        tester,
        find.text('Left from last month, incl. -200,00€ correction'),
      );
      await tapAndSettle(tester, find.text('Remove correction'));
      await save(tester);
      month = await october(tester);
      expect(
        (month.carryOverCents, month.carryOverAdjustmentCents),
        (300000, 0),
      );
      await unmount(tester);
    });

    testWidgets('takes an overspent month off this one', (tester) async {
      await pumpPlan(tester, seed: carryOverFromSeptember);

      await openDialog(tester);
      await enterAmount(tester, 'Amount', '50');
      await tapAndSettle(tester, find.text('Overspent'));
      await save(tester);

      expect((await october(tester)).carryOverCents, -5000);
      expect(find.text('-50,00€'), findsOneWidget);
      await unmount(tester);
    });
  });
}
