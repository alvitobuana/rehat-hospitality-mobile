import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Memuat konfigurasi environment secara dinamis dari folder assets `config/`
class EnvConfig {
  static late String baseUrl;
  static late String environment;
  static late bool debug;

  static final Logger _logger = Logger();

  static Future<void> initialize() async {
    // Membaca jalur file dari Dart Define (contoh: --dart-define=envConfigPath=config/env_staging.json)
    // Fallback default ke config/env_dev.json
    const envPath = String.fromEnvironment(
      'envConfigPath',
      defaultValue: 'config/env_dev.json',
    );

    try {
      final jsonString = await rootBundle.loadString(envPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      baseUrl = jsonMap['baseUrl'] as String;
      environment = jsonMap['environment'] as String;
      debug = jsonMap['debug'] as bool;

      _logger.i('✓ Environment "$environment" initialized. Base URL: $baseUrl');
    } catch (e) {
      // Fallback default jika file tidak ditemukan
      baseUrl = 'http://localhost/qa_web_rehat';
      environment = 'development';
      debug = true;
      _logger.w('⚠ Failed to load environment config from path "$envPath". '
          'Falling back to default. Error: $e');
    }
  }
}
