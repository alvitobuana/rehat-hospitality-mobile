import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase terinisialisasi untuk isolate latar belakang
  await Firebase.initializeApp();
  final logger = Logger();
  logger.i("Background message received ID: ${message.messageId}");
}

final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  return FirebaseMessagingService();
});

class FirebaseMessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();
  
  static const String _fcmChannelId = 'rehat_housekeeping_channel';
  static const String _fcmChannelName = 'Rehat Housekeeping';
  static const String _fcmChannelDescription = 'Channel untuk notifikasi tugas dan info Rehat Housekeeping';
  static const String _prefFcmTokenKey = 'fcm_token_cache';

  // Callback ketika token di-refresh oleh Firebase
  void Function(String token)? _onTokenRefreshCallback;

  /// Registrasi listener refresh token
  void setOnTokenRefresh(void Function(String token) callback) {
    _onTokenRefreshCallback = callback;
  }

  /// Inisialisasi Firebase Cloud Messaging dan local notifications
  Future<void> initialize() async {
    try {
      // 1. Daftarkan background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Setup Android Notification Channel dengan Importance High
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _fcmChannelId,
          _fcmChannelName,
          description: _fcmChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await androidPlugin?.createNotificationChannel(channel);
      }

      // 3. Inisialisasi plugin notifikasi lokal untuk menampilkan pesan saat Foreground
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _logger.i("Foreground notification clicked: ${response.payload}");
        },
      );

      // 4. Minta izin notifikasi (terutama Android 13+)
      await requestNotificationPermissions();

      // 5. Setup foreground notification listener
      _setupForegroundListener();

      // 6. Setup token refresh listener
      _fcm.onTokenRefresh.listen((newToken) async {
        _logger.i("FCM Token refreshed: $newToken");
        _logger.i("FCM TOKEN:\n$newToken");
        await cacheTokenLocally(newToken);
        if (_onTokenRefreshCallback != null) {
          _onTokenRefreshCallback!(newToken);
        }
      });

      // Ambil token awal dan simpan ke cache
      final initialToken = await getFcmToken();
      if (initialToken != null) {
        _logger.i("Initial FCM Token retrieved: $initialToken");
        _logger.i("FCM TOKEN:\n$initialToken");
      }

    } catch (e) {
      _logger.e("Gagal menginisialisasi Firebase Messaging Service: $e");
    }
  }

  /// Minta izin Push Notification (Android 13+)
  Future<bool> requestNotificationPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _logger.i("Notification permission status: ${settings.authorizationStatus}");
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      _logger.e("Error requesting notification permissions: $e");
      return false;
    }
  }

  /// Memperoleh FCM Token saat ini
  Future<String?> getFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        _logger.i("FCM TOKEN:\n$token");
        await cacheTokenLocally(token);
      }
      return token;
    } catch (e) {
      _logger.e("Error fetching FCM token: $e");
      // Fallback load dari cache lokal jika gagal mengambil yang baru
      return getCachedToken();
    }
  }

  /// Menghapus FCM Token (misal saat logout jika diperlukan secara client-side)
  Future<void> deleteFcmToken() async {
    try {
      await _fcm.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefFcmTokenKey);
      _logger.i("FCM Token locally deleted.");
    } catch (e) {
      _logger.e("Error deleting FCM token: $e");
    }
  }

  /// Menyimpan token ke shared_preferences sebagai cache sementara
  Future<void> cacheTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefFcmTokenKey, token);
  }

  /// Mengambil token ter-cache
  Future<String?> getCachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefFcmTokenKey);
  }

  /// Setup listener saat notifikasi masuk dan aplikasi sedang Foreground
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i("Foreground FCM Message received: ${message.messageId}");
      
      final notification = message.notification;
      final android = message.notification?.android;
      
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _fcmChannelId,
              _fcmChannelName,
              channelDescription: _fcmChannelDescription,
              importance: Importance.max,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
          ),
          payload: json.encode(message.data),
        );
      }
    });

    // Menangani ketika notifikasi diklik saat aplikasi di latar belakang (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i("Notification clicked from background state: ${message.messageId}");
    });
  }
}
