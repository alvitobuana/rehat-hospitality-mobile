import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/location/location_service.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'auth_controller.dart';

/// Tampilan state permission yang sedang ditampilkan.
enum _PermissionView {
  /// Layar penjelasan (rationale) — tampil pertama kali
  rationale,
  /// User menolak permission (masih bisa coba lagi)
  denied,
  /// User memilih Don't Ask Again — arahkan ke App Settings
  permanentlyDenied,
  /// GPS service perangkat mati
  gpsDisabled,
}

/// Layar permission lokasi GPS dengan alur UX yang lengkap.
///
/// Flow:
/// 1. Tampilkan rationale → Tombol "Izinkan Lokasi"
/// 2. Jika ditolak → tampilkan pesan + Tombol "Coba Lagi"
/// 3. Jika ditolak permanen → tampilkan dialog + Tombol "Buka Pengaturan"
/// 4. Jika GPS mati → tampilkan dialog + Tombol "Aktifkan GPS"
class GpsPermissionScreen extends ConsumerStatefulWidget {
  const GpsPermissionScreen({super.key});

  @override
  ConsumerState<GpsPermissionScreen> createState() => _GpsPermissionScreenState();
}

class _GpsPermissionScreenState extends ConsumerState<GpsPermissionScreen> {
  _PermissionView _currentView = _PermissionView.rationale;

