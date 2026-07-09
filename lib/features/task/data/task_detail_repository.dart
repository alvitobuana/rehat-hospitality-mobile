import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';
import 'task_detail.dart';

final taskDetailRepositoryProvider = Provider<TaskDetailRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return TaskDetailRepository(dioClient);
});

class TaskDetailRepository {
  final DioClient _dioClient;

  TaskDetailRepository(this._dioClient);

  /// Mengambil data detail tugas housekeeping berdasarkan task_id
  Future<TaskDetail> getTaskDetail(int taskId) async {
    try {
      final response = await _dioClient.get(
        '/Housekeeping/api_get_task.php',
        queryParameters: {'id': taskId},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          return TaskDetail.fromJson(data['data']);
        } else {
          throw AppFailure.local(
            data['message'] ?? 'Tugas tidak ditemukan.',
            'TASK_NOT_FOUND',
          );
        }
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw AppFailure.local('Tugas tidak ditemukan (404).', 'TASK_NOT_FOUND');
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AppFailure.local('Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED');
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal mengambil detail tugas: $e');
    }
  }
}
