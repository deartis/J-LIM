import 'package:flutter/material.dart';

class JLimTheme {
  // Paleta de cores
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

  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: green,
          secondary: greenDim,
          surface: surface,
          error: red,
        ),
        fontFamily: 'monospace',
        appBarTheme: const AppBarTheme(
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
                letterSpacing: 0.3,
              );
            }
            return const TextStyle(
              color: textSecondary,
              fontSize: 10,
              letterSpacing: 0.3,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: green, size: 22);
            }
            return const IconThemeData(color: textSecondary, size: 22);
          }),
        ),
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
        dividerColor: border,
      );
}

// Cores de status por percentual
Color statusColor(double percent) {
  if (percent < 0.5) return JLimTheme.green;
  if (percent < 0.75) return JLimTheme.amber;
  return JLimTheme.red;
}
