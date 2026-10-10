// Token desain Les Jogoloyo. Anti AI slop: polos, tegas, 1 font, 2 aksen.
// Primer hijau joglo, latar kertas, teks arang. Tanpa gradasi generik.
import 'package:flutter/material.dart';

class JogloColors {
  static const primary = Color(0xFF1B5E20);
  static const primaryDark = Color(0xFF144A18);
  static const paper = Color(0xFFFAF7F0);
  static const card = Colors.white;
  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF6B6B6B);
  static const line = Color(0xFFE8E0D2);
  static const success = Color(0xFF2E7D32);
  static const danger = Color(0xFFC62828);
  static const warning = Color(0xFFEF6C00);
  static const scheduledBg = Color(0xFFE8F0E8);
  static const cancelledBg = Color(0xFFFDECEA);
  static const izinBg = Color(0xFFFFF3E0);
}

class JogloSpacing {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
}

ThemeData jogloTheme() {
  final base = ThemeData(useMaterial3: true, fontFamily: 'Roboto');
  const inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: JogloColors.line),
  );
  return base.copyWith(
    scaffoldBackgroundColor: JogloColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: JogloColors.primary,
      primary: JogloColors.primary,
      surface: JogloColors.paper,
    ),
    textTheme: base.textTheme.copyWith(
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: JogloColors.ink),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: JogloColors.ink),
      bodyMedium: const TextStyle(fontSize: 14, color: JogloColors.ink),
      bodySmall: const TextStyle(fontSize: 12, color: JogloColors.muted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: JogloColors.paper,
      foregroundColor: JogloColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: JogloColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: JogloColors.line),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
    inputDecorationTheme: const InputDecorationTheme(
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: JogloColors.primary, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    dialogTheme: const DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: const DividerThemeData(color: JogloColors.line, thickness: 1),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 8),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: JogloColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: JogloColors.card,
      indicatorColor: JogloColors.scheduledBg,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
