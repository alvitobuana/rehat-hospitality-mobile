import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'auth_controller.dart';

class DeviceBindingScreen extends ConsumerWidget {
  const DeviceBindingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(authControllerProvider.notifier).resetError();
      } else if (next.status == AuthStatus.locationPermissionRequired) {
        context.go('/gps-permission');
      } else if (next.status == AuthStatus.authenticated) {
        context.go('/dashboard');
      } else if (next.status == AuthStatus.unauthenticated) {
        context.go('/login');
      }
    });

    final bool isLoading = authState.status == AuthStatus.authenticating;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Mendaftarkan perangkat...',
      child: AppPage(
        title: 'Validasi Keamanan',
        useSafeArea: true,
        scrollable: true,
        padding: AppInsets.page(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppInsets.s32),
            AppCard(
              child: Column(
                children: [
                  Icon(
                    Icons.phonelink_lock_rounded,
                    size: 64,
                    color: AppColors.primary(context),
                  ),
                  const SizedBox(height: AppInsets.s16),
                  Text(
                    'Device Binding Diperlukan',
                    style: AppTypography.title(context).copyWith(
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppInsets.s12),
                  const Text(
                    'Untuk mencegah kecurangan absensi, ID Karyawan Anda harus didaftarkan secara permanen pada perangkat ponsel ini.',
                    style: TextStyle(height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppInsets.s24),
                  AppPrimaryButton(
                    text: 'IKAT PERANGKAT SEKARANG',
                    isLoading: isLoading,
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).performDeviceBinding();
                    },
                  ),
                  const SizedBox(height: AppInsets.s12),
                  TextButton(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                    },
                    child: const Text(
                      'Batalkan & Keluar Akun',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
