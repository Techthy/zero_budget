import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_budget/data/database.dart';
import 'package:zero_budget/data/database_provider.dart';
import 'package:zero_budget/settings/settings_screen.dart';
import 'package:zero_budget/theme/budget_theme.dart';

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
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: budgetTheme(Brightness.light),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final email = find.text('zero-budget@chammann.dev');
    await tester.scrollUntilVisible(email, 200);
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

    // Unmounts the app while the test still runs, then runs the timers
    // drift starts when its streams close.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.runAsync(db.close);
  });
}
