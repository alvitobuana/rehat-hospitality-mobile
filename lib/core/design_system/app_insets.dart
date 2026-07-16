import 'package:flutter/material.dart';

class AppInsets {
  // Spacing Constants
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  // Radius Constants
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;

  // Standardized Padding Configurations
  static EdgeInsets page(BuildContext context) {
    return EdgeInsets.only(
      left: s24,
      right: s24,
      top: s24,
      bottom: s24 + MediaQuery.of(context).padding.bottom,
    );
  }

  static const EdgeInsets card = EdgeInsets.all(s16);
  static const EdgeInsets dialog = EdgeInsets.all(s24);
  static const EdgeInsets form = EdgeInsets.all(s20);
  static const EdgeInsets list = EdgeInsets.symmetric(horizontal: s20, vertical: s8);

  static double bottomSafe(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
}
