import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/theme/budget_theme.dart';
import 'package:zero_budget/planning/planning_providers.dart';
import 'package:zero_budget/planning/planning_screen.dart';

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
          home: const PlanningScreen(),
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

  /// Lets the app's queries finish: writing from inside the app and
  /// watching the database needs real time and fake time in turns.
  Future<void> settleQueries(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();
  }

  /// Adds a September plan, which October is copied from.
  Future<void> planSeptember(WidgetTester tester) => tester.runAsync(() async {
    final september = await db.getOrCreateMonth(2026, 9);
    await db.addIncome(september.id, 'Job', 250000);
    await db.addBudget(september.id, 'Rent', 90000, isFixed: true);
    await db.addBudget(september.id, 'Gym', 3000);
  });

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// The button that locks or unlocks the plan, labeled or, when the title
  /// leaves no room, just a lock with [label] as its tooltip.
  Finder lockButton(String label) => find.byWidgetPredicate(
    (widget) =>
        (widget is Text && widget.data == label) ||
        (widget is Tooltip && widget.message == label),
  );

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

    // Once there are notes, they open to read; the pen edits them.
    await tapAndSettle(tester, find.text('Cancel the gym'));
    expect(find.byType(TextField), findsNothing);
    await tapAndSettle(tester, find.byTooltip('Edit notes'));
    await tester.enterText(find.byType(TextField), 'Cancel the gym today');
    // Cancelling goes back to reading the notes as they were.
    await tapAndSettle(tester, find.text('Cancel'));
    expect(find.byType(TextField), findsNothing);
    await tapAndSettle(tester, find.byTooltip('Edit notes'));
    await tester.enterText(find.byType(TextField), 'Cancel the gym today');
    await tapAndSettle(tester, find.text('Save'));
    expect(find.text('Cancel the gym today'), findsOneWidget);
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

  testWidgets('locking in from the top says what is in the way', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tapAndSettle(tester, lockButton('Lock'));
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Add your income and budgets before locking in.'),
      ),
      findsOneWidget,
    );
    final month = (await tester.runAsync(() => db.getOrCreateMonth(2026, 10)))!;
    expect(month.lockedAt, isNull);
    await unmount(tester);
  });

  testWidgets('the plan locks and unlocks from the top without asking', (
    tester,
  ) async {
    // Drift needs real time to run its queries outside the app, and writes
    // from here would wait on the app's streams, so set up first.
    await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 10);
      await db.addIncome(month.id, 'Job', 250000);
      await db.addBudget(month.id, 'Rent', 250000, isFixed: true);
    });
    await pumpScreen(tester);

    await tapAndSettle(tester, lockButton('Lock'));
    expect(lockButton('Edit plan'), findsOneWidget);
    // The long title leaves no room on a narrow phone: just the lock shows.
    expect(find.text('Edit plan'), findsNothing);
    expect(lockButton('Lock'), findsNothing);

    await tapAndSettle(tester, lockButton('Edit plan'));
    expect(find.byType(AlertDialog), findsNothing);
    expect(lockButton('Lock'), findsOneWidget);
    final month = (await tester.runAsync(() => db.getOrCreateMonth(2026, 10)))!;
    expect(month.lockedAt, isNull);
    await unmount(tester);
  });

  testWidgets('the step by step card explains how it works', (tester) async {
    await pumpScreen(tester);

    await tapAndSettle(tester, find.byTooltip('How it works'));
    expect(find.text('How step by step works'), findsOneWidget);
    expect(find.text('Where you start'), findsOneWidget);
    // Further down, the sheet scrolls.
    await tester.scrollUntilVisible(
      find.text('Pay yourself'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Pay yourself'), findsOneWidget);
    await closeSheet(tester);
    expect(find.text('How step by step works'), findsNothing);
    await unmount(tester);
  });

  testWidgets('left to assign explains zero-based budgeting', (tester) async {
    await pumpScreen(tester);

    await tapAndSettle(tester, find.byTooltip('How a zero-based budget works'));
    expect(find.text('How a zero-based budget works'), findsOneWidget);
    expect(find.text('Income + carried over − budgets = 0'), findsOneWidget);
    await closeSheet(tester);
    expect(find.text('Every euro gets a job'), findsNothing);
    await unmount(tester);
  });

  testWidgets('long pressing a budget on the plan moves it', (tester) async {
    await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 10);
      await db.addIncome(month.id, 'Job', 250000);
      await db.addBudget(
        month.id,
        'Rent',
        90000,
        isFixed: true,
        category: BudgetCategory.essential,
      );
      await db.addBudget(month.id, 'Fun', 10000);
      await db.addBudget(
        month.id,
        'Giving',
        5000,
        category: BudgetCategory.giving,
      );
    });
    await pumpScreen(tester);
    // Tall enough to show every budget at once.
    tester.view.physicalSize = const Size(360, 3000);
    await tester.pumpAndSettle();

    List<String> listed() {
      final names = ['Rent', 'Fun', 'Giving'];
      return names..sort(
        (a, b) => tester
            .getTopLeft(find.text(a).last)
            .dy
            .compareTo(tester.getTopLeft(find.text(b).last).dy),
      );
    }

    expect(listed(), ['Giving', 'Rent', 'Fun']);

    // Fun goes to the top.
    final start = tester.getCenter(find.text('Fun').last);
    final top = tester.getTopLeft(find.text('Giving').last).dy - 40;
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(
        Offset(start.dx, start.dy + (top - start.dy) * i / 10),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(listed(), ['Fun', 'Giving', 'Rent']);
    // Moving it didn't open it for editing.
    expect(find.byType(AlertDialog), findsNothing);
    final settings = (await tester.runAsync(() => db.watchSettings().first))!;
    expect(settings.budgetOrder, BudgetOrder.custom);
    await unmount(tester);
  });

  testWidgets('a copied month first asks which budgets to keep', (
    tester,
  ) async {
    await planSeptember(tester);
    await pumpScreen(tester);

    expect(find.text('Set up October 2026'), findsOneWidget);
    expect(find.text('Keeping 2 of 2 budgets'), findsOneWidget);
    await tapAndSettle(tester, find.text('Gym'));
    expect(find.text('Keeping 1 of 2 budgets'), findsOneWidget);

    await tester.tap(find.text('Go to my plan'));
    await settleQueries(tester);
    expect(find.text('Set up October 2026'), findsNothing);
    // The plan, with its card to plan step by step. It's not empty, so
    // it doesn't greet a new user.
    expect(find.text('Plan step by step'), findsOneWidget);
    expect(find.text('Plan your month'), findsOneWidget);
    final (month, budgets) = (await tester.runAsync(() async {
      final month = await db.getOrCreateMonth(2026, 10);
      return (month, await db.watchBudgets(month.id).first);
    }))!;
    expect(month.needsSetUp, isFalse);
    expect(budgets.map((b) => b.name), ['Rent']);
    await unmount(tester);
  });

  testWidgets('setting up a month can go on step by step', (tester) async {
    await planSeptember(tester);
    await pumpScreen(tester);

    await tester.tap(find.text('Plan step by step'));
    await settleQueries(tester);
    expect(find.text('Step 1 of 5'), findsOneWidget);
    await unmount(tester);
  });
}
