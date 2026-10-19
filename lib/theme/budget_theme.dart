// Budget App design system for Flutter.
// Generated from the design system's tokens.json. Edit the tokens there and regenerate,
// rather than changing values here by hand.
//
// Usage:
//   MaterialApp(
//     theme: budgetTheme(Brightness.light),
//     darkTheme: budgetTheme(Brightness.dark),
//     themeMode: ThemeMode.system,
//   )
//   ...
//   final c = context.budgetColors;   // c.gold, c.soil, c.sproutTint ...
//   final s = context.budgetShadows;  // s.sm, s.md, s.lg, s.coin

import 'package:flutter/material.dart';

/// Every colour token, per theme. Read with `context.budgetColors`.
@immutable
class BudgetColors extends ThemeExtension<BudgetColors> {
  const BudgetColors({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.ink,
    required this.inkMuted,
    required this.forest,
    required this.onForest,
    required this.forestDeep,
    required this.sprout,
    required this.sproutStrong,
    required this.sproutTint,
    required this.onSproutTint,
    required this.highlight,
    required this.onHighlight,
    required this.gold,
    required this.onGold,
    required this.goldDeep,
    required this.soil,
    required this.danger,
  });

  /// Page background. Light value is the logo's cream ground; dark is a deep forest night.
  final Color surface;

  /// Cards, category rows, sheets.
  final Color surfaceRaised;

  /// Inputs, wells, the amount field behind a number being edited.
  final Color surfaceSunken;

  /// Hairlines between rows and around cards.
  final Color border;

  /// Primary text on surface and surface-raised (13.7:1 / 14.7:1).
  final Color ink;

  /// Secondary text, labels, dates (5.3:1 / 7.6:1 on surface).
  final Color inkMuted;

  /// Primary action colour: primary buttons, the + button, the active tab. Dark mode uses a lighter green so buttons stand out from the dark ground. Text on it uses on-forest.
  final Color forest;

  /// Text and icons on forest (6.3:1 / 7.8:1).
  final Color onForest;

  /// Pressed state of forest, links, inflow amounts and other green text on surface (7.4:1 in light).
  final Color forestDeep;

  /// From the logo's leaves. Large fills and illustrations; in light mode it is too pale for thin bars or text (use sprout-strong).
  final Color sprout;

  /// Progress-bar fill toward a category target (3.2:1 on surface-sunken, 3.8:1 on white).
  final Color sproutStrong;

  /// Background of 'funded' badges and goal-reached highlights.
  final Color sproutTint;

  /// Text on sprout-tint (5.5:1 / 8.5:1).
  final Color onSproutTint;

  /// The everyday highlight, from the sunlit edge of the logo's leaves: the Ready to Assign banner, a selected chip, a 'new' dot. Text on it uses on-highlight.
  final Color highlight;

  /// Text and icons on highlight (9.5:1 / 9.6:1).
  final Color onHighlight;

  /// Rare highlight from the coin, for celebrations only: a savings goal reached, every euro assigned for the month. Most screens have none; never more than one. Text on it uses on-gold.
  final Color gold;

  /// Text on gold (8.7:1 / 9.3:1).
  final Color onGold;

  /// From the euro sign. Gold text for the same rare moments, e.g. a 'Goal reached' label (5.5:1 in light).
  final Color goldDeep;

  /// From the soil. Outflow / spending amounts, a calm alternative to red (7.8:1 / 6.4:1).
  final Color soil;

  /// Overspent categories and destructive actions only (5.7:1 / 6.9:1).
  final Color danger;

