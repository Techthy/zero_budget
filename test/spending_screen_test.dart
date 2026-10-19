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
      await db.setSavingsGoal(500000, SavingsPeriod.year);
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

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
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
    expect(find.text('Saved'), findsOneWidget);
    expect(
      find.text('Contributed towards the goal of 5000,00€'),
      findsOneWidget,
    );
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
    expect(
      find.text('Tap a flow to see its full name and numbers.'),
      findsOneWidget,
    );

    // Tapping the top budget, the fixed rent, shows its details.
    final plot = find
        .descendant(
          of: find.byType(BudgetSankey),
          matching: find.byType(CustomPaint),
        )
        .first;
    await tester.ensureVisible(plot);
    await tester.pumpAndSettle();
    final rect = tester.getRect(plot);
    await tester.tapAt(Offset(rect.right - 4, rect.top + 24 + 8));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fixed budget · 98765,43€'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('adding an expense from a budget picks that budget', (
    tester,
  ) async {
    await pumpScreen(tester);

    final groceries = find.text('Groceries');
    await tester.scrollUntilVisible(groceries, 200);
    await tester.ensureVisible(groceries);
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(rent);
    await tester.pumpAndSettle();
    expect(find.text('Paid in full'), findsOneWidget);
    await tester.tap(rent);
    await tester.pumpAndSettle();
    expect(find.text('Fixed cost'), findsOneWidget);
    expect(find.text('Add expense'), findsNothing);
    await unmount(tester);
  });

  testWidgets('editing an expense changes it in place', (tester) async {
    await pumpScreen(tester);

    final groceries = find.text('Groceries');
    await tester.scrollUntilVisible(groceries, 200);
    await tester.ensureVisible(groceries);
    await tester.pumpAndSettle();
    await tester.tap(groceries);
    await tester.pumpAndSettle();

    final edit = find.byTooltip('Edit expense');
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.text('Edit expense'), findsOneWidget);
    expect(find.text('Too many snacks'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Expense title'),
      'Snacks',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '45');
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    final expenses = (await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 10);
      return db.watchExpenses(month.id).first;
    }))!;
    final snacks = expenses.singleWhere((e) => e.budgetId == groceriesId);
    expect((snacks.title, snacks.amountCents), ('Snacks', 4500));
    expect(find.text('Snacks'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('budgets are listed by category or from A to Z', (tester) async {
    await pumpScreen(tester);
    // Tall enough to show every budget at once.
    tester.view.physicalSize = const Size(320, 3000);
    await tester.pumpAndSettle();

    const long = 'A budget with a really very long name that goes on';
    List<String> listed() {
      final names = ['Rent', 'Groceries', long, 'Holiday'];
      return names..sort(
        (a, b) => tester
            .getTopLeft(find.text(a).last)
            .dy
            .compareTo(tester.getTopLeft(find.text(b).last).dy),
      );
    }

    // The rent is an essential, the long one is savings.
    expect(listed(), ['Rent', 'Groceries', long, 'Holiday']);

    await tapAndSettle(tester, find.byTooltip('Sort budgets'));
    await tapAndSettle(tester, find.text('A to Z'));
    expect(listed(), [long, 'Groceries', 'Holiday', 'Rent']);
    final settings = (await tester.runAsync(() => db.watchSettings().first))!;
    expect(settings.budgetOrder, BudgetOrder.alphabetical);
    await unmount(tester);
  });
}
