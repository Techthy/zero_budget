import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'home_screen.dart';
import 'money.dart';
import 'settings/settings_providers.dart';
import 'theme/budget_theme.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance =
        ref.watch(settingsProvider).value?.appearance ?? Appearance.system;
    ref.listen(
      settingsProvider.select((settings) => settings.value?.currency),
      (_, chosen) {
        if (chosen == null || chosen == currency) return;
        currency = chosen;
        // Amounts are formatted without a context to depend on, so
        // everything is built again to show them in the new currency.
        void rebuild(Element element) {
          element.markNeedsBuild();
          element.visitChildren(rebuild);
        }

        (context as Element).visitChildren(rebuild);
      },
    );

    return MaterialApp(
      title: 'Zero Budget',
      theme: budgetTheme(Brightness.light),
      darkTheme: budgetTheme(Brightness.dark),
      themeMode: switch (appearance) {
        Appearance.system => ThemeMode.system,
        Appearance.light => ThemeMode.light,
        Appearance.dark => ThemeMode.dark,
      },
      home: const HomeScreen(),
    );
  }
}
