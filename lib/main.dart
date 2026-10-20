import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'home_screen.dart';
import 'settings/currency_sync.dart';
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
    return CurrencySync(
      child: MaterialApp(
        title: 'Zero Budget',
        theme: budgetTheme(Brightness.light),
        darkTheme: budgetTheme(Brightness.dark),
        themeMode: switch (appearance) {
          Appearance.system => ThemeMode.system,
          Appearance.light => ThemeMode.light,
          Appearance.dark => ThemeMode.dark,
        },
        home: const HomeScreen(),
      ),
    );
  }
}
