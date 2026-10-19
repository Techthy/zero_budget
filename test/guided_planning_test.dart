import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/theme/budget_theme.dart';
import 'package:zero_budget/welcome/guided_planning_screen.dart';
import 'package:zero_budget/welcome/welcome_providers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Opens the guided planning for October 2026, which the app has already
  /// selected by then.
  Future<void> pumpScreen(WidgetTester tester) async {
    // Drift needs real time to run its queries outside the app.
    await tester.runAsync(
      () => db.selectMonth(
        (year: 2026, month: 10),
        calendar: (year: 2026, month: 10),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(DateTime(2026, 10, 1)),
        ],
        child: MaterialApp(
          theme: budgetTheme(Brightness.light),
          home: const GuidedPlanningScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterAmount(WidgetTester tester, String label, String amount) =>
      tester.enterText(find.widgetWithText(TextFormField, label), amount);

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the first plan goes from the balance to every budget', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Where you start'), findsOneWidget);
    await enterAmount(tester, 'Account balance', '1500');
    await enterAmount(tester, 'Buffer', '1000');
    expect(find.textContaining('with 500,00€ to plan'), findsOneWidget);
    await tapAndSettle(tester, find.text('Next'));

    expect(find.text('Your income'), findsOneWidget);
    await tapAndSettle(tester, find.text('Add income'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Job');
    await enterAmount(tester, 'Amount', '2500');
    await tapAndSettle(tester, find.text('Add'));
    expect(find.text('3000,00€'), findsOneWidget);
    await tapAndSettle(tester, find.text('Next'));

    expect(find.text('Giving first'), findsOneWidget);
    await enterAmount(tester, 'Giving', '100');
    await tapAndSettle(tester, find.text('Next'));

    expect(find.text('The essentials'), findsOneWidget);
    await enterAmount(tester, 'Rent', '900');
    await enterAmount(tester, 'Utilities', '200');
    await enterAmount(tester, 'Groceries', '400');
    await tapAndSettle(tester, find.text('I need transportation for work'));
    await enterAmount(tester, 'Transportation', '80');
    await tester.pump();
    expect(find.text('1320,00€'), findsOneWidget);
    await tapAndSettle(tester, find.text('Next'));

    expect(find.text('Everything else'), findsOneWidget);
    expect(find.text('No other budgets yet.'), findsOneWidget);
    await tapAndSettle(tester, find.text('Add budget'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Phone');
    await enterAmount(tester, 'Amount', '20');
    await tapAndSettle(tester, find.text('Add'));
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('1300,00€'), findsOneWidget);
    await tapAndSettle(tester, find.text('Finish'));

    final (month, settings, budgets) = (await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 10);
      return (
        month,
        await db.watchSettings().first,
        await db.watchBudgets(month.id).first,
      );
    }))!;
    expect(month.carryOverCents, 50000);
    expect(month.incomeCents, 250000);
    expect(settings.bufferCents, 100000);
    expect(budgets.map((b) => (b.name, b.amountCents, b.isFixed)), [
      ('Giving', 10000, true),
      ('Rent', 90000, true),
      ('Utilities', 20000, true),
      ('Groceries', 40000, false),
      ('Transportation', 8000, false),
      ('Phone', 2000, false),
    ]);
  });

  testWidgets('a later month skips the balance and starts from its plan', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final september = await db.getOrCreateMonth(2026, 9);
      await db.addIncome(september.id, 'Job', 250000);
      await db.addBudget(september.id, 'Rent', 90000, isFixed: true);
      await db.addBudget(september.id, 'Gym', 3000);
    });

    await pumpScreen(tester);

    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Your income'), findsOneWidget);
    expect(find.text('Job'), findsOneWidget);
    await tapAndSettle(tester, find.text('Next'));
    // No giving last month: skipped by leaving it empty.
    await tapAndSettle(tester, find.text('Next'));

    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, 'Rent'))
          .controller!
          .text,
      '900.00',
    );
    await enterAmount(tester, 'Rent', '950');
    await tapAndSettle(tester, find.text('Next'));

    // Rent is an essential, so only the gym is left here.
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Rent'), findsNothing);
    await tapAndSettle(tester, find.text('Finish'));

    final budgets = (await tester.runAsync(() async {
      final october = await db.getOrCreateMonth(2026, 10);
      return db.watchBudgets(october.id).first;
    }))!;
    expect(budgets.map((b) => (b.name, b.amountCents)), [
      ('Rent', 95000),
      ('Gym', 3000),
    ]);
  });
}
