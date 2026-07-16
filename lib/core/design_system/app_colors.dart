import 'package:flutter/material.dart';

class AppColors {
  // Raw Palette Colors
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color successGreen = Color(0xFF34A853);
  static const Color warningOrange = Color(0xFFFBBC05);
  static const Color dangerRed = Color(0xFFEA4335);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color darkBg = Color(0xFF202124);
  static const Color textDarkGrey = Color(0xFF3C4043);
  static const Color textLightGrey = Color(0xFF80868B);
  static const Color textDarkPrimary = Color(0xFFF1F3F4);
  static const Color textDarkSecondary = Color(0xFFBDC1C6);

  // Semantic Colors mapped dynamically
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color secondary(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color success(BuildContext context) => successGreen;
  static Color warning(BuildContext context) => warningOrange;
  static Color danger(BuildContext context) => dangerRed;
  static Color info(BuildContext context) => primaryBlue;
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color background(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color divider(BuildContext context) => Theme.of(context).brightness == Brightness.light 
      ? const Color(0xFFDADCE0) 
      : const Color(0xFF3C4043);
  static Color text(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  static Color textMuted(BuildContext context) => Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
  static Color chip(BuildContext context) => Theme.of(context).colorScheme.primary.withAlpha(20);
}