  @override
  void initState() {
    super.initState();
    // Tentukan view awal berdasarkan error code yang dikirim AuthController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncViewWithAuthState();
    });
  }

  /// Menyesuaikan tampilan awal dengan error code dari AuthController
  void _syncViewWithAuthState() {
    final authState = ref.read(authControllerProvider);
    final code = authState.errorMessage ?? '';
    setState(() {
      _currentView = _mapErrorCodeToView(code);
    });
  }

  _PermissionView _mapErrorCodeToView(String code) {
    switch (code) {
      case 'GPS_SERVICE_DISABLED':
        return _PermissionView.gpsDisabled;
      case 'PERMISSION_PERMANENTLY_DENIED':
        return _PermissionView.permanentlyDenied;
      case 'PERMISSION_DENIED':
        return _PermissionView.denied;
      default:
        return _PermissionView.rationale;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isLoading = authState.status == AuthStatus.authenticating;

    // Redirect ke dashboard jika permission berhasil diberikan
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/dashboard');
      } else if (next.status == AuthStatus.unauthenticated) {
        context.go('/login');
      } else if (next.status == AuthStatus.locationPermissionRequired) {
        // Update view berdasarkan error code terbaru dari controller
        final code = next.errorMessage ?? '';
        setState(() {
          _currentView = _mapErrorCodeToView(code);
        });
      }
    });

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Memeriksa izin lokasi...',
      child: AppPage(
        title: 'Izin Lokasi',
        useSafeArea: true,
        scrollable: true,
        padding: AppInsets.page(context),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentView(theme, isLoading),
        ),
      ),
    );
  }

  Widget _buildCurrentView(ThemeData theme, bool isLoading) {
    switch (_currentView) {
      case _PermissionView.rationale:
        return _buildRationaleView(theme, isLoading);
      case _PermissionView.denied:
        return _buildDeniedView(theme, isLoading);
      case _PermissionView.permanentlyDenied:
        return _buildPermanentlyDeniedView(theme);
      case _PermissionView.gpsDisabled:
        return _buildGpsDisabledView(theme);
    }
  }

  // ---------------------------------------------------------------------------
  // View 1: Rationale — Penjelasan sebelum meminta permission
  // ---------------------------------------------------------------------------
  Widget _buildRationaleView(ThemeData theme, bool isLoading) {
    return _PermissionCard(
      key: const ValueKey('rationale'),
      icon: Icons.location_on_rounded,
      iconColor: theme.colorScheme.primary,
      title: 'Akses Lokasi Diperlukan',
      description:
          'Aplikasi membutuhkan akses lokasi agar dapat melakukan Check In dan Check Out '
          'sesuai lokasi hotel.\n\n'
          'Lokasi Anda hanya digunakan saat absensi dan tidak disimpan di luar keperluan tersebut.',
      actions: [
        AppPrimaryButton(
          text: 'IZINKAN LOKASI',
          isLoading: isLoading,
          onPressed: () => ref.read(authControllerProvider.notifier).checkGpsPermission(),
        ),
        const SizedBox(height: AppInsets.s12),
        _buildCancelButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // View 2: Denied — User menolak, masih bisa coba lagi
  // ---------------------------------------------------------------------------
  Widget _buildDeniedView(ThemeData theme, bool isLoading) {
    return _PermissionCard(
      key: const ValueKey('denied'),
      icon: Icons.location_off_rounded,
      iconColor: Colors.orange,
      title: 'Akses Lokasi Ditolak',
      description:
          'Akses lokasi diperlukan untuk menggunakan fitur absensi.\n\n'
          'Silakan izinkan akses lokasi agar dapat melakukan Check In dan Check Out.',
      actions: [
        AppPrimaryButton(
          text: 'COBA LAGI',
          isLoading: isLoading,
          onPressed: () => ref.read(authControllerProvider.notifier).checkGpsPermission(),
        ),
        const SizedBox(height: AppInsets.s12),
        _buildCancelButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // View 3: Permanently Denied — Arahkan ke App Settings
  // ---------------------------------------------------------------------------
  Widget _buildPermanentlyDeniedView(ThemeData theme) {
    return _PermissionCard(
      key: const ValueKey('permanently_denied'),
      icon: Icons.lock_outline_rounded,
      iconColor: theme.colorScheme.error,
      title: 'Akses Lokasi Ditolak Permanen',
      description:
          'Akses lokasi telah ditolak secara permanen. Untuk menggunakan fitur absensi, '
          'Anda perlu mengaktifkan izin lokasi secara manual melalui pengaturan aplikasi.',
      actions: [
        AppPrimaryButton(
          text: 'BUKA PENGATURAN',
          onPressed: () async {
            await ref.read(locationServiceProvider).openAppSettings();
            // Setelah kembali dari settings, cek ulang status
            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 500));
              ref.read(authControllerProvider.notifier).checkGpsPermission();
            }
          },
        ),
        const SizedBox(height: AppInsets.s12),
        _buildCancelButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // View 4: GPS Disabled — GPS service perangkat mati
  // ---------------------------------------------------------------------------
  Widget _buildGpsDisabledView(ThemeData theme) {
    return _PermissionCard(
      key: const ValueKey('gps_disabled'),
      icon: Icons.gps_off_rounded,
      iconColor: Colors.amber.shade700,
      title: 'GPS Belum Aktif',
      description:
          'Layanan GPS perangkat Anda tidak aktif. Aktifkan GPS untuk dapat '
          'melakukan absensi berdasarkan lokasi hotel.',
      actions: [
        AppPrimaryButton(
          text: 'AKTIFKAN GPS',
          onPressed: () async {
            await ref.read(locationServiceProvider).openLocationSettings();
            // Setelah kembali dari settings, cek ulang status GPS
            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 500));
              ref.read(authControllerProvider.notifier).checkGpsPermission();
            }
          },
        ),
        const SizedBox(height: AppInsets.s12),
        _buildCancelButton(),
      ],
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () => ref.read(authControllerProvider.notifier).logout(),
      child: const Text(
        'Batalkan & Keluar Akun',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI component — Permission Card
// ---------------------------------------------------------------------------

/// Kartu UI yang konsisten untuk semua state permission.
class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<Widget> actions;

  const _PermissionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 72, color: iconColor),
                  const SizedBox(height: AppInsets.s20),
                  Text(
                    title,
                    style: AppTypography.title(context).copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppInsets.s12),
                  Text(
                    description,
                    style: AppTypography.body(context).copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppInsets.s24),
                  ...actions,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
