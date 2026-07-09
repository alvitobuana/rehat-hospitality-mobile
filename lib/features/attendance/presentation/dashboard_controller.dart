import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/session_manager.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_summary.dart';

class DashboardController extends StateNotifier<AsyncValue<DashboardSummary>> {
  final DashboardRepository _repository;
  final SessionManager _sessionManager;

  /// BUG 5 FIX: Guard untuk mencegah request GET paralel saat rapid pull-to-refresh
  bool _isRefreshing = false;

  DashboardController(this._repository, this._sessionManager) : super(const AsyncValue.loading()) {
    loadSummary();
  }

  /// Mengambil data summary awal (Loading -> Success/Error)
  Future<void> loadSummary() async {
    state = const AsyncValue.loading();
    try {
      final userId = await _sessionManager.getUserId();
      if (userId == null) {
        state = AsyncValue.error('Sesi user_id tidak ditemukan. Silakan login kembali.', StackTrace.current);
        return;
      }
      final summary = await _repository.getDashboardSummary(userId);
      state = AsyncValue.data(summary);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Memperbarui data summary tanpa memicu status loading visual penuh (Refresh)
  Future<void> refreshSummary() async {
    // BUG 5 FIX: Abaikan request jika refresh sebelumnya masih berjalan
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final userId = await _sessionManager.getUserId();
      if (userId == null) {
        state = AsyncValue.error('Sesi tidak ditemukan.', StackTrace.current);
        return;
      }
      final summary = await _repository.getDashboardSummary(userId);
      state = AsyncValue.data(summary);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      _isRefreshing = false;
    }
  }
}

/// Provider Riverpod untuk DashboardController StateNotifier
final dashboardControllerProvider = StateNotifierProvider<DashboardController, AsyncValue<DashboardSummary>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  final sessionManager = ref.watch(sessionManagerProvider);
  return DashboardController(repository, sessionManager);
});

/// Pintasan alias reaktif untuk mendapatkan DashboardSummary AsyncValue secara langsung
final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  return ref.watch(dashboardControllerProvider);
});
