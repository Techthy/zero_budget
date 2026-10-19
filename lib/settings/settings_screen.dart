import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../history/history_screen.dart';
import '../money.dart';
import '../welcome/welcome_providers.dart';
import '../widgets/leaf_background.dart';
import 'buffer_dialog.dart';
import 'settings_providers.dart';

/// Opens the [SettingsScreen].
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LeafBackground(
        child: switch (settings) {
          AsyncData(value: final settings) => _SettingsList(settings: settings),
          AsyncError(:final error) =>
            Center(child: Text('Something went wrong: $error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.settings});

  final Setting settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(appDatabaseProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          children: [
            const _SectionHeader('Appearance'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<Appearance>(
                segments: const [
                  ButtonSegment(
                    value: Appearance.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: Appearance.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: Appearance.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark'),
                  ),
                ],
                selected: {settings.appearance},
                onSelectionChanged: (selected) =>
                    db.setAppearance(selected.single),
              ),
            ),
            const _SectionHeader('Money'),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Buffer'),
              subtitle: Text(
                '${formatCents(settings.bufferCents)} always kept in your '
                'bank account on top of your plan',
              ),
              onTap: () => editBuffer(context, ref, settings.bufferCents),
            ),
            const _SectionHeader('History'),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Past months'),
              subtitle: const Text(
                'Look back at what you planned and spent in earlier months',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
              ),
            ),
            if (kDebugMode) ...[
              const _SectionHeader('Debug'),
              SwitchListTile(
                secondary: const Icon(Icons.bug_report_outlined),
                title: const Text('Show debug bar'),
                subtitle: const Text(
                  'Move through days and months to try things out. Hiding it '
                  'goes back to today.',
                ),
                value: settings.showDebugBar,
                onChanged: (show) {
                  // Don't stay in another day without the bar showing it.
                  if (!show) ref.read(dayOffsetProvider.notifier).reset();
                  db.setShowDebugBar(show);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
