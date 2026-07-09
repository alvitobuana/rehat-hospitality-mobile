import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/task_detail.dart';
import 'task_detail_controller.dart';

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
      _showError('Gagal memperbarui checklist. Perubahan dibatalkan.');
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
      _showError('Gagal memperbarui status. Perubahan dibatalkan.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskDetailAsync = ref.watch(taskDetailProvider(widget.taskId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: taskDetailAsync.when(
          data: (TaskDetail detail) => Text('Kamar ${detail.room}'),
          loading: () => const Text('Memuat Detail...'),
          error: (_, __) => const Text('Detail Tugas'),
        ),
      ),
      body: taskDetailAsync.when(
        data: (TaskDetail detail) {
          final isPending = detail.status == 'Pending';
          final isInProgress = detail.status == 'In Progress';
          final isCompleted = detail.status == 'Completed';

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(taskDetailControllerProvider(widget.taskId).notifier)
                  .refreshTaskDetail();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Info
                  AppCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status Pengerjaan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            StatusBadge.fromStatusString(detail.status),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Flat visual Step Progress Indicator
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
                        const Divider(height: 18, color: Color(0xFFF1F3F4)),
                        _buildDetailRow('Petugas (PIC)', detail.assignedStaff),
                        const Divider(height: 18, color: Color(0xFFF1F3F4)),
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
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),

                  // Checklist Box
                  const SectionHeader(title: 'Item Checklist Kamar'),
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
                            children: detail.checklist.map((item) {
                              return CheckboxListTile(
                                title: Text(item.itemName, style: const TextStyle(fontSize: 14)),
                                value: item.isChecked,
                                // Read-only saat tugas Selesai atau sedang memproses
                                onChanged: isCompleted || _isUpdating
                                    ? null
                                    : (bool? newValue) {
                                        if (newValue != null) {
                                          _onChecklistToggled(item.id, newValue);
                                        }
                                      },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  if (isPending)
                    CustomButton(
                      text: _isUpdating ? 'Memproses...' : 'MULAI KELOLA SEKARANG',
                      onPressed: _isUpdating ? null : () => _onUpdateStatus('In Progress'),
                    )
                  else if (isInProgress)
                    CustomButton(
                      text: 'AMBIL FOTO & SELESAIKAN',
                      backgroundColor: Colors.green.shade700,
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      // Navigasi ke halaman upload foto; status Completed di-set setelah foto berhasil diunggah
                      onPressed: _isUpdating ? null : () => context.push('/take-photo/${widget.taskId}'),
                    )
                  else if (isCompleted)
                    const CustomButton(
                      text: '✓ TUGAS TELAH DISELESAIKAN',
                      backgroundColor: Colors.grey,
                      onPressed: null,
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) {
          final isNotFound = err.toString().contains('tidak ditemukan') ||
              err.toString().contains('404');
          return Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isNotFound ? Icons.search_off_rounded : Icons.error_outline_rounded,
                    size: 56,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isNotFound ? 'Tugas Tidak Ditemukan' : 'Gagal Memuat Detail Tugas',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(taskDetailControllerProvider(widget.taskId).notifier)
                          .loadTaskDetail();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
