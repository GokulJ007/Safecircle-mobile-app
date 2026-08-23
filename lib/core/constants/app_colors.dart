import 'package:flutter/material.dart';

/// Centralized color palette for SafeCircle.
/// Trust-oriented primary tones with a distinct SOS/alert accent.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2E5AAC);
  static const Color primaryDark = Color(0xFF1B3A73);
  static const Color secondary = Color(0xFF3FB8AF);

  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color sosRed = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFF5A623);
  static const Color safeGreen = Color(0xFF2ECC71);

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);

  static const List<Color> splashGradient = [
    Color(0xFF1B3A73),
    Color(0xFF2E5AAC),
    Color(0xFF3FB8AF),
  ];
}
