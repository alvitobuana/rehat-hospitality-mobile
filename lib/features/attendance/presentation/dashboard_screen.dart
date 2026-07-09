import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/session_manager.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/attendance_card.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/task_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../task/presentation/task_list_controller.dart';
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

  @override
  void initState() {
    super.initState();
    // Daftarkan listener ke ValueNotifier global
    sessionExpiredNotifier.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    // Cabut listener agar tidak memory leak
    sessionExpiredNotifier.removeListener(_onSessionExpired);
    super.dispose();
  }

  String _getHotelName(String? username, String? level) {
    if (username == 'hk_dago' || level == 'Housekeeping') {
      return 'Dago Sky';
    }
    return 'Rehat Hospitality';
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
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(sessionDataProvider);
                  // BUG 2 FIX: Refresh task list bersamaan agar Tugas Terdekat sinkron
                  await Future.wait([
                    ref.read(dashboardControllerProvider.notifier).refreshSummary(),
                    ref.read(taskListControllerProvider.notifier).refreshActiveTasks(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Greeting dinamis dari secure session
                      sessionAsync.when(
                        data: (session) => Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.primaryColor,
                              child: const Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${session.username ?? 'Staf'}!',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getHotelName(session.username, session.level),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                              child: _buildSummaryItem(
                                context,
                                title: 'Antrean',
                                count: summary.pending,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryItem(
                                context,
                                title: 'Dikerjakan',
                                count: summary.inProgress,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryItem(
                                context,
                                title: 'Selesai',
                                count: summary.completed,
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
                          if (tasks.isEmpty) {
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
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      backgroundColor: theme.cardTheme.color,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
