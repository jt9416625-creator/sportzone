import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores tomados del login. Todo el diseño sale de aquí.
class AppColors {
  static const green = Color(0xFFB7F34A); // verde limón del login
  static const bg = Color(0xFF10131A); // fondo del login
  static const card = Color(0xFF1B202A); // tarjetas / campos del login
  static const border = Color(0xFF303746);
  static const live = Color(0xFFFF3B47);
  static const fire = Color(0xFFFF8A1F);
  static const gold = Color(0xFFFFC83D);

  // Versión clara
  static const lightBg = Color(0xFFF2F4F8);
  static const lightCard = Colors.white;
  static const lightBorder = Color(0xFFDDE1EA);
  static const lightAccent = Color(0xFF4C8A00); // verde legible sobre blanco
}

class AppTheme {
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final base = ThemeData(brightness: b, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: dark ? AppColors.bg : AppColors.lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        brightness: b,
      ).copyWith(
        primary: dark ? AppColors.green : AppColors.lightAccent,
        surface: dark ? AppColors.bg : AppColors.lightBg,
        surfaceTint: Colors.transparent,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? AppColors.card : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.green.withValues(alpha: dark ? 0.2 : 0.35),
      ),
    );
  }
}

/// Atajos para usar los colores según el tema actual.
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardColor2 => isDark ? AppColors.card : AppColors.lightCard;
  Color get borderColor2 => isDark ? AppColors.border : AppColors.lightBorder;
  Color get accent => isDark ? AppColors.green : AppColors.lightAccent;
  Color get muted => isDark ? Colors.white60 : Colors.black54;
}

/// Letra deportiva para marcadores y títulos.
TextStyle display(double size, {Color? color, FontWeight w = FontWeight.w700}) {
  return GoogleFonts.barlowCondensed(
    fontSize: size,
    fontWeight: w,
    color: color,
    letterSpacing: 0.4,
    height: 1.05,
  );
}
