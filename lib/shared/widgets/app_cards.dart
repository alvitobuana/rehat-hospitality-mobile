import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_insets.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppInsets.card,
    this.margin = const EdgeInsets.only(bottom: AppInsets.s12),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppInsets.r8,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidget = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.divider(context),
          width: 1,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

class AppInfoCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const AppInfoCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: backgroundColor,
      borderColor: color.withAlpha(120),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppInsets.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppInsets.s4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppStatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const AppStatCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppInsets.s12, horizontal: AppInsets.s8),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppInsets.s4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class AppEmptyCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AppEmptyCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppInsets.s16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey),
            const SizedBox(height: AppInsets.s8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: AppInsets.s4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;

  const AppGlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppInsets.r8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(AppInsets.r8),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
