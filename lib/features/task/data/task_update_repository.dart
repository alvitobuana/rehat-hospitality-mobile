import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';
import 'task_detail.dart';

final taskUpdateRepositoryProvider = Provider<TaskUpdateRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return TaskUpdateRepository(dioClient);
});

/// Repository untuk memperbarui status tugas dan item checklist
/// melalui POST /Housekeeping/api_update_task.php
class TaskUpdateRepository {
  final DioClient _dioClient;

  TaskUpdateRepository(this._dioClient);

  /// Mengirim pembaruan status tugas dan daftar checklist ke server.
  ///
  /// [taskId]   : ID tugas yang akan diperbarui.
  /// [newStatus]: Status baru tugas (Pending | In Progress | Completed).
  /// [checklist]: Seluruh item checklist beserta status terbarunya.
  ///
  /// Mengembalikan `true` jika server mengkonfirmasi keberhasilan.
  Future<bool> updateTask({
    required int taskId,
    required String newStatus,
    required List<ChecklistItem> checklist,
  }) async {
    try {
      final payload = {
        'task_id': taskId,
        'status': newStatus,
        'checklist': checklist
            .map((item) => {'id': item.id, 'is_checked': item.isChecked})
            .toList(),
      };

      final response = await _dioClient.post(
        '/Housekeeping/api_update_task.php',
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true) {
          return true;
        }
        throw AppFailure.local(
          data['message'] ?? 'Gagal memperbarui tugas.',
          'UPDATE_FAILED',
        );
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AppFailure.local('Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED');
      }
      throw AppFailure.fromDioException(e);
    } catch (e) {
      throw AppFailure.local('Gagal memperbarui tugas: $e');
    }
  }
}
