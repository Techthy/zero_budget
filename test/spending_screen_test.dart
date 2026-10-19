import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/spending/spending_screen.dart';
import 'package:zero_budget/theme/budget_theme.dart';
import 'package:zero_budget/welcome/welcome_providers.dart';
import 'package:zero_budget/widgets/budget_sankey.dart';

void main() {
  late AppDatabase db;
  late int groceriesId;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Opens the tracking screen for a locked in October 2026, on a narrow
  /// phone, with long names and large amounts to catch overflows.
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Drift needs real time to run its queries outside the app.
    await tester.runAsync(() async {
      const october = (year: 2026, month: 10);
      await db.selectMonth(october, calendar: october);
      final month = await db.getOrCreateMonth(2026, 10);
      await db.addIncome(month.id, 'Salary', 123456789);
      await db.addBudget(month.id, 'Rent', 9876543, isFixed: true);
      groceriesId = await db.addBudget(month.id, 'Groceries', 40000);
      final long = await db.addBudget(
        month.id,
        'A budget with a really very long name that goes on',
        99999999,
        isSavings: true,
      );
      await db.addBudget(month.id, 'Holiday', 10000, isSinkingFund: true);
      await db.lockMonth(month.id);
      await db.addExpense(long, 12345678, title: 'Transfer');
      await db.addExpense(groceriesId, 50000, title: 'Too many snacks');
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(DateTime(2026, 10, 20)),
        ],
        child: MaterialApp(
          theme: budgetTheme(Brightness.light),
          home: const SpendingScreen(),
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

  testWidgets('shows the month at a glance without overflowing', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Left to spend'), findsOneWidget);
    expect(find.text('Bank balance'), findsOneWidget);
    expect(find.text('Per day'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('1 budget is over'), findsOneWidget);
    expect(find.text('Sinking funds'), findsOneWidget);
    expect(find.text('Change buffer'), findsNothing);

    // The diagram is folded away until it's wanted.
    expect(find.byType(BudgetSankey), findsNothing);
    final diagram = find.text('Where your money goes');
    await tester.scrollUntilVisible(diagram, 200);
    await tester.tap(diagram);
    await tester.pumpAndSettle();
    expect(find.byType(BudgetSankey), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('adding an expense from a budget picks that budget', (
    tester,
  ) async {
    await pumpScreen(tester);

    final groceries = find.text('Groceries');
    await tester.scrollUntilVisible(groceries, 200);
    expect(find.text('100,00€ over'), findsOneWidget);
    expect(find.text('Add expense'), findsNothing);
    await tester.tap(groceries);
    await tester.pumpAndSettle();
    expect(find.text('Too many snacks'), findsOneWidget);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    expect(find.text('New expense'), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.textContaining('Groceries'),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(chip.selected, isTrue);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Expense title'),
      'Bread',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '3');
    await tester.tap(find.widgetWithText(FilledButton, 'Add expense'));
    await tester.pumpAndSettle();

    final expenses = (await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 10);
      return db.watchExpenses(month.id).first;
    }))!;
    expect(expenses.where((e) => e.title == 'Bread').map((e) => e.budgetId), [
      groceriesId,
    ]);
    await unmount(tester);
  });

  testWidgets('fixed budgets are paid in full and take no expenses', (
    tester,
  ) async {
    await pumpScreen(tester);

    final rent = find.text('Rent');
    await tester.scrollUntilVisible(rent, 200);
    expect(find.text('Paid in full'), findsOneWidget);
    await tester.tap(rent);
    await tester.pumpAndSettle();
    expect(find.text('Fixed cost'), findsOneWidget);
    expect(find.text('Add expense'), findsNothing);
    await unmount(tester);
  });
}
