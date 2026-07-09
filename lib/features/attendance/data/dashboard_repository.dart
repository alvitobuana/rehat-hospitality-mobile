import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';
import 'dashboard_summary.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return DashboardRepository(dioClient);
});

class DashboardRepository {
  final DioClient _dioClient;

  DashboardRepository(this._dioClient);

  /// Mengambil data summary dashboard berdasarkan user_id
  Future<DashboardSummary> getDashboardSummary(int userId) async {
    try {
      final response = await _dioClient.get(
        '/Housekeeping/api_get_dashboard.php',
        queryParameters: {'user_id': userId},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          return DashboardSummary.fromJson(data['data']);
        } else {
          throw AppFailure.local(
            data['message'] ?? 'Gagal memuat dashboard.',
            'DASHBOARD_REJECTED',
          );
        }
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AppFailure.local('Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED');
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal mengambil data dashboard: $e');
    }
  }
}
