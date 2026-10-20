import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/month/month_providers.dart';
import 'package:zero_budget/planning/guided_planning_screen.dart';
import 'package:zero_budget/theme/budget_theme.dart';

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

    expect(find.text('Step 1 of 6'), findsOneWidget);
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
    await enterAmount(tester, 'Transportation', '80');
    await tester.pump();
    expect(find.text('1320,00€'), findsOneWidget);
    await tapAndSettle(tester, find.text('Next'));

    expect(find.text('Pay yourself'), findsOneWidget);
    expect(find.textContaining('Set a savings goal'), findsOneWidget);
    await enterAmount(tester, 'Savings', '300');
    await tester.pump();
    expect(find.text('1020,00€'), findsOneWidget);
    await tapAndSettle(tester, find.text('Next'));

    expect(find.text('Everything else'), findsOneWidget);
    expect(find.text('No other budgets yet.'), findsOneWidget);
    await tapAndSettle(tester, find.text('Add budget'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Phone');
    await enterAmount(tester, 'Amount', '20');
    await tapAndSettle(tester, find.text('Add'));
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('1000,00€'), findsOneWidget);
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
    expect(budgets.map((b) => (b.name, b.amountCents, b.isFixed, b.category)), [
      ('Giving', 10000, false, BudgetCategory.giving),
      ('Rent', 90000, true, BudgetCategory.essential),
      ('Utilities', 20000, false, BudgetCategory.essential),
      ('Groceries', 40000, false, BudgetCategory.essential),
      ('Transportation', 8000, false, BudgetCategory.essential),
      ('Savings', 30000, true, BudgetCategory.savings),
      ('Phone', 2000, false, BudgetCategory.other),
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
      await db.addBudget(
        september.id,
        'ETF',
        20000,
        isFixed: true,
        category: BudgetCategory.savings,
      );
      await db.addBudget(
        september.id,
        'Church',
        5000,
        category: BudgetCategory.giving,
      );
      await db.setSavingsGoal(600000, SavingsPeriod.year);
    });

    await pumpScreen(tester);

    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Your income'), findsOneWidget);
    expect(find.text('Job'), findsOneWidget);
    await tapAndSettle(tester, find.text('Next'));

    // The giving budget there already, whatever it's called.
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, 'Giving'))
          .controller!
          .text,
      '50.00',
    );
    await enterAmount(tester, 'Giving', '60');
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

    // The savings budget there already, whatever it's called.
    final savings = find.widgetWithText(TextFormField, 'Savings');
    expect(tester.widget<TextFormField>(savings).controller!.text, '200.00');
    // Nothing saved yet this year, and three months left to reach 6000€.
    expect(find.text('Your goal for 2026: 6000,00€'), findsOneWidget);
    await tapAndSettle(tester, find.text('Use 2000,00€'));
    expect(tester.widget<TextFormField>(savings).controller!.text, '2000.00');
    await tapAndSettle(tester, find.text('Next'));

    // Rent is an essential, the ETF is savings and the church is giving, so
    // only the gym is left.
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Rent'), findsNothing);
    expect(find.text('ETF'), findsNothing);
    expect(find.text('Church'), findsNothing);
    await tapAndSettle(tester, find.text('Finish'));

    final budgets = (await tester.runAsync(() async {
      final october = await db.getOrCreateMonth(2026, 10);
      return db.watchBudgets(october.id).first;
    }))!;
    expect(budgets.map((b) => (b.name, b.amountCents, b.category)), [
      ('Rent', 95000, BudgetCategory.essential),
      ('Gym', 3000, BudgetCategory.other),
      ('ETF', 200000, BudgetCategory.savings),
      ('Church', 6000, BudgetCategory.giving),
    ]);
  });
}
