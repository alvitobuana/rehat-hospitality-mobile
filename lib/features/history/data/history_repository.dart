import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/session_manager.dart';
import 'history_item.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final sessionManager = ref.read(sessionManagerProvider);
  return HistoryRepository(dioClient, sessionManager);
});

/// Repository untuk mengambil riwayat tugas housekeeping yang telah selesai
/// melalui GET /Housekeeping/api_get_history.php?user_id={userId}
class HistoryRepository {
  final DioClient _dioClient;
  final SessionManager _sessionManager;

  HistoryRepository(this._dioClient, this._sessionManager);

  /// Mengambil seluruh riwayat tugas berstatus Completed untuk user aktif.
  ///
  /// Mengembalikan list [HistoryItem] yang sudah terurut dari terbaru ke terlama
  /// (urutan dari backend, ORDER BY updated_at DESC).
  Future<List<HistoryItem>> getHistory() async {
    // Ambil user_id dari session
    final userId = await _sessionManager.getUserId();
    if (userId == null) {
      throw AppFailure.local(
        'Sesi berakhir. Silakan masuk kembali.',
        'SESSION_EXPIRED',
      );
    }

    try {
      final response = await _dioClient.get(
        '/Housekeeping/api_get_history.php',
        queryParameters: {'user_id': userId},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true) {
          final list = data['data'] as List? ?? [];
          return list
              .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        // success: false — server mengembalikan pesan error
        throw AppFailure.local(
          data['message'] ?? 'Gagal memuat riwayat tugas.',
          'HISTORY_FETCH_FAILED',
        );
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 401:
        case 403:
          throw AppFailure.local('Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED');
        case 404:
          throw AppFailure.local('Data riwayat tidak ditemukan.', 'NOT_FOUND');
        case 500:
          throw AppFailure.local('Terjadi gangguan pada server hotel.', 'SERVER_ERROR');
        default:
          throw AppFailure.fromDioException(e);
      }
    } catch (e) {
      throw AppFailure.local('Gagal memuat riwayat: $e');
    }
  }
}
