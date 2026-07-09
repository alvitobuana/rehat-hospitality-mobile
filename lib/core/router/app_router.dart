import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/attendance/presentation/main_shell_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/device_binding_screen.dart';
import '../../features/auth/presentation/gps_permission_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/task/presentation/take_photo_screen.dart';
import '../../features/task/presentation/task_detail_screen.dart';

/// Provider Riverpod untuk mengakses instance GoRouter secara global
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/device-binding',
        name: 'device-binding',
        builder: (context, state) => const DeviceBindingScreen(),
      ),
      GoRoute(
        path: '/gps-permission',
        name: 'gps-permission',
        builder: (context, state) => const GpsPermissionScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/task-detail/:id',
        name: 'task-detail',
        builder: (context, state) {
          final idStr = state.pathParameters['id']!;
          final id = int.tryParse(idStr) ?? 0;
          return TaskDetailScreen(taskId: id);
        },
      ),
      GoRoute(
        path: '/take-photo/:id',
        name: 'take-photo',
        builder: (context, state) {
          final idStr = state.pathParameters['id']!;
          final id = int.tryParse(idStr) ?? 0;
          return TakePhotoScreen(taskId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Rute tidak ditemukan: ${state.uri}'),
      ),
    ),
  );
});

/// Halaman Splash Screen Utama yang mendeteksi auto-login session
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Membaca ulang status login saat widget dimasukkan ke tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).checkAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan status otentikasi di splash screen untuk navigasi otomatis
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        context.go('/login');
      } else if (next.status == AuthStatus.deviceBindingRequired) {
        context.go('/device-binding');
      } else if (next.status == AuthStatus.locationPermissionRequired) {
        context.go('/gps-permission');
      } else if (next.status == AuthStatus.authenticated) {
        context.go('/dashboard');
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 32),
            Icon(
              Icons.cleaning_services_rounded,
              size: 56,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rehat Housekeeping',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Menghubungkan ke server hotel...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