  static const light = BudgetColors(
    surface: Color(0xFFF8F7F2),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEFEDE4),
    border: Color(0xFFDEDBD0),
    ink: Color(0xFF1E2B24),
    inkMuted: Color(0xFF5B6A61),
    forest: Color(0xFF3B6A4C),
    onForest: Color(0xFFFFFFFF),
    forestDeep: Color(0xFF2E5A3E),
    sprout: Color(0xFF99C547),
    sproutStrong: Color(0xFF5A922A),
    sproutTint: Color(0xFFEAF3C8),
    onSproutTint: Color(0xFF3D6B1F),
    highlight: Color(0xFFBCDC65),
    onHighlight: Color(0xFF1E2B24),
    gold: Color(0xFFF6BF47),
    onGold: Color(0xFF1E2B24),
    goldDeep: Color(0xFF8B5A12),
    soil: Color(0xFF6E441E),
    danger: Color(0xFFA8402A),
  );

  static const dark = BudgetColors(
    surface: Color(0xFF14201A),
    surfaceRaised: Color(0xFF1C2B23),
    surfaceSunken: Color(0xFF0F1813),
    border: Color(0xFF2C3D33),
    ink: Color(0xFFEEF1EA),
    inkMuted: Color(0xFFA3B3A9),
    forest: Color(0xFF7FBF95),
    onForest: Color(0xFF14201A),
    forestDeep: Color(0xFFA6D6B5),
    sprout: Color(0xFFA9D25A),
    sproutStrong: Color(0xFFA9D25A),
    sproutTint: Color(0xFF26381C),
    onSproutTint: Color(0xFFC5DF7A),
    highlight: Color(0xFFA9D25A),
    onHighlight: Color(0xFF14201A),
    gold: Color(0xFFF2B83A),
    onGold: Color(0xFF14201A),
    goldDeep: Color(0xFFE6A94A),
    soil: Color(0xFFC99566),
    danger: Color(0xFFF08A6E),
  );

  @override
  BudgetColors copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? border,
    Color? ink,
    Color? inkMuted,
    Color? forest,
    Color? onForest,
    Color? forestDeep,
    Color? sprout,
    Color? sproutStrong,
    Color? sproutTint,
    Color? onSproutTint,
    Color? highlight,
    Color? onHighlight,
    Color? gold,
    Color? onGold,
    Color? goldDeep,
    Color? soil,
    Color? danger,
  }) {
    return BudgetColors(
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      forest: forest ?? this.forest,
      onForest: onForest ?? this.onForest,
      forestDeep: forestDeep ?? this.forestDeep,
      sprout: sprout ?? this.sprout,
      sproutStrong: sproutStrong ?? this.sproutStrong,
      sproutTint: sproutTint ?? this.sproutTint,
      onSproutTint: onSproutTint ?? this.onSproutTint,
      highlight: highlight ?? this.highlight,
      onHighlight: onHighlight ?? this.onHighlight,
      gold: gold ?? this.gold,
      onGold: onGold ?? this.onGold,
      goldDeep: goldDeep ?? this.goldDeep,
      soil: soil ?? this.soil,
      danger: danger ?? this.danger,
    );
  }

  @override
  BudgetColors lerp(ThemeExtension<BudgetColors>? other, double t) {
    if (other is! BudgetColors) return this;
    return BudgetColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      forest: Color.lerp(forest, other.forest, t)!,
      onForest: Color.lerp(onForest, other.onForest, t)!,
      forestDeep: Color.lerp(forestDeep, other.forestDeep, t)!,
      sprout: Color.lerp(sprout, other.sprout, t)!,
      sproutStrong: Color.lerp(sproutStrong, other.sproutStrong, t)!,
      sproutTint: Color.lerp(sproutTint, other.sproutTint, t)!,
      onSproutTint: Color.lerp(onSproutTint, other.onSproutTint, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      onHighlight: Color.lerp(onHighlight, other.onHighlight, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      goldDeep: Color.lerp(goldDeep, other.goldDeep, t)!,
      soil: Color.lerp(soil, other.soil, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Elevation tokens, per theme. Read with `context.budgetShadows`.
/// Use as `BoxDecoration(boxShadow: context.budgetShadows.sm)`.
@immutable
class BudgetShadows extends ThemeExtension<BudgetShadows> {
  const BudgetShadows({
    required this.sm,
    required this.md,
    required this.lg,
    required this.highlight,
    required this.coin,
  });

  /// Resting cards: category rows, account lists. Pair with the border hairline.
  final List<BoxShadow> sm;

  /// Things that float above the page: the + button, a pressed or dragged card, toasts.
  final List<BoxShadow> md;

  /// Overlays: bottom sheets (Assign money), menus, dialogs.
  final List<BoxShadow> lg;

  /// A soft leaf-green glow under highlight elements, mainly the Ready to Assign banner.
  final List<BoxShadow> highlight;

  /// A warm gold glow from the coin, only for the rare gold celebration moments.
  final List<BoxShadow> coin;

  static const light = BudgetShadows(
    sm: [
      BoxShadow(
        offset: Offset(0.0, 1.0),
        blurRadius: 2.0,
        color: Color(0x0F1E2B24),
      ),
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 6.0,
        color: Color(0x0F1E2B24),
      ),
    ],
    md: [
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 4.0,
        color: Color(0x0F1E2B24),
      ),
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 20.0,
        color: Color(0x1A1E2B24),
      ),
    ],
    lg: [
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 24.0,
        color: Color(0x1F1E2B24),
      ),
      BoxShadow(
        offset: Offset(0.0, 24.0),
        blurRadius: 48.0,
        color: Color(0x1F1E2B24),
      ),
    ],
    highlight: [
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 4.0,
        color: Color(0x1A3B6A4C),
      ),
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 20.0,
        color: Color(0x3D5A922A),
      ),
    ],
    coin: [
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 4.0,
        color: Color(0x1F8B5A12),
      ),
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 20.0,
        color: Color(0x47B87A1D),
      ),
    ],
  );

  static const dark = BudgetShadows(
    sm: [
      BoxShadow(
        offset: Offset(0.0, 1.0),
        blurRadius: 2.0,
        color: Color(0x59000000),
      ),
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 6.0,
        color: Color(0x40000000),
      ),
    ],
    md: [
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 4.0,
        color: Color(0x59000000),
      ),
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 20.0,
        color: Color(0x59000000),
      ),
    ],
    lg: [
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 24.0,
        color: Color(0x73000000),
      ),
      BoxShadow(
        offset: Offset(0.0, 24.0),
        blurRadius: 48.0,
        color: Color(0x66000000),
      ),
    ],
    highlight: [
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 4.0,
        color: Color(0x59000000),
      ),
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 24.0,
        color: Color(0x29A9D25A),
      ),
    ],
    coin: [
      BoxShadow(
        offset: Offset(0.0, 2.0),
        blurRadius: 4.0,
        color: Color(0x59000000),
      ),
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 24.0,
        color: Color(0x2EF2B83A),
      ),
    ],
  );

  @override
  BudgetShadows copyWith({
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    List<BoxShadow>? highlight,
    List<BoxShadow>? coin,
  }) {
    return BudgetShadows(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      highlight: highlight ?? this.highlight,
      coin: coin ?? this.coin,
    );
  }

  @override
  BudgetShadows lerp(ThemeExtension<BudgetShadows>? other, double t) {
    if (other is! BudgetShadows) return this;
    return BudgetShadows(
      sm: BoxShadow.lerpList(sm, other.sm, t)!,
      md: BoxShadow.lerpList(md, other.md, t)!,
      lg: BoxShadow.lerpList(lg, other.lg, t)!,
      highlight: BoxShadow.lerpList(highlight, other.highlight, t)!,
      coin: BoxShadow.lerpList(coin, other.coin, t)!,
    );
  }
}

