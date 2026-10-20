import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../history/history_screen.dart';
import '../money.dart';
import '../month/month_providers.dart';
import '../widgets/async_view.dart';
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
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LeafBackground(
        child: AsyncView(
          value: ref.watch(settingsProvider),
          data: (settings) => _SettingsList(settings: settings),
        ),
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
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Currency'),
              subtitle: Text(
                '${settings.currency.label}, like '
                '${formatCents(123450)}',
              ),
              onTap: () => _chooseCurrency(context, ref, settings.currency),
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
            const _SectionHeader('About'),
            const _About(),
          ],
        ),
      ),
    );
  }
}

/// Asks which currency to show amounts in, starting from [current].
Future<void> _chooseCurrency(
  BuildContext context,
  WidgetRef ref,
  Currency current,
) async {
  final chosen = await showDialog<Currency>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Currency'),
      children: [
        for (final currency in Currency.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(currency),
            child: Row(
              children: [
                Expanded(child: Text('${currency.label} (${currency.symbol})')),
                if (currency == current) const Icon(Icons.check),
              ],
            ),
          ),
      ],
    ),
  );
  if (chosen != null) await ref.read(appDatabaseProvider).setCurrency(chosen);
}

/// What the app is, who wrote it, its version, and where to report issues.
class _About extends ConsumerWidget {
  const _About();

  static const issuesUrl = 'https://github.com/Techthy/zero_budget/issues';
  static const email = 'zero-budget@chammann.dev';

  /// The app can't open links, so a tap copies them instead.
  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Copied $text')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Zero Budget helps you plan every ${currency.unitName} of your '
            'month before you spend it, instead of tracking where your money '
            "went after it's gone.\n\n"
            'Written by C. Hammann. The app is highly vibe coded, so expect a '
            'rough edge here and there, and please report anything that '
            "doesn't work as it should.",
          ),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Report an issue on GitHub'),
          subtitle: const Text(issuesUrl),
          trailing: const Icon(Icons.copy_outlined),
          onTap: () => _copy(context, issuesUrl),
        ),
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: const Text('Or send an email'),
          subtitle: const Text(email),
          trailing: const Icon(Icons.copy_outlined),
          onTap: () => _copy(context, email),
        ),
        // Copied for an issue report, to say which build it's about.
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: Text(version ?? ''),
          trailing: const Icon(Icons.copy_outlined),
          onTap: version == null ? null : () => _copy(context, version),
        ),
        const SizedBox(height: 16),
      ],
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
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
