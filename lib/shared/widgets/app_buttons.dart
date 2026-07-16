import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_insets.dart';

class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
      backgroundColor: backgroundColor ?? AppColors.primary(context),
      foregroundColor: Colors.white,
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;

  const AppSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
      backgroundColor: backgroundColor ?? Colors.grey.shade300,
      foregroundColor: Colors.black87,
    );
  }
}

class AppDangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  const AppDangerButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      height: height,
      backgroundColor: AppColors.danger(context),
      foregroundColor: Colors.white,
    );
  }
}

class AppOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final ButtonStyle? style;

  const AppOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style ?? OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppInsets.r8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppInsets.s16),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary(context)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: AppInsets.s8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}

class _BaseButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;

  const _BaseButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
    this.icon,
    this.width,
    required this.height,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withAlpha(150),
          disabledForegroundColor: foregroundColor.withAlpha(150),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppInsets.r8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppInsets.s16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: AppInsets.s8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}