/// Spacing steps in logical pixels.
class BudgetSpacing {
  BudgetSpacing._();

  /// Icon-to-label gaps.
  static const double space1 = 4.0;

  /// Inside badges, between stacked lines.
  static const double space2 = 8.0;

  /// Card padding, screen gutter.
  static const double space4 = 16.0;

  /// Between sections.
  static const double space8 = 32.0;
}

/// Corner radii.
class BudgetRadius {
  BudgetRadius._();

  /// Badges, inputs.
  static const BorderRadius sm = BorderRadius.all(Radius.circular(6.0));

  /// Cards, buttons.
  static const BorderRadius md = BorderRadius.all(Radius.circular(12.0));

  /// Sheets, the Ready to Assign banner.
  static const BorderRadius lg = BorderRadius.all(Radius.circular(20.0));
}

/// Text styles. Colours come from the theme; apply with `.copyWith(color: ...)` if needed.
/// The system font (San Francisco on iOS, Roboto on Android) is used, as in the design system.
class BudgetText {
  BudgetText._();
  static const TextStyle display = TextStyle(
    fontSize: 32.0,
    height: 1.1875,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle title = TextStyle(
    fontSize: 22.0,
    height: 1.2727,
    fontWeight: FontWeight.w600,
  ); // 650 in the design system; Flutter's nearest named weight
  static const TextStyle heading = TextStyle(
    fontSize: 17.0,
    height: 1.4118,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15.0,
    height: 1.4667,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle amount = TextStyle(
    fontSize: 15.0,
    height: 1.4667,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    height: 1.3333,
    fontWeight: FontWeight.w500,
  );
}

/// The full Material theme. Pass Brightness.light for `theme`, Brightness.dark for `darkTheme`.
ThemeData budgetTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final c = isLight ? BudgetColors.light : BudgetColors.dark;
  final s = isLight ? BudgetShadows.light : BudgetShadows.dark;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.forest,
    onPrimary: c.onForest,
    primaryContainer: c.sproutTint,
    onPrimaryContainer: c.onSproutTint,
    secondary: c.highlight,
    onSecondary: c.onHighlight,
    tertiary: c.forestDeep,
    onTertiary: c.onForest,
    tertiaryContainer: c.sproutTint,
    onTertiaryContainer: c.onSproutTint,
    error: c.danger,
    onError: c.surfaceRaised,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    surfaceContainerLowest: c.surfaceRaised,
    surfaceContainerLow: c.surfaceRaised,
    surfaceContainer: c.surfaceRaised,
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainerHighest: c.surfaceSunken,
    outline: c.inkMuted,
    outlineVariant: c.border,
  );

