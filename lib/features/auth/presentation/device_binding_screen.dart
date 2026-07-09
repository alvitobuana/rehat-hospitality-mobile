import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_button.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Validasi Keamanan'),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.phonelink_lock_rounded,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Device Binding Diperlukan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Untuk mencegah kecurangan absensi, ID Karyawan Anda harus didaftarkan secara permanen pada perangkat ponsel ini.',
                        style: TextStyle(height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'IKAT PERANGKAT SEKARANG',
                        isLoading: isLoading,
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).performDeviceBinding();
                        },
                      ),
                      const SizedBox(height: 12),
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
        ),
      ),
    );
  }
}
