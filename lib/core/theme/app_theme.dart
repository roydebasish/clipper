import 'package:flutter/material.dart';

class AppTheme {
  // macOS Accent Palette
  static const Color macBlue = Color(0xFF007AFF);
  static const Color macGreen = Color(0xFF34C759);
  static const Color macAmber = Color(0xFFFF9500);
  static const Color macRed = Color(0xFFFF3B30);
  static const Color macPurple = Color(0xFFAF52DE);
  static const Color macTeal = Color(0xFF5AC8FA);
  static const Color macIndigo = Color(0xFF5856D6);

  // Light Palette (macOS Tahoe / Sonoma Style)
  static const Color lightBg = Color(0xFFF6F7F9);
  static const Color lightSidebarBg = Color(0xFFECEEF2);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF3F5F9);
  static const Color lightCardSelected = Color(0xFFE8F1FC);
  static const Color lightBorder = Color(0xFFE1E4EA);
  static const Color lightTextPrimary = Color(0xFF1D2129);
  static const Color lightTextSecondary = Color(0xFF6E7687);
  static const Color lightTextMuted = Color(0xFF9AA0AE);

  // Dark Palette (macOS Graphite Style)
  static const Color darkBg = Color(0xFF141518);
  static const Color darkSidebarBg = Color(0xFF1C1E23);
  static const Color darkCardBg = Color(0xFF23262D);
  static const Color darkCardHover = Color(0xFF2C3039);
  static const Color darkCardSelected = Color(0xFF1B3152);
  static const Color darkBorder = Color(0xFF2F343F);
  static const Color darkTextPrimary = Color(0xFFF0F3F8);
  static const Color darkTextSecondary = Color(0xFF969DAE);
  static const Color darkTextMuted = Color(0xFF646B7B);

  // Dynamic Context Helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) => isDark(context) ? darkBg : lightBg;
  static Color sidebarBg(BuildContext context) => isDark(context) ? darkSidebarBg : lightSidebarBg;
  static Color cardBg(BuildContext context) => isDark(context) ? darkCardBg : lightCardBg;
  static Color cardHover(BuildContext context) => isDark(context) ? darkCardHover : lightCardHover;
  static Color cardSelected(BuildContext context) => isDark(context) ? darkCardSelected : lightCardSelected;
  static Color border(BuildContext context) => isDark(context) ? darkBorder : lightBorder;
  static Color textPrimary(BuildContext context) => isDark(context) ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(BuildContext context) => isDark(context) ? darkTextSecondary : lightTextSecondary;
  static Color textMuted(BuildContext context) => isDark(context) ? darkTextMuted : lightTextMuted;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: macBlue,
      colorScheme: const ColorScheme.light(
        primary: macBlue,
        secondary: macBlue,
        surface: lightCardBg,
        error: macRed,
      ),
      fontFamily: '.AppleSystemUIFont',
      cardTheme: CardThemeData(
        color: lightCardBg,
        elevation: 0.5,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: lightBorder, width: 0.9),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: macBlue,
        selectionColor: Color(0x66007AFF),
        selectionHandleColor: macBlue,
      ),
      dividerColor: lightBorder,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: macBlue,
      colorScheme: const ColorScheme.dark(
        primary: macBlue,
        secondary: macBlue,
        surface: darkCardBg,
        error: macRed,
      ),
      fontFamily: '.AppleSystemUIFont',
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: macBlue,
        selectionColor: Color(0x66007AFF),
        selectionHandleColor: macBlue,
      ),
      cardTheme: CardThemeData(
        color: darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: darkBorder, width: 0.8),
        ),
      ),
      dividerColor: darkBorder,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D35),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: darkBorder),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
