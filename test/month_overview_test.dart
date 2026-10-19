import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/theme/budget_theme.dart';
import 'package:zero_budget/welcome/welcome_providers.dart';
import 'package:zero_budget/welcome/welcome_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Opens the plan for October 2026 on a narrow phone.
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Drift needs real time to run its queries outside the app.
    await tester.runAsync(
      () => db.selectMonth(
        (year: 2026, month: 10),
        calendar: (year: 2026, month: 10),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          todayProvider.overrideWithValue(DateTime(2026, 10, 1)),
        ],
        child: MaterialApp(
          theme: budgetTheme(Brightness.light),
          home: const WelcomeScreen(),
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

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Closes a bottom sheet by tapping above it.
  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
  }

  testWidgets('income is added from its sheet and adds up on the card', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(
      find.text('Start by adding your income for this month.'),
      findsOneWidget,
    );
    expect(find.text('Tap to add your income'), findsOneWidget);

    await tapAndSettle(tester, find.text('Income'));
    expect(find.text('Income this month'), findsOneWidget);
    await tapAndSettle(tester, find.text('Add income'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Job');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '2500',
    );
    await tapAndSettle(tester, find.text('Add'));
    expect(
      find.descendant(of: find.byType(BottomSheet), matching: find.text('Job')),
      findsOneWidget,
    );
    await closeSheet(tester);

    // Left to assign and the income row.
    expect(find.text('2500,00€'), findsNWidgets(2));
    expect(find.text('Job'), findsOneWidget);
    expect(
      find.text('Give this money a job by adding budgets.'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('notes are written in their sheet', (tester) async {
    await pumpScreen(tester);

    await tapAndSettle(tester, find.text('Notes'));
    await tester.enterText(find.byType(TextField), 'Cancel the gym');
    await tapAndSettle(tester, find.text('Save'));

    expect(find.text('Cancel the gym'), findsOneWidget);
    final month = (await tester.runAsync(() => db.getOrCreateMonth(2026, 10)))!;
    expect(month.notes, 'Cancel the gym');
    await unmount(tester);
  });

  testWidgets('a locked in plan shows its income read only', (tester) async {
    await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 10);
      await db.addIncome(month.id, 'Job', 250000);
      await db.addBudget(month.id, 'Rent', 250000, isFixed: true);
      await db.lockMonth(month.id);
    });
    await pumpScreen(tester);

    await tapAndSettle(tester, find.text('Income'));
    expect(
      find.text('Your plan is locked in. Unlock it to change your income.'),
      findsOneWidget,
    );
    expect(find.text('Add income'), findsNothing);
    expect(find.byTooltip('Delete Job'), findsNothing);
    await closeSheet(tester);
    await unmount(tester);
  });
}
