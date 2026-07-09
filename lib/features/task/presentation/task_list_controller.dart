import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/session_manager.dart';
import '../data/task_model.dart';
import '../data/task_repository.dart';

class TaskListController extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository _repository;
  final SessionManager _sessionManager;

  /// BUG 5 FIX: Guard untuk mencegah request GET paralel saat rapid pull-to-refresh
  bool _isRefreshing = false;

  TaskListController(this._repository, this._sessionManager) : super(const AsyncValue.loading()) {
    loadActiveTasks();
  }

  /// Mengambil daftar tugas aktif (Loading -> Success/Empty/Error)
  Future<void> loadActiveTasks() async {
    state = const AsyncValue.loading();
    try {
      final userId = await _sessionManager.getUserId();
      if (userId == null) {
        state = AsyncValue.error('Sesi user_id tidak ditemukan. Silakan login kembali.', StackTrace.current);
        return;
      }
      final tasks = await _repository.getActiveTasks(userId);
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Memperbarui daftar tugas aktif (Refresh)
  Future<void> refreshActiveTasks() async {
    // BUG 5 FIX: Abaikan request jika refresh sebelumnya masih berjalan
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final userId = await _sessionManager.getUserId();
      if (userId == null) {
        state = AsyncValue.error('Sesi tidak ditemukan.', StackTrace.current);
        return;
      }
      final tasks = await _repository.getActiveTasks(userId);
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      _isRefreshing = false;
    }
  }
}

/// Provider Riverpod untuk TaskListController StateNotifier
final taskListControllerProvider = StateNotifierProvider<TaskListController, AsyncValue<List<TaskModel>>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final sessionManager = ref.watch(sessionManagerProvider);
  return TaskListController(repository, sessionManager);
});

/// Pintasan alias reaktif untuk mendapatkan List dari TaskModel AsyncValue secara langsung
final taskListProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  return ref.watch(taskListControllerProvider);
});
