import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/theme/budget_theme.dart';
import 'package:zero_budget/welcome/welcome_screen.dart';

void main() {
  testWidgets('adding income and budgets updates what is left to assign',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    // Tall enough to keep the whole plan on screen.
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: budgetTheme(Brightness.light),
          home: const WelcomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Start by adding your income for this month.'),
        findsOneWidget);

    Future<void> addIncome(String name, String amount) async {
      await tester.tap(find.text('Add income'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), name);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'), amount);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
    }

    await addIncome('Salary', '2500');
    await addIncome('Side job', '500');

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Side job'), findsOneWidget);
    // The total is shown both as income and as left to assign.
    expect(find.text('3000.00'), findsNWidgets(2));

    await tester.tap(find.text('Add budget'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Rent');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'), '3000');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('Every bit of your income has a job.'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Rent'));
    await tester.pumpAndSettle();

    expect(find.text('Rent'), findsNothing);

    await tester.tap(find.byTooltip('Delete Side job'));
    await tester.pumpAndSettle();

    expect(find.text('Side job'), findsNothing);
    expect(find.text('2500.00'), findsNWidgets(3));

    // Dispose the widget tree before closing the database so drift's stream
    // queries shut down cleanly.
    await tester.pumpWidget(const SizedBox());
    await db.close();
    await tester.pumpAndSettle();
  });
}
