import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import '../exceptions/app_failure.dart';
import '../storage/session_manager.dart';
import '../utils/env_config.dart';

/// Provider Riverpod untuk mengakses instance DioClient secara global
final dioClientProvider = Provider<DioClient>((ref) {
  throw UnimplementedError('DioClient harus diinisialisasi terlebih dahulu di main.dart');
});

/// BUG 3 FIX: ValueNotifier global sebagai event bus tipis untuk sinyal sesi kedaluwarsa.
///
/// DioClient men-set nilai ini ke true saat interceptor mendeteksi HTTP 401/403.
/// DashboardScreen (dan screen lainnya) listen ke notifier ini dan langsung
/// memicu logout + redirect ke Login secara reaktif.
///
/// Setelah logout diproses, nilai direset ke false.
final sessionExpiredNotifier = ValueNotifier<bool>(false);

class DioClient {
  late final Dio dio;
  late final PersistCookieJar cookieJar;
  final Logger _logger = Logger();

  DioClient._(this.dio, this.cookieJar);

  /// Menginisialisasi Klien Dio secara asynchronous (menyiapkan storage cookie jar)
  static Future<DioClient> initialize(SessionManager sessionManager) async {
    final dio = Dio();
    
    // Konfigurasi Base Options
    dio.options = BaseOptions(
      baseUrl: EnvConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    // Setup Storage Cookie Jar untuk Session Cookie PHP (PHPSESSID)
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookieJarPath = '${appDocDir.path}/.cookies/';
    final cookieJar = PersistCookieJar(
      storage: FileStorage(cookieJarPath),
    );

    // Menambahkan Interceptor Cookie & Log
    dio.interceptors.add(CookieManager(cookieJar));
    
    // Custom Session Interceptor untuk sinkronisasi dengan Secure Storage
    dio.interceptors.add(SessionInterceptor(sessionManager));
    
    if (EnvConfig.debug) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => Logger().d(obj),
      ));
    }

    // Menambahkan custom Interceptor untuk pemetaan error global
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        // Memetakan DioException menjadi AppFailure terstandar
        final appFailure = AppFailure.fromDioException(e);

        // BUG 3 FIX: Bersihkan session dan kirim sinyal expired saat 401 atau 403
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await sessionManager.clearSession();
          // Notifikasi listener UI agar langsung redirect ke halaman Login
          sessionExpiredNotifier.value = true;
        }

        // Membungkus kembali error aslinya agar dapat ditangkap sebagai AppFailure
        final error = DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: appFailure,
          message: appFailure.message,
        );
        return handler.next(error);
      },
    ));

    return DioClient._(dio, cookieJar);
  }

  /// Helper untuk request GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        throw e.error as AppFailure;
      }
      throw AppFailure.local(e.message ?? 'Terjadi kesalahan sistem.');
    }
  }

  /// Helper untuk request POST
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        throw e.error as AppFailure;
      }
      throw AppFailure.local(e.message ?? 'Terjadi kesalahan sistem.');
    }
  }

  /// Menghapus seluruh session cookie (dipanggil saat logout)
  Future<void> clearCookies() async {
    try {
      await cookieJar.deleteAll();
      _logger.i('✓ Persistent cookies cleared successfully.');
    } catch (e) {
      _logger.e('Failed to clear persistent cookies: $e');
    }
  }
}

class SessionInterceptor extends Interceptor {
  final SessionManager _sessionManager;

  SessionInterceptor(this._sessionManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // KECUALIKAN endpoint registrasi dari pengiriman session cookie
    if (options.path.contains('api_register.php')) {
      handler.next(options);
      return;
    }

    final phpSessionId = await _sessionManager.getPhpSessionId();
    if (phpSessionId != null && phpSessionId.isNotEmpty) {
      options.headers['Cookie'] = 'PHPSESSID=$phpSessionId';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final setCookies = response.headers['set-cookie'];
    if (setCookies != null && setCookies.isNotEmpty) {
      for (var cookie in setCookies) {
        if (cookie.contains('PHPSESSID=')) {
          final match = RegExp(r'PHPSESSID=([^;]+)').firstMatch(cookie);
          if (match != null) {
            final phpSessionId = match.group(1);
            if (phpSessionId != null) {
              await _sessionManager.savePhpSessionId(phpSessionId);
            }
          }
        }
      }
    }
    handler.next(response);
  }
}
