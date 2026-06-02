import 'package:flutter/material.dart';

class JLimTheme {
  // ── DARK ─────────────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0A0C0B);
  static const Color surface = Color(0xFF131815);
  static const Color card = Color(0xFF181E1B);
  static const Color border = Color(0xFF243028);

  static const Color green = Color(0xFF00E87A);
  static const Color greenDim = Color(0xFF00A855);
  static const Color amber = Color(0xFFFFB800);
  static const Color red = Color(0xFFFF3B3B);
  static const Color blue = Color(0xFF3B8BFF);

  static const Color textPrimary = Color(0xFFEDF2F0);
  static const Color textSecondary = Color(0xFF6B8880);
  static const Color textMuted = Color(0xFF354842);

  // ── LIGHT ─────────────────────────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF4F7F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFDDE9E5);

  static const Color textPrimaryLight = Color(0xFF0D1F19);
  static const Color textSecondaryLight = Color(0xFF4A7068);
  static const Color textMutedLight = Color(0xFF8AADA6);

  static ThemeData get theme => _buildTheme(
        bg: bg,
        surface: surface,
        card: card,
        border: border,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        brightness: Brightness.dark,
      );

  static ThemeData get lightTheme => _buildTheme(
        bg: bgLight,
        surface: surfaceLight,
        card: cardLight,
        border: borderLight,
        textPrimary: textPrimaryLight,
        textSecondary: textSecondaryLight,
        textMuted: textMutedLight,
        brightness: Brightness.light,
      );

  static ThemeData _buildTheme({
    required Color bg,
    required Color surface,
    required Color card,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Brightness brightness,
  }) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: green,
        onPrimary: const Color(0xFF0A0C0B),
        secondary: greenDim,
        onSecondary: const Color(0xFF0A0C0B),
        surface: surface,
        onSurface: textPrimary,
        error: red,
        onError: Colors.white,
      ),
      fontFamily: 'monospace',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: green.withValues(alpha: 0.12),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: green,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3);
          }
          return TextStyle(
              color: textSecondary, fontSize: 10, letterSpacing: 0.3);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: green, size: 22);
          }
          return IconThemeData(color: textSecondary, size: 22);
        }),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dividerColor: border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return green;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return green.withValues(alpha: 0.3);
          return border;
        }),
      ),
    );
  }
}

// Cores de status por percentual
Color statusColor(double percent) {
  if (percent < 0.5) return JLimTheme.green;
  if (percent < 0.75) return JLimTheme.amber;
  return JLimTheme.red;
}
