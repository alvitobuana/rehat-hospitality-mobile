import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle heading(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.headlineLarge ?? const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
    );
  }

  static TextStyle title(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleMedium ?? const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle subtitle(BuildContext context) {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
    );
  }

  static TextStyle body(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge ?? const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.normal,
    );
  }

  static TextStyle caption(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium ?? const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.normal,
    );
  }

  static TextStyle label(BuildContext context) {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle error(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppColors.danger(context),
    );
  }

  static TextStyle success(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppColors.success(context),
    );
  }
}
