import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../money.dart';
import 'settings_providers.dart';

/// Shows amounts below it in the currency chosen in the settings, and again
/// whenever it's changed there.
class CurrencySync extends ConsumerWidget {
  const CurrencySync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      settingsProvider.select((settings) => settings.value?.currency),
      (_, chosen) {
        if (chosen == null || chosen == currency) return;
        useCurrency(chosen);
        _rebuildAllBelow(context);
      },
    );
    return child;
  }
}

/// Builds everything below [context] again. Amounts are formatted without a
/// context to depend on, so that's how they're shown in a new currency.
void _rebuildAllBelow(BuildContext context) {
  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}
