import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';

// ── Cache keys ──────────────────────────────────────────────────────────────
const _kReportsCacheKey = 'engineer_reports_cache_v1';

// ── Provider definitions ────────────────────────────────────────────────────

final engineerRepositoryProvider = Provider<EngineerRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return EngineerRepository(dioClient);
});

/// Provider semua laporan yang relevan untuk engineer ini (NEW pool + claimed)
final engineerReportsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(engineerRepositoryProvider);
  return repo.fetchReports();
});

/// Provider laporan yang sedang dikerjakan oleh engineer ini (CLAIMED / IN_PROGRESS)
final engineerMyTasksProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(engineerRepositoryProvider);
  final all = await repo.fetchReports();
  // Filter hanya yang diklaim oleh engineer ini (bukan pool NEW/OPEN)
  return all
      .where((r) =>
          r['status'] != 'NEW' &&
          r['status'] != 'OPEN' &&
          (r['is_mine'] == true || r['is_mine'] == 1))
      .toList();
});

// ── Repository ───────────────────────────────────────────────────────────────

class EngineerRepository {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  EngineerRepository(this._dioClient);

  // ── Fetch daftar laporan ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchReports() async {
    try {
      final response = await _dioClient.get(
        '/Housekeeping/api_list_maintenance.php',
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final list = data['data'] as List? ?? [];
        final result =
            list.map((item) => Map<String, dynamic>.from(item)).toList();
        // Simpan ke cache offline
        await _cacheReports(result);
        return result;
      }
      throw AppFailure.local(
        data['message'] ?? 'Gagal memuat daftar laporan.',
        'FETCH_FAILED',
      );
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AppFailure.local(
            'Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED');
      }
      // Offline fallback — kembalikan cache jika ada
      _logger.w('Network error, loading from cache: ${e.message}');
      final cached = await _loadCachedReports();
      if (cached != null) return cached;
      throw AppFailure.local('Tidak ada koneksi. Cache tidak tersedia.');
    } catch (e) {
      throw AppFailure.local('Gagal memuat laporan: $e');
    }
  }

  // ── Offline Cache ─────────────────────────────────────────────────────────

  Future<void> _cacheReports(List<Map<String, dynamic>> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kReportsCacheKey, json.encode(reports));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>?> _loadCachedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kReportsCacheKey);
      if (raw == null) return null;
      return (json.decode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── Fetch detail satu laporan ─────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchReportDetail(int reportId) async {
    try {
      final response = await _dioClient.get(
        '/Housekeeping/api_list_maintenance.php',
        queryParameters: {'id': reportId},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
      throw AppFailure.local(
        data['message'] ?? 'Laporan tidak ditemukan.',
        'DETAIL_FAILED',
      );
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AppFailure.local(
            'Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED');
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal memuat detail laporan: $e');
    }
  }

  // ── Klaim laporan (NEW → CLAIMED) ─────────────────────────────────────────

  Future<void> claimReport(int reportId) async {
    try {
      _logger.i('Engineer mengklaim laporan ID: $reportId');
      final response = await _dioClient.post(
        '/Housekeeping/api_engineer_claim.php',
        data: {'report_id': reportId},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) return;
      throw AppFailure.local(
        data['message'] ?? 'Gagal mengklaim laporan.',
        'CLAIM_FAILED',
      );
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      final resData = e.response?.data;
      if (resData is Map<String, dynamic> && resData['message'] != null) {
        throw AppFailure.local(resData['message'], 'CLAIM_FAILED_SERVER');
      }
      if (e.response?.statusCode == 409) {
        throw AppFailure.local(
            'Laporan sudah diklaim oleh engineer lain.', 'ALREADY_CLAIMED');
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal mengklaim laporan: $e');
    }
  }

  // ── Update progress ───────────────────────────────────────────────────────

  Future<void> updateProgress(int reportId, String newStatus,
      {String? notes}) async {
    try {
      _logger.i('Engineer update laporan $reportId -> $newStatus');
      final response = await _dioClient.post(
        '/Housekeeping/api_engineer_update.php',
        data: {
          'report_id': reportId,
          'status': newStatus,
          if (notes != null) 'notes': notes,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) return;
      throw AppFailure.local(
        data['message'] ?? 'Gagal memperbarui status laporan.',
        'UPDATE_FAILED',
      );
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      final resData = e.response?.data;
      if (resData is Map<String, dynamic> && resData['message'] != null) {
        throw AppFailure.local(resData['message'], 'UPDATE_FAILED_SERVER');
      }
      if (e.response?.statusCode == 422) {
        throw AppFailure.local(
          'Upload minimal 1 foto bukti sebelum menandai selesai.',
          'PHOTO_REQUIRED',
        );
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal memperbarui status: $e');
    }
  }

  // ── Upload foto bukti perbaikan ───────────────────────────────────────────

  Future<Map<String, dynamic>> uploadRepairPhoto(
      int reportId, XFile photo) async {
    try {
      _logger.i('Upload foto bukti perbaikan untuk laporan $reportId');
      final ext = photo.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'repair_evidence_${reportId}_$timestamp.$ext';

      final formData = FormData.fromMap({
        'report_id': reportId.toString(),
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
        ),
      });

      final response = await _dioClient.post(
        '/Housekeeping/api_engineer_upload_photo.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data;
      }
      throw AppFailure.local(
        data['message'] ?? 'Gagal mengupload foto.',
        'UPLOAD_FAILED',
      );
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      final resData = e.response?.data;
      if (resData is Map<String, dynamic> && resData['message'] != null) {
        throw AppFailure.local(resData['message'], 'UPLOAD_FAILED_SERVER');
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal mengupload foto: $e');
    }
  }
}
