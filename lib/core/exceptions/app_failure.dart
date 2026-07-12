import 'package:dio/dio.dart';

/// Representasi standar kegagalan/error dalam aplikasi
class AppFailure implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  const AppFailure({
    required this.message,
    required this.code,
    this.statusCode,
  });

  /// Factory untuk memetakan DioException menjadi AppFailure terstruktur
  factory AppFailure.fromDioException(DioException dioException) {
    String message = 'Terjadi kesalahan koneksi yang tidak diketahui.';
    String code = 'UNKNOWN_NETWORK_ERROR';
    int? statusCode = dioException.response?.statusCode;

    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Koneksi ke server terputus (Waktu tunggu habis).';
        code = 'CONNECTION_TIMEOUT';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Gagal mengirim data ke server (Waktu kirim habis).';
        code = 'SEND_TIMEOUT';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Gagal memuat data dari server (Waktu terima habis).';
        code = 'RECEIVE_TIMEOUT';
        break;
      case DioExceptionType.badCertificate:
        message = 'Sertifikat keamanan server tidak valid atau tidak aman.';
        code = 'BAD_CERTIFICATE';
        break;
      case DioExceptionType.badResponse:
        final data = dioException.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          message = data['message'] as String;
        } else {
          message = 'Server merespon dengan status error: $statusCode';
        }
        
        // Pemetaan status code
        if (statusCode == 400) {
          code = 'BAD_REQUEST';
        } else if (statusCode == 401) {
          code = 'UNAUTHORIZED';
        } else if (statusCode == 403) {
          code = 'FORBIDDEN';
        } else if (statusCode == 404) {
          code = 'NOT_FOUND';
        } else if (statusCode == 500) {
          code = 'SERVER_ERROR';
          message = 'Terjadi gangguan internal pada server hotel.';
        } else {
          code = 'BAD_RESPONSE';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Permintaan data ke server dibatalkan.';
        code = 'REQUEST_CANCELLED';
        break;
      case DioExceptionType.connectionError:
        message = 'Gagal terhubung ke server. Periksa jaringan internet Anda.';
        code = 'CONNECTION_ERROR';
        break;
      case DioExceptionType.unknown:
      default:
        if (dioException.error != null && dioException.error.toString().contains('SocketException')) {
          message = 'Jaringan internet terputus. Menggunakan Mode Offline.';
          code = 'OFFLINE_STATE';
        } else {
          message = dioException.message ?? message;
          code = 'UNKNOWN_EXCEPTION';
        }
        break;
    }

    return AppFailure(message: message, code: code, statusCode: statusCode);
  }

  /// Factory untuk error lokal/formatting data
  factory AppFailure.local(String message, [String code = 'LOCAL_ERROR']) {
    return AppFailure(message: message, code: code);
  }

  @override
  String toString() => 'AppFailure(code: $code, message: $message, statusCode: $statusCode)';
}

/// Kegagalan check-out karena masih ada tugas yang belum selesai
class IncompleteTasksFailure extends AppFailure {
  final List<String> rooms;
  
  const IncompleteTasksFailure({
    required this.rooms,
    required String message,
  }) : super(message: message, code: 'INCOMPLETE_TASKS');
}
