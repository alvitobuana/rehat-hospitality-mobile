import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/task_detail.dart';
import 'task_detail_controller.dart';
import 'task_list_controller.dart';
import '../../attendance/presentation/attendance_controller.dart';
import '../../attendance/presentation/dashboard_controller.dart';
import '../../../core/exceptions/app_failure.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final int taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isUpdating = false;

  /// Menampilkan pesan error di SnackBar
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Menampilkan pesan sukses di SnackBar
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Toggle satu item checklist (Optimistic Update)
  Future<void> _onChecklistToggled(int itemId, bool newValue) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .toggleChecklist(itemId, newValue);
    } catch (e) {
      _handleExpiredError(e, 'Gagal memperbarui checklist. Perubahan dibatalkan.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  /// Mengubah status tugas (Optimistic Update)
  Future<void> _onUpdateStatus(String newStatus) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .updateStatus(newStatus);
      _showSuccess('Status tugas berhasil diperbarui.');
    } catch (e) {
      _handleExpiredError(e, 'Gagal memperbarui status. Perubahan dibatalkan.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _handleExpiredError(dynamic e, String defaultMessage) {
    final errStr = e.toString();
    if (errStr.contains('Task telah berakhir') || (e is AppFailure && e.statusCode == 409)) {
      _showExpiredDialog();
    } else {
      _showError(defaultMessage);
    }
  }

  void _showExpiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppInsets.r12)),
          title: const Text('Task Berakhir'),
          content: const Text(
            'Task ini telah berakhir karena pergantian hari dan tidak dapat diubah lagi.\n\n'
            'Silakan hubungi Admin apabila diperlukan.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _handleExpiredAction();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _handleExpiredAction() {
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(taskListControllerProvider);
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskDetailAsync = ref.watch(taskDetailProvider(widget.taskId));
    final attendanceState = ref.watch(attendanceControllerProvider);
    final isAttendanceActive = attendanceState.status == AttendanceStatus.checkedIn;
    final pageTitle = taskDetailAsync.when(
      data: (TaskDetail detail) => 'Kamar ${detail.room}',
      loading: () => 'Memuat Detail...',
      error: (_, __) => 'Detail Tugas',
    );

    return AppPage(
      title: pageTitle,
      useSafeArea: true,
      scrollable: true,
      onRefresh: () async {
        await ref
            .read(taskDetailControllerProvider(widget.taskId).notifier)
            .refreshTaskDetail();
      },
      padding: EdgeInsets.only(
        left: AppInsets.s24,
        right: AppInsets.s24,
        top: AppInsets.s24,
        bottom: AppInsets.s24 + AppInsets.bottomSafe(context),
      ),
      child: taskDetailAsync.when(
        data: (TaskDetail detail) {
          final isPending    = detail.status == 'Pending';
          final isInProgress = detail.status == 'In Progress';
          final isCompleted  = detail.status == 'Completed';

          // Sprint 7.1: Checklist Gate
          final checklistComplete = detail.isChecklistComplete;
          final doneCount         = detail.checklistDoneCount;
          final totalCount        = detail.checklistTotalCount;
          final hasChecklist      = totalCount > 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sprint 7.3: Attendance Access Control notice banner
              if (!isAttendanceActive) ...[
                AppInfoCard(
                  title: 'Akses Terkunci',
                  message: 'Anda harus melakukan Check-In absensi terlebih dahulu untuk mengelola tugas.',
                  icon: Icons.lock_outline_rounded,
                  color: AppColors.danger(context),
                  backgroundColor: AppColors.danger(context).withAlpha(15),
                ),
                const SizedBox(height: AppInsets.s16),
              ],

              // Status Info
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status Pengerjaan',
                          style: AppTypography.body(context).copyWith(fontWeight: FontWeight.bold),
                        ),
                        StatusBadge.fromStatusString(detail.status),
                      ],
                    ),
                    const SizedBox(height: AppInsets.s20),

                    // Step Progress Indicator
                    Row(
                      children: [
                        _buildStep(context, label: 'Antrean', isActive: true, isDone: isInProgress || isCompleted),
                        _buildConnector(context, isDone: isInProgress || isCompleted),
                        _buildStep(context, label: 'Dikerjakan', isActive: isInProgress || isCompleted, isDone: isCompleted),
                        _buildConnector(context, isDone: isCompleted),
                        _buildStep(context, label: 'Selesai', isActive: isCompleted, isDone: isCompleted),
                      ],
                    ),
                  ],
                ),
              ),

              // Task Details Box
              const SectionHeader(title: 'Spesifikasi Ruangan'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Nomor Kamar', 'Kamar ${detail.room}'),
                    Divider(height: 18, color: AppColors.divider(context)),
                    _buildDetailRow('Petugas (PIC)', detail.assignedStaff),
                    Divider(height: 18, color: AppColors.divider(context)),
                    _buildDetailRow('Tanggal Dibuat', detail.createdAt),
                  ],
                ),
              ),

              // Instruction Box
              const SectionHeader(title: 'Instruksi Pembersihan'),
              AppCard(
                child: Text(
                  detail.description.isNotEmpty
                      ? detail.description
                      : 'Tidak ada instruksi khusus.',
                  style: AppTypography.body(context).copyWith(height: 1.4),
                ),
              ),

              // Checklist Box — Sprint 7.1: badge counter & gate notice
              _buildChecklistHeader(
                context,
                hasChecklist: hasChecklist,
                doneCount: doneCount,
                totalCount: totalCount,
                isComplete: checklistComplete,
                isInProgress: isInProgress,
              ),
              AppCard(
                child: detail.checklist.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Tidak ada item checklist untuk kamar ini.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : Column(
                        children: [
                          // Checklist items
                          ...detail.checklist.map((item) {
                            return CheckboxListTile(
                              title: Text(item.itemName, style: const TextStyle(fontSize: 14)),
                              value: item.isChecked,
                              // Read-only jika status tugas bukan 'In Progress', sedang memproses, atau absensi tidak aktif
                              onChanged: !isInProgress || _isUpdating || !isAttendanceActive
                                  ? null
                                  : (bool? newValue) {
                                      if (newValue != null) {
                                        _onChecklistToggled(item.id, newValue);
                                      }
                                    },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeColor: Colors.green.shade700,
                            );
                          }),

                          // Sprint 7.1: Gate warning notice saat In Progress & belum selesai
                          if (isInProgress && hasChecklist && !checklistComplete) ...[
                            const SizedBox(height: AppInsets.s8),
                            AppInfoCard(
                              title: 'Selesaikan Checklist',
                              message: 'Selesaikan semua item checklist ($doneCount/$totalCount) sebelum menyelesaikan tugas.',
                              icon: Icons.warning_amber_rounded,
                              color: Colors.amber.shade800,
                              backgroundColor: Colors.amber.shade50,
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppInsets.s16),

              // Foto Bukti Box — Sprint 8.3: progress indicator
              _buildPhotoHeader(
                context,
                doneCount: detail.photoCount,
                totalCount: 3,
                isComplete: detail.photoCount >= 3 || isCompleted,
                isInProgress: isInProgress,
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isCompleted && detail.photoCount == 0 ? 1.0 : (detail.photoCount / 3).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (detail.photoCount >= 3 || isCompleted) ? Colors.green.shade700 : Colors.orange.shade700
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isCompleted && detail.photoCount == 0
                        ? 'Foto bukti telah dihapus sesuai kebijakan retensi (14 hari).'
                        : (detail.photoCount >= 3 || isCompleted)
                          ? 'Foto bukti sudah lengkap (3/3).' 
                          : 'Wajib mengunggah 3 foto bukti sebagai dokumentasi.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isCompleted && detail.photoCount == 0
                          ? Colors.orange.shade800
                          : (detail.photoCount >= 3 || isCompleted)
                            ? Colors.green.shade800
                            : Colors.grey[600],
                        fontWeight: (detail.photoCount >= 3 || isCompleted) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppInsets.s16),

              // Action Buttons
              if (isPending)
                AppPrimaryButton(
                  text: _isUpdating ? 'Memproses...' : 'MULAI KELOLA SEKARANG',
                  backgroundColor: !isAttendanceActive ? Colors.grey.shade400 : null,
                  onPressed: _isUpdating || !isAttendanceActive ? null : () => _onUpdateStatus('In Progress'),
                )
              else if (isInProgress)
                _buildCompleteButton(
                  context,
                  checklistComplete: checklistComplete,
                  hasChecklist: hasChecklist,
                  doneCount: doneCount,
                  totalCount: totalCount,
                  isAttendanceActive: isAttendanceActive,
                  photoCount: detail.photoCount,
                )
              else if (isCompleted)
                const AppPrimaryButton(
                  text: '✓ TUGAS TELAH DISELESAIKAN',
                  onPressed: null,
                ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppInsets.s24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) {
          final isNotFound = err.toString().contains('tidak ditemukan') ||
              err.toString().contains('404');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNotFound ? Icons.search_off_rounded : Icons.error_outline_rounded,
                  size: 56,
                  color: AppColors.danger(context),
                ),
                const SizedBox(height: AppInsets.s16),
                Text(
                  isNotFound ? 'Tugas Tidak Ditemukan' : 'Gagal Memuat Detail Tugas',
                  style: AppTypography.title(context).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppInsets.s8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(context),
                ),
                const SizedBox(height: AppInsets.s24),
                AppPrimaryButton(
                  text: 'Coba Lagi',
                  onPressed: () {
                    ref
                        .read(taskDetailControllerProvider(widget.taskId).notifier)
                        .loadTaskDetail();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sprint 7.1: Checklist Section Header dengan badge counter
  // ---------------------------------------------------------------------------

  Widget _buildChecklistHeader(
    BuildContext context, {
    required bool hasChecklist,
    required int doneCount,
    required int totalCount,
    required bool isComplete,
    required bool isInProgress,
  }) {
    if (!hasChecklist) {
      return const SectionHeader(title: 'Item Checklist Kamar');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Item Checklist Kamar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          // Badge counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isComplete
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isComplete ? Icons.check_circle_rounded : Icons.pending_outlined,
                  size: 14,
                  color: isComplete ? Colors.green.shade700 : Colors.orange.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  '$doneCount/$totalCount selesai',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isComplete ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sprint 8.3: Photo Section Header dengan badge counter
  // ---------------------------------------------------------------------------

  Widget _buildPhotoHeader(
    BuildContext context, {
    required int doneCount,
    required int totalCount,
    required bool isComplete,
    required bool isInProgress,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Foto Bukti Kamar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          // Badge counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isComplete
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isComplete ? Icons.check_circle_rounded : Icons.pending_outlined,
                  size: 14,
                  color: isComplete ? Colors.green.shade700 : Colors.orange.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  (isComplete && doneCount == 0)
                      ? 'Dihapus (Retensi)'
                      : '$doneCount/$totalCount terunggah',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isComplete ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sprint 7.1: Tombol Selesaikan dengan checklist gate
  // ---------------------------------------------------------------------------

  Widget _buildCompleteButton(
    BuildContext context, {
    required bool checklistComplete,
    required bool hasChecklist,
    required int doneCount,
    required int totalCount,
    required bool isAttendanceActive,
    required int photoCount,
  }) {
    // Gate: disabled jika checklist belum selesai semua atau absensi tidak aktif
    final isBlocked = (hasChecklist && !checklistComplete) || !isAttendanceActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPrimaryButton(
          text: photoCount > 0 
              ? 'KELOLA FOTO BUKTI ($photoCount/3)' 
              : 'AMBIL FOTO BUKTI',
          backgroundColor: isBlocked ? Colors.grey.shade400 : Colors.green.shade700,
          icon: Icon(
            isBlocked ? Icons.lock_outline_rounded : Icons.camera_alt_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: isBlocked || _isUpdating
              ? null
              : () => context.push('/take-photo/${widget.taskId}'),
        ),

        // Pesan alasan disabled
        if (isBlocked) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                !isAttendanceActive
                    ? 'Check-In absensi diperlukan untuk mengelola tugas.'
                    : 'Selesaikan checklist ($doneCount/$totalCount) untuk melanjutkan.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildStep(
    BuildContext context, {
    required String label,
    required bool isActive,
    required bool isDone,
  }) {
    final theme = Theme.of(context);
    final circleColor = isDone
        ? Colors.green
        : isActive
            ? theme.primaryColor
            : Colors.grey[300];

    final textColor =
        isActive || isDone ? theme.textTheme.bodyLarge?.color : Colors.grey;

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: circleColor,
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : isActive
                    ? const CircleAvatar(radius: 4, backgroundColor: Colors.white)
                    : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  isActive || isDone ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BuildContext context, {required bool isDone}) {
    return Container(
      width: 32,
      height: 2.5,
      color: isDone ? Colors.green : Colors.grey[300],
      margin: const EdgeInsets.only(bottom: 18.0),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
