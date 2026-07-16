import 'package:flutter/material.dart';
import '../../core/design_system/app_insets.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const AppEmptyState({
    super.key,
    this.title = 'Tidak Ada Data',
    this.message = 'Belum ada data tersedia di halaman ini.',
    this.icon = Icons.folder_open_outlined,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppInsets.s24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
            ),
            const SizedBox(height: AppInsets.s16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppInsets.s8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: AppInsets.s24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
