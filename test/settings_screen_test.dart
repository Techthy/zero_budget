import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/money.dart';
import 'package:zero_budget/settings/settings_providers.dart';
import 'package:zero_budget/settings/settings_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('the about section says who wrote it and copies contacts', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    await tester.pumpWidget(
      testApp(
        db,
        const SettingsScreen(),
        overrides: [
          appVersionProvider.overrideWith((ref) async => '1.2.0-nightly.57'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final version = find.text('1.2.0-nightly.57');
    await tester.scrollUntilVisible(version, 200);
    await tester.ensureVisible(version);
    await tester.pumpAndSettle();
    await tester.tap(version);
    await tester.pumpAndSettle();
    expect(copied, '1.2.0-nightly.57');

    final email = find.text('zero-budget@chammann.dev');
    await tester.scrollUntilVisible(email, -200);
    await tester.ensureVisible(email);
    await tester.pumpAndSettle();
    expect(find.textContaining('Written by C. Hammann'), findsOneWidget);
    expect(find.textContaining('highly vibe coded'), findsOneWidget);
    expect(
      find.text('https://github.com/Techthy/zero_budget/issues'),
      findsOneWidget,
    );

    await tester.tap(email);
    await tester.pumpAndSettle();
    expect(copied, 'zero-budget@chammann.dev');
    expect(find.text('Copied zero-budget@chammann.dev'), findsOneWidget);

    // Amounts are in euros until another currency is chosen.
    final currency = find.text('Euro, like 1234,50€');
    await tester.scrollUntilVisible(currency, -200);
    await tester.tap(currency);
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'US Dollar ($)'));
    await tester.pumpAndSettle();
    final settings = (await tester.runAsync(() => db.watchSettings().first))!;
    expect(settings.currency, Currency.usd);

    // Unmounts the app while the test still runs, then runs the timers
    // drift starts when its streams close.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.runAsync(db.close);
  });
}
