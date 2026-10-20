import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/planning/left_to_assign.dart';
import 'package:zero_budget/theme/budget_theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget banner) => tester.pumpWidget(
    MaterialApp(
      theme: budgetTheme(Brightness.light),
      home: Scaffold(body: banner),
    ),
  );

  testWidgets('the banner says what to do next', (tester) async {
    Future<void> expectBanner(
      int leftCents,
      int assignableCents,
      String title,
      String message,
    ) async {
      await pump(
        tester,
        LeftToAssign(leftCents: leftCents, assignableCents: assignableCents),
      );
      expect(find.text(title), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    }

    await expectBanner(
      0,
      0,
      'Left to assign',
      'Start by adding your income for this month.',
    );
    await expectBanner(0, 300000, 'Left to assign', 'Every euro has a job.');
    await expectBanner(
      5000,
      300000,
      'Left to assign',
      'Give this money a job by adding budgets.',
    );
    await expectBanner(
      -5000,
      300000,
      'Over-assigned',
      "You've assigned more than you have this month.",
    );
    // Over shows how much over, without a minus.
    expect(find.text('50,00€'), findsOneWidget);
  });

  testWidgets('the compact banner says it in one line', (tester) async {
    Future<void> expectLine(int leftCents, int assignableCents, String line) =>
        pump(
          tester,
          LeftToAssign.compact(
            leftCents: leftCents,
            assignableCents: assignableCents,
          ),
        ).then((_) => expect(find.text(line), findsOneWidget));

    // Nothing to assign yet isn't every euro having a job.
    await expectLine(0, 0, 'Left to assign');
    await expectLine(0, 300000, 'Every euro has a job.');
    await expectLine(5000, 300000, 'Left to assign');
    await expectLine(-5000, 300000, 'Over-assigned');
  });
}
