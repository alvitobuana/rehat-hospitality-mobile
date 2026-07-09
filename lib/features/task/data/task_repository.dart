import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';
import 'task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return TaskRepository(dioClient);
});

class TaskRepository {
  final DioClient _dioClient;

  TaskRepository(this._dioClient);

  /// Mengambil daftar tugas aktif housekeeping berdasarkan user_id
  Future<List<TaskModel>> getActiveTasks(int userId) async {
    try {
      final response = await _dioClient.get(
        '/Housekeeping/api_list_tasks.php',
        queryParameters: {'user_id': userId},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          final list = data['data'] as List;
          return list.map((item) => TaskModel.fromJson(item)).toList();
        } else {
          throw AppFailure.local(
            data['message'] ?? 'Gagal memuat daftar tugas.',
            'TASK_LIST_REJECTED',
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
      throw AppFailure.local('Gagal mengambil daftar tugas: $e');
    }
  }
}
