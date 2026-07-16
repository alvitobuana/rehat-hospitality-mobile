import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/session_manager.dart';
import '../../profile/data/profile_repository.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/attendance_card.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/task_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../task/presentation/task_list_controller.dart';
import '../data/attendance_repository.dart';
import 'attendance_controller.dart';
import 'dashboard_controller.dart';

// BUG 3 FIX: Dikonversi ke ConsumerStatefulWidget agar dapat listen
// sessionExpiredNotifier dari DioClient melalui initState/dispose lifecycle.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _checkoutAlertTimer;
  Duration? _serverTimeOffset;
  String? _lastAlertDateStr;

  /// Listener yang dipanggil saat DioClient mendeteksi HTTP 401/403.
  /// Memicu logout otomatis dan redirect ke halaman Login.
  void _onSessionExpired() {
    if (!mounted) return;
    if (sessionExpiredNotifier.value) {
      sessionExpiredNotifier.value = false; // Reset signal
      ref.read(authControllerProvider.notifier).logout();
      context.go('/login');
    }
  }

  Future<void> _syncServerTimeOffset() async {
    try {
      final startTime = DateTime.now();
      final serverTimeStr = await ref.read(attendanceRepositoryProvider).getServerTime();
      if (serverTimeStr != null) {
        final endTime = DateTime.now();
        final latency = endTime.difference(startTime) ~/ 2;
        final serverTime = DateTime.parse(serverTimeStr).add(latency);
        if (mounted) {
          setState(() {
            _serverTimeOffset = serverTime.difference(DateTime.now());
          });
        }
      }
    } catch (e) {
      print('Gagal sinkronisasi waktu server: $e');
    }
  }

  DateTime getEstimateServerTime() {
    final now = DateTime.now();
    if (_serverTimeOffset == null) return now;
    return now.add(_serverTimeOffset!);
  }

  void _startCheckoutAlertTimer() {
    _checkoutAlertTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final attendanceState = ref.read(attendanceControllerProvider);
      if (attendanceState.status != AttendanceStatus.checkedIn) {
        return;
      }
      
      final serverTime = getEstimateServerTime();
      final dateStr = '${serverTime.year}-${serverTime.month}-${serverTime.day}';
      
      // Pukul 17:45 WIB
      if (serverTime.hour == 17 && serverTime.minute >= 45) {
        if (_lastAlertDateStr != dateStr && mounted) {
          _lastAlertDateStr = dateStr;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Jam kerja akan berakhir dalam 15 menit. Jangan lupa melakukan Check Out.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 6),
            ),
          );
        }
      }
    });
  }

  Widget _buildCheckoutWarningBanner() {
    final serverTime = getEstimateServerTime();
    final isAlertWindow = serverTime.hour == 17 && serverTime.minute >= 45;
    final attendanceState = ref.watch(attendanceControllerProvider);
    final isCheckedIn = attendanceState.status == AttendanceStatus.checkedIn;
    
    if (!isCheckedIn || !isAlertWindow) {
      return const SizedBox.shrink();
    }
    
    return AppInfoCard(
      title: 'Mengingatkan Absensi',
      message: 'Jam kerja akan berakhir dalam 15 menit. Jangan lupa melakukan Check Out.',
      icon: Icons.warning_amber_rounded,
      color: Colors.amber.shade800,
      backgroundColor: Colors.amber.shade50,
    );
  }

  @override
  void initState() {
    super.initState();
    // Daftarkan listener ke ValueNotifier global
    sessionExpiredNotifier.addListener(_onSessionExpired);
    // Sinkronisasi waktu server
    _syncServerTimeOffset();
    // Jalankan timer notifikasi jam kerja berakhir
    _startCheckoutAlertTimer();
    // Cek status absensi aktif dari server saat masuk ke beranda
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceControllerProvider.notifier).checkCurrentAttendanceStatus();
    });
  }

  @override
  void dispose() {
    // Cabut listener agar tidak memory leak
    sessionExpiredNotifier.removeListener(_onSessionExpired);
    _checkoutAlertTimer?.cancel();
    super.dispose();
  }


  Widget _buildSummaryPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      backgroundColor: theme.cardTheme.color,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceControllerProvider);
    final sessionAsync = ref.watch(sessionDataProvider);
    final dashboardSummaryAsync = ref.watch(dashboardSummaryProvider);
    final theme = Theme.of(context);

    // Listens to global session expired to redirect to Login
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

    // Listens to dashboard loading/refresh errors
    ref.listen<AsyncValue>(dashboardSummaryProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dashboard: ${next.error}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    final bool isLoading = attendanceState.status == AttendanceStatus.loading;
    final bool isSuccess = attendanceState.status == AttendanceStatus.success;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Mencocokkan koordinat GPS...',
      child: AppPage(
        scrollable: false,
        useSafeArea: true,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(sessionDataProvider);
                await _syncServerTimeOffset();
                // BUG 2 FIX: Refresh task list bersamaan agar Tugas Terdekat sinkron
                await Future.wait([
                  ref.read(dashboardControllerProvider.notifier).refreshSummary(),
                  ref.read(taskListControllerProvider.notifier).refreshActiveTasks(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: AppInsets.s24,
                  right: AppInsets.s24,
                  top: AppInsets.s24,
                  bottom: AppInsets.s24 + AppInsets.bottomSafe(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Greeting dinamis dari secure session
                    sessionAsync.when(
                      data: (session) {
                        final photoPath = session.profilePhoto ?? '';
                        final photoUrl = photoPath.isNotEmpty
                            ? '${ProfileRepository.buildPhotoUrl(photoPath)}?t=${photoPath.hashCode}'
                            : '';
                        return Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/edit-profile'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.primaryColor.withAlpha(100),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: photoUrl.isNotEmpty
                                      ? Image.network(
                                          photoUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => CircleAvatar(
                                            radius: 20,
                                            backgroundColor: theme.primaryColor.withAlpha(40),
                                            child: Icon(Icons.person, color: theme.primaryColor, size: 20),
                                          ),
                                          loadingBuilder: (_, child, progress) {
                                            if (progress == null) return child;
                                            return CircleAvatar(
                                              radius: 20,
                                              backgroundColor: theme.primaryColor.withAlpha(25),
                                              child: const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 1.5),
                                              ),
                                            );
                                          },
                                        )
                                      : CircleAvatar(
                                          radius: 20,
                                          backgroundColor: theme.primaryColor.withAlpha(40),
                                          child: Icon(Icons.person, color: theme.primaryColor, size: 20),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${session.fullName?.isNotEmpty == true ? session.fullName! : (session.username ?? 'Staf')}!',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    (session.hotelName != null && session.hotelName!.isNotEmpty)
                                        ? session.hotelName!
                                        : 'Rehat Hospitality',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, _) => Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.error,
                            child: const Icon(Icons.error_outline, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('Gagal memuat sesi profil'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildCheckoutWarningBanner(),

                    // Widget Absensi GPS Reusable
                    AttendanceCard(
                      status: attendanceState.status,
                      onCheckIn: () {
                        ref.read(attendanceControllerProvider.notifier).checkIn();
                      },
                      onCheckOut: () {
                        ref.read(attendanceControllerProvider.notifier).checkOut();
                      },
                    ),
                    const SizedBox(height: 12),

                    // Summary Counters Box dinamis dari dashboardSummaryProvider
                    const SectionHeader(title: 'Ringkasan Tugas Hari Ini'),
                    dashboardSummaryAsync.when(
                      data: (summary) => Row(
                        children: [
                          Expanded(
                            child: AppStatCard(
                              title: 'Antrean',
                              count: summary.pending.toString(),
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppStatCard(
                              title: 'Dikerjakan',
                              count: summary.inProgress.toString(),
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppStatCard(
                              title: 'Selesai',
                              count: summary.completed.toString(),
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      loading: () => Row(
                        children: [
                          Expanded(child: _buildSummaryPlaceholder(context)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryPlaceholder(context)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryPlaceholder(context)),
                        ],
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Gagal menampilkan ringkasan tugas.',
                            style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Today's Task List
                    const SectionHeader(title: 'Tugas Terdekat'),
                    ref.watch(taskListProvider).when(
                      data: (tasks) {
                        bool hasNoTasksToday = false;
                        dashboardSummaryAsync.whenData((summary) {
                          if (summary.todayTotal == 0) {
                            hasNoTasksToday = true;
                          }
                        });

                        if (tasks.isEmpty) {
                          if (hasNoTasksToday) {
                            return const EmptyStateView(
                              title: 'Tidak ada tugas hari ini',
                              message: 'Silakan menunggu penugasan dari Admin.',
                              icon: Icons.assignment_outlined,
                            );
                          }
                          return const EmptyStateView(
                            title: 'Semua Tugas Selesai',
                            message: 'Selamat! Seluruh tugas kamar Anda hari ini telah diselesaikan.',
                            icon: Icons.check_circle_outline_rounded,
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: tasks.take(3).map((task) {
                            return TaskCard(
                              task: task,
                              onTap: () {
                                context.push('/task-detail/${task.taskId}');
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Gagal memuat tugas terdekat.',
                            style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Success Overlay Animasi
            if (isSuccess)
              Container(
                color: Colors.black.withAlpha(100),
                alignment: Alignment.center,
                child: SuccessStateView(
                  title: 'Absensi Berhasil',
                  message: attendanceState.lastActionMessage ?? 'Data absensi GPS terverifikasi.',
                ),
              ),
          ],
        ),
      ),
    );
  }


}
