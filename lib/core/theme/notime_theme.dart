import 'package:flutter/material.dart';

/// NotiMe brand colors aligned with heynotime.com marketing.
abstract final class NotiMeColors {
  static const primary = Color(0xFF5B4FE8);
  static const primaryDark = Color(0xFF4338CA);
  static const accent = Color(0xFF22C55E);
  static const background = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const expired = Color(0xFF94A3B8);
  static const expiredBg = Color(0xFFE2E8F0);
  static const danger = Color(0xFFDC2626);
  static const border = Color(0xFFE2E8F0);
  static const menuPrimary = Color(0xFF1A2036);
}

ThemeData buildNotiMeTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NotiMeColors.primary,
      primary: NotiMeColors.primary,
      surface: NotiMeColors.surface,
    ),
    scaffoldBackgroundColor: NotiMeColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: NotiMeColors.surface,
      foregroundColor: NotiMeColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: NotiMeColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: NotiMeColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NotiMeColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    fontFamily: 'Roboto',
  );
  return base;
}
