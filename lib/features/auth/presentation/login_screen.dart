import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    // Menangani snakbar jika status error terpicu
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(authControllerProvider.notifier).resetError();
      } else if (next.status == AuthStatus.deviceBindingRequired) {
        context.go('/device-binding');
      } else if (next.status == AuthStatus.locationPermissionRequired) {
        context.go('/gps-permission');
      } else if (next.status == AuthStatus.authenticated) {
        context.go('/dashboard');
      }
    });

    final bool isLoading = authState.status == AuthStatus.authenticating;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Mengecek keamanan...',
      child: AppPage(
        useSafeArea: true,
        scrollable: true,
        padding: AppInsets.page(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppInsets.s32),
              // Brand Logo
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 54,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppInsets.s24),
              Text(
                'Rehat Housekeeping',
                style: AppTypography.heading(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppInsets.s8),
              Text(
                'Aplikasi Operasional Staf Kamar',
                style: AppTypography.caption(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppInsets.s32),
              
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masuk Sesi Kerja',
                      style: AppTypography.title(context),
                    ),
                    const SizedBox(height: AppInsets.s16),
                    AppTextField(
                      controller: _usernameController,
                      labelText: 'Username / Email / ID Karyawan',
                      hintText: 'Username, email, atau ID karyawan...',
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Username / Email / ID Karyawan wajib diisi';
                        }
                        return null;
                      },
                    ),
                    AppTextField(
                      controller: _passwordController,
                      labelText: 'Kata Sandi',
                      hintText: 'Masukkan password...',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Kata sandi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppInsets.s8),
                    AppPrimaryButton(
                      text: 'LOG IN',
                      isLoading: isLoading,
                      onPressed: _onLoginPressed,
                    ),
                    const SizedBox(height: AppInsets.s16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(
                          'Belum punya akun? Daftar sekarang',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
