import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import 'attendance_controller.dart';

class DashboardPlaceholderScreen extends ConsumerWidget {
  const DashboardPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final attendanceState = ref.watch(attendanceControllerProvider);
    final theme = Theme.of(context);

    // Listens to logout action and redirect
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        context.go('/login');
      }
    });

    // Listens to attendance error SnackBar
    ref.listen<AttendanceState>(attendanceControllerProvider, (previous, next) {
      if (next.status == AttendanceStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        ref.read(attendanceControllerProvider.notifier).clearError();
      } else if (next.status == AttendanceStatus.incompleteTasksWarning) {
        // Sprint 7.3: Dialog warning jika ada tugas yang belum selesai saat check-out
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Tugas Belum Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Anda masih memiliki tugas yang belum selesai.\n\nTask:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  ...next.incompleteRooms.map((room) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          '• $room',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      )),
                  const SizedBox(height: 16),
                  const Text(
                    'Apakah Anda yakin ingin Check Out?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(attendanceControllerProvider.notifier).cancelCheckOut();
                  },
                  child: const Text('Kembali', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(attendanceControllerProvider.notifier).checkOut(confirmIncomplete: true);
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                  child: const Text('Tetap Check Out'),
                ),
              ],
            );
          },
        );
      }
    });

    final bool isAuthenticating = authState.status == AuthStatus.authenticating;
    final bool isAttendanceLoading = attendanceState.status == AttendanceStatus.loading;
    final bool isActionSuccess = attendanceState.status == AttendanceStatus.success;

    return LoadingOverlay(
      isLoading: isAuthenticating || isAttendanceLoading,
      message: isAuthenticating ? 'Mengeluarkan sesi...' : 'Mencocokkan koordinat GPS...',
      child: AppPage(
        title: 'Rehat Housekeeping',
        leading: const SizedBox.shrink(),
        useSafeArea: true,
        scrollable: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar Akun',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
        padding: const EdgeInsets.all(AppInsets.s24),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Profile Box
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.primaryColor.withAlpha(30),
                        child: Icon(Icons.person, size: 36, color: theme.primaryColor),
                      ),
                      const SizedBox(width: AppInsets.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState.username ?? 'Staf Housekeeping',
                              style: AppTypography.title(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Housekeeping Staff',
                              style: AppTypography.caption(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppInsets.s12),
                
                // Attendance Controller Box
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sesi Absensi Kehadiran',
                        style: AppTypography.title(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppInsets.s16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Status Saat Ini: '),
                          const SizedBox(width: 8),
                          StatusBadge.fromStatusString(
                            attendanceState.status == AttendanceStatus.checkedIn
                                ? 'clean' // Maps to green "Clean"
                                : 'dirty', // Maps to red "Dirty" (Checked Out)
                          ),
                        ],
                      ),
                      const SizedBox(height: AppInsets.s24),
                      
                      if (attendanceState.status == AttendanceStatus.checkedOut ||
                          attendanceState.status == AttendanceStatus.loading ||
                          attendanceState.status == AttendanceStatus.error) ...[
                        AppPrimaryButton(
                          text: 'CHECK IN (MASUK KERJA)',
                          backgroundColor: Colors.green,
                          icon: const Icon(Icons.login_rounded, color: Colors.white),
                          onPressed: () {
                            ref.read(attendanceControllerProvider.notifier).checkIn();
                          },
                        ),
                      ] else if (attendanceState.status == AttendanceStatus.checkedIn) ...[
                        AppDangerButton(
                          text: 'CHECK OUT (PULANG KERJA)',
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                          onPressed: () {
                            ref.read(attendanceControllerProvider.notifier).checkOut();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: AppInsets.s32),
                // Stakeholder simple footer note
                Text(
                  'Rehat Hospitality • Simple, Stable, Fast',
                  style: AppTypography.caption(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            
            // Animasi overlay sukses absensi
            if (isActionSuccess)
              Container(
                color: Colors.black.withAlpha(100),
                alignment: Alignment.center,
                child: SuccessStateView(
                  title: 'Absensi Berhasil',
                  message: attendanceState.lastActionMessage ?? 'Data absensi GPS terkirim.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
