import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_detail.dart';
import '../data/task_detail_repository.dart';
import '../data/task_update_repository.dart';

class TaskDetailController extends StateNotifier<AsyncValue<TaskDetail>> {
  final TaskDetailRepository _repository;
  final TaskUpdateRepository _updateRepository;
  final int taskId;

  TaskDetailController(this._repository, this._updateRepository, this.taskId)
      : super(const AsyncValue.loading()) {
    loadTaskDetail();
  }

  /// Mengambil data detail tugas housekeeping secara asinkron
  Future<void> loadTaskDetail() async {
    state = const AsyncValue.loading();
    try {
      final detail = await _repository.getTaskDetail(taskId);
      state = AsyncValue.data(detail);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Memperbarui detail tugas housekeeping (Refresh) tanpa loading indicator
  Future<void> refreshTaskDetail() async {
    try {
      final detail = await _repository.getTaskDetail(taskId);
      state = AsyncValue.data(detail);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Mengubah status tugas dengan Optimistic Update.
  ///
  /// Urutan:
  /// 1. Simpan snapshot state saat ini untuk rollback.
  /// 2. Update UI secara optimis (langsung tampilkan status baru).
  /// 3. Kirim POST ke backend.
  /// 4. Jika berhasil → state tetap, sinkron dengan server melalui refresh ringan.
  /// 5. Jika gagal → rollback ke snapshot, lempar error kembali ke UI.
  Future<void> updateStatus(String newStatus) async {
    final previousState = state;

    // Guard: hanya proses jika state saat ini mengandung data
    final currentData = state.valueOrNull;
    if (currentData == null) return;

    // 1. Optimistic update — update UI seketika
    state = AsyncValue.data(currentData.copyWith(status: newStatus));

    try {
      // 2. Kirim ke backend
      await _updateRepository.updateTask(
        taskId: taskId,
        newStatus: newStatus,
        checklist: currentData.checklist,
      );
      // Berhasil — tidak perlu rollback
    } catch (e) {
      // 3. Gagal — rollback ke state sebelumnya
      state = previousState;
      rethrow;
    }
  }

  /// Toggle satu item checklist dengan Optimistic Update.
  ///
  /// Urutan sama seperti [updateStatus].
  Future<void> toggleChecklist(int checklistItemId, bool newValue) async {
    final previousState = state;
    final currentData = state.valueOrNull;
    if (currentData == null) return;

    // Buat list checklist baru dengan item yang ditoggle
    final updatedChecklist = currentData.checklist.map((item) {
      if (item.id == checklistItemId) {
        return item.copyWith(isChecked: newValue);
      }
      return item;
    }).toList();

    // 1. Optimistic update — update UI seketika
    state = AsyncValue.data(currentData.copyWith(checklist: updatedChecklist));

    try {
      // 2. Kirim ke backend (status tidak berubah, hanya checklist)
      await _updateRepository.updateTask(
        taskId: taskId,
        newStatus: currentData.status,
        checklist: updatedChecklist,
      );
    } catch (e) {
      // 3. Gagal — rollback ke state sebelumnya
      state = previousState;
      rethrow;
    }
  }
}

/// Provider Riverpod keluarga (family) untuk TaskDetailController StateNotifier
final taskDetailControllerProvider =
    StateNotifierProvider.family<TaskDetailController, AsyncValue<TaskDetail>, int>(
  (ref, taskId) {
    final repository = ref.watch(taskDetailRepositoryProvider);
    final updateRepository = ref.watch(taskUpdateRepositoryProvider);
    return TaskDetailController(repository, updateRepository, taskId);
  },
);

/// Pintasan alias reaktif untuk mendapatkan TaskDetail AsyncValue secara langsung berdasarkan taskId
final taskDetailProvider = Provider.family<AsyncValue<TaskDetail>, int>((ref, taskId) {
  return ref.watch(taskDetailControllerProvider(taskId));
});
