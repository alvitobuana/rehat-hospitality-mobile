import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/env_config.dart';
import 'services/firebase_messaging_service.dart';

void main() async {
  // Menjamin framework Flutter terinisialisasi sebelum pemicuan operasi async
  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();

  try {
    // 1. Memuat konfigurasi environment (Dart Define config loader)
    await EnvConfig.initialize();

    // 2. Menginisialisasi Klien Dio & Cookie Jar persistent
    final sessionManager = SessionManager();
    final dioClient = await DioClient.initialize(sessionManager);

    // 3. Menginisialisasi Firebase & Firebase Messaging Service
    await Firebase.initializeApp();
    final fcmService = FirebaseMessagingService();
    fcmService.initialize(); // Run asynchronously to not block runApp and UI loading

    logger.i('✓ Flutter Foundation Core (Sprint 1.1 Refined) with FCM initialization success.');


    runApp(
      ProviderScope(
        overrides: [
          // Meng-override provider DioClient agar instansiasi Dio yang sudah siap dapat digunakan global
          dioClientProvider.overrideWithValue(dioClient),
          // Meng-override provider SessionManager agar instance yang sama digunakan global
          sessionManagerProvider.overrideWithValue(sessionManager),
          // Meng-override provider FirebaseMessagingService agar instance terinisialisasi digunakan global
          firebaseMessagingServiceProvider.overrideWithValue(fcmService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    logger.e('Critical Failure during app bootstrap initialization: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Rehat Housekeeping Mobile',
      debugShowCheckedModeBanner: false,
      
      // Standar Design System visual
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Menyesuaikan setelan OS ponsel karyawan
      
      // GoRouter Declarative Routing
      routerConfig: router,
    );
  }
}
