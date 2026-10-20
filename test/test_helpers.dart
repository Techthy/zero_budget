// Helpers shared by the widget tests.
//
// Drift and fake time: the database runs its queries and stream updates on
// timers. Inside a widget test those only run as fake time passes, while
// queries made from the test itself need real time, so set up the database
// in `tester.runAsync`, let the app's queries finish with [settleQueries],
// and end each test with [unmount] so no timer is left pending.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/month/month_providers.dart';
import 'package:zero_budget/theme/budget_theme.dart';

/// The app's providers around [child], with [db] as the database, [today] as
/// today when it's given, and any other [overrides].
Widget testScope(
  AppDatabase db,
  Widget child, {
  DateTime? today,
  List<Override> overrides = const [],
}) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWithValue(db),
    if (today != null) todayProvider.overrideWithValue(today),
    ...overrides,
  ],
  child: child,
);

/// [home] as the app shows it, see [testScope].
Widget testApp(
  AppDatabase db,
  Widget home, {
  DateTime? today,
  List<Override> overrides = const [],
}) => testScope(
  db,
  MaterialApp(theme: budgetTheme(Brightness.light), home: home),
  today: today,
  overrides: overrides,
);

/// Lets the app's queries finish: watching the database from inside the app
/// needs real time and fake time in turns.
Future<void> settleQueries(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
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

/// Types [amount] into the field labeled [label].
Future<void> enterAmount(WidgetTester tester, String label, String amount) =>
    tester.enterText(find.widgetWithText(TextFormField, label), amount);