  final textTheme = TextTheme(
    headlineMedium: BudgetText.display,
    titleLarge: BudgetText.title,
    titleMedium: BudgetText.heading,
    bodyLarge: BudgetText.body,
    bodyMedium: BudgetText.body,
    labelLarge: BudgetText.amount,
    bodySmall: BudgetText.caption,
    labelSmall: BudgetText.caption,
  ).apply(bodyColor: c.ink, displayColor: c.ink);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.surface,
    textTheme: textTheme,
    dividerColor: c.border,
    extensions: <ThemeExtension<dynamic>>[c, s],
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.forest,
        foregroundColor: c.onForest,
        minimumSize: const Size(64, 48),
        shape: const RoundedRectangleBorder(borderRadius: BudgetRadius.md),
        textStyle: BudgetText.heading,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.forest,
      foregroundColor: c.onForest,
      shape: const CircleBorder(),
    ),
  );
}

/// Shortcuts: `context.budgetColors.gold`, `context.budgetShadows.sm`.
extension BudgetThemeContext on BuildContext {
  BudgetColors get budgetColors => Theme.of(this).extension<BudgetColors>()!;
  BudgetShadows get budgetShadows => Theme.of(this).extension<BudgetShadows>()!;
}

/// The design system's card: surface-raised, border hairline, shadow-sm, radius-md, space-4 padding.
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BudgetSpacing.space4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border.all(color: c.border),
        borderRadius: BudgetRadius.md,
        boxShadow: context.budgetShadows.sm,
      ),
      child: child,
    );
  }
}
