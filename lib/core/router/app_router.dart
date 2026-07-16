import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/attendance/presentation/main_shell_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/device_binding_screen.dart';
import '../../features/auth/presentation/gps_permission_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/registration_success_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
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
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/registration-success',
        name: 'registration-success',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return RegistrationSuccessScreen(email: email);
        },
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
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Rute tidak ditemukan: ${state.uri}'),
      ),
    ),
  );
});

/// Halaman Splash Screen Utama yang mendeteksi auto-login session dengan Timeout
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timeoutTimer;
  bool _isTimeout = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLogin();
    });
  }

  void _startTimer() {
    _timeoutTimer?.cancel();
    setState(() {
      _isTimeout = false;
      _errorMessage = null;
    });
    // Set batas loading maksimal 5 detik sebelum menampilkan halaman error/timeout
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isTimeout = true;
          _errorMessage = 'Koneksi lambat atau server tidak merespons. Silakan periksa jaringan internet Anda.';
        });
      }
    });
  }

  Future<void> _checkLogin() async {
    try {
      await ref.read(authControllerProvider.notifier).checkAutoLogin();
      _timeoutTimer?.cancel();
    } catch (e) {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _isTimeout = true;
          _errorMessage = 'Terjadi kesalahan saat menghubungkan: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan status otentikasi di splash screen untuk navigasi otomatis
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        _timeoutTimer?.cancel();
        context.go('/login');
      } else if (next.status == AuthStatus.deviceBindingRequired) {
        _timeoutTimer?.cancel();
        context.go('/device-binding');
      } else if (next.status == AuthStatus.locationPermissionRequired) {
        _timeoutTimer?.cancel();
        context.go('/gps-permission');
      } else if (next.status == AuthStatus.authenticated) {
        _timeoutTimer?.cancel();
        context.go('/dashboard');
      }
    });

    if (_isTimeout) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Image.asset(
                  'assets/logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage ?? 'Koneksi ke server hotel terputus.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    _startTimer();
                    _checkLogin();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    _timeoutTimer?.cancel();
                    context.go('/login');
                  },
                  child: const Text('Masuk Secara Manual'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 32),
            Image.asset(
              'assets/logo.png',
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
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

