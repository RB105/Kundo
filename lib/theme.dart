import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Microsoft To Do accent (the "Tasks" blue).
const Color kBlue = Color(0xFF2564CF);

/// Colors a user can pick for their own lists, in the order To Do shows them.
const List<Color> kListThemes = <Color>[
  Color(0xFF2564CF), // blue
  Color(0xFF0F7B0F), // green
  Color(0xFF038387), // teal
  Color(0xFFD13438), // red
  Color(0xFFE3008C), // pink
  Color(0xFF8764B8), // purple
  Color(0xFFCA5010), // orange
  Color(0xFF4C4A48), // graphite
];

/// The list screens use a flat theme color that darkens towards the bottom.
List<Color> gradientOf(Color color) {
  final HSLColor hsl = HSLColor.fromColor(color);
  return <Color>[
    hsl.withLightness((hsl.lightness + 0.04).clamp(0.0, 1.0)).toColor(),
    hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor(),
  ];
}

/// A list color used as a foreground — check circles, stars, chart bars —
/// has to stay readable on the dark cards, so dark mode lifts its lightness.
/// Backgrounds keep the original color.
Color tintFor(Color color, Brightness brightness) {
  if (brightness == Brightness.light) return color;
  final HSLColor hsl = HSLColor.fromColor(color);
  return hsl.lightness >= 0.65 ? color : hsl.withLightness(0.65).toColor();
}

/// The iOS semantic colors the app is drawn with, one set per appearance.
///
/// Values follow UIKit's system colors (systemGroupedBackground, label,
/// separator, …). Screens read them through [AppColors.of] instead of
/// hard-coding a color, so light and dark stay in sync.
@immutable
class AppColors {
  const AppColors._({
    required this.brightness,
    required this.background,
    required this.card,
    required this.bar,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.separator,
    required this.fill,
    required this.pressedOverlay,
    required this.accent,
    required this.danger,
    required this.success,
    required this.purple,
  });

  static const AppColors light = AppColors._(
    brightness: Brightness.light,
    background: Color(0xFFF2F2F7),
    card: Color(0xFFFFFFFF),
    bar: Color(0xF0F9F9F9),
    label: Color(0xFF000000),
    secondaryLabel: Color(0x993C3C43),
    tertiaryLabel: Color(0x4D3C3C43),
    separator: Color(0x4A3C3C43),
    fill: Color(0x1F767680),
    pressedOverlay: Color(0x29000000),
    accent: kBlue,
    danger: Color(0xFFFF3B30),
    success: Color(0xFF34C759),
    purple: Color(0xFFAF52DE),
  );

  static final AppColors dark = AppColors._(
    brightness: Brightness.dark,
    background: const Color(0xFF000000),
    card: const Color(0xFF1C1C1E),
    bar: const Color(0xF01D1D1D),
    label: const Color(0xFFFFFFFF),
    secondaryLabel: const Color(0x99EBEBF5),
    tertiaryLabel: const Color(0x4DEBEBF5),
    separator: const Color(0x99545458),
    fill: const Color(0x3D767680),
    pressedOverlay: const Color(0x21FFFFFF),
    accent: tintFor(kBlue, Brightness.dark),
    danger: const Color(0xFFFF453A),
    success: const Color(0xFF30D158),
    purple: const Color(0xFFBF5AF2),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  final Brightness brightness;

  /// systemGroupedBackground — behind grouped sections.
  final Color background;

  /// secondarySystemGroupedBackground — cards, rows and sheets.
  final Color card;

  /// Translucent navigation bar and toolbar material.
  final Color bar;

  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color separator;

  /// tertiarySystemFill — tracks, placeholders, empty thumbnails.
  final Color fill;

  /// Laid over a row while it is pressed, like a highlighted table cell.
  final Color pressedOverlay;

  final Color accent;
  final Color danger;
  final Color success;
  final Color purple;

  bool get isDark => brightness == Brightness.dark;
}

/// iOS text styles at the default Dynamic Type size. They carry no color, so
/// the ambient [DefaultTextStyle] (the label color) applies unless overridden.
abstract final class IosText {
  static const TextStyle title2 =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.35);
  static const TextStyle title3 =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.38);
  static const TextStyle headline =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41);
  static const TextStyle body = TextStyle(fontSize: 17, letterSpacing: -0.41);
  static const TextStyle subheadline =
      TextStyle(fontSize: 15, letterSpacing: -0.24);
  static const TextStyle footnote = TextStyle(fontSize: 13, letterSpacing: -0.08);
  static const TextStyle caption = TextStyle(fontSize: 12, letterSpacing: 0);
  static const TextStyle caption2 = TextStyle(fontSize: 11, letterSpacing: 0.07);
}

ThemeData buildAppTheme(Brightness brightness) {
  final AppColors colors =
      brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    // iOS look and behavior on every platform: Cupertino page transitions with
    // the back swipe, bouncing scroll, SF fonts and iOS text selection.
    platform: TargetPlatform.iOS,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBlue,
      brightness: brightness,
      primary: colors.accent,
      surface: colors.card,
      error: colors.danger,
    ),
    scaffoldBackgroundColor: colors.background,
    // iOS rows highlight instead of rippling.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(cursorColor: colors.accent),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: colors.accent,
      scaffoldBackgroundColor: colors.background,
      barBackgroundColor: colors.bar,
    ),
  );
}
