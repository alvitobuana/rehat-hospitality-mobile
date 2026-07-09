import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/history_item.dart';
import '../data/history_repository.dart';

class HistoryController extends StateNotifier<AsyncValue<List<HistoryItem>>> {
  final HistoryRepository _repository;

  /// BUG 5 FIX: Guard untuk mencegah request GET paralel saat rapid pull-to-refresh
  bool _isRefreshing = false;

  HistoryController(this._repository) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  /// Memuat riwayat tugas dari backend (dengan loading indicator)
  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    try {
      final history = await _repository.getHistory();
      state = AsyncValue.data(history);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Memuat ulang riwayat tanpa menampilkan loading indicator penuh
  /// (digunakan untuk Pull to Refresh)
  Future<void> refreshHistory() async {
    // BUG 5 FIX: Abaikan request jika refresh sebelumnya masih berjalan
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final history = await _repository.getHistory();
      state = AsyncValue.data(history);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      _isRefreshing = false;
    }
  }
}

/// Provider Riverpod untuk HistoryController StateNotifier
final historyControllerProvider =
    StateNotifierProvider<HistoryController, AsyncValue<List<HistoryItem>>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryController(repository);
});

/// Pintasan alias reaktif untuk mendapatkan `AsyncValue<List<HistoryItem>>` secara langsung
final historyListProvider =
    Provider<AsyncValue<List<HistoryItem>>>((ref) {
  return ref.watch(historyControllerProvider);
});
