import 'package:flutter/material.dart';
import 'app_empty_state.dart';

/// Halaman visual untuk merender Empty State (tidak ada data, tidak ada tugas)
class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const EmptyStateView({
    super.key,
    this.title = 'Tidak Ada Data',
    this.message = 'Belum ada data tersedia di halaman ini.',
    this.icon = Icons.folder_open_outlined,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      message: message,
      icon: icon,
      actionText: actionText,
      onActionPressed: onActionPressed,
    );
  }
}

/// Halaman visual untuk merender Error State (kegagalan server, offline)
class ErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String actionText;
  final VoidCallback onRetryPressed;

  const ErrorStateView({
    super.key,
    this.title = 'Terjadi Gangguan Jaringan',
    this.message = 'Gagal memuat data. Silakan periksa koneksi internet Anda dan coba lagi.',
    this.icon = Icons.wifi_off_rounded,
    this.actionText = 'Coba Lagi',
    required this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: theme.colorScheme.error.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: onRetryPressed,
              icon: const Icon(Icons.refresh),
              label: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay / Dialog visual untuk merender Success State centang hijau berdurasi pendek
class SuccessStateView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;

  const SuccessStateView({
    super.key,
    this.title = 'Berhasil Tersimpan',
    this.message = 'Transaksi data operasional hotel telah berhasil dikirim.',
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFFE6F4EA), // Light Teal
              child: Icon(
                Icons.check_circle_rounded,
                size: 54,
                color: Color(0xFF0E9F7E), // Deep Teal
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onDismiss != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onDismiss,
                child: const Text('Tutup'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
