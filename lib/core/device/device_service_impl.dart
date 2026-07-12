import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../features/auth/data/device_repository.dart';
import '../storage/session_manager.dart';
import 'device_info.dart';
import 'device_service.dart';

class DeviceServiceImpl implements DeviceService {
  final DeviceRepository _deviceRepository;
  final SessionManager _sessionManager;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final Logger _logger = Logger();

  DeviceServiceImpl(this._deviceRepository, this._sessionManager);

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    String deviceId = 'unknown_id';
    String deviceModel = 'unknown_model';
    String osVersion = 'unknown_os';

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String appVersion = packageInfo.version;

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id; 
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion = 'Android API ${androidInfo.version.sdkInt}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_id';
        deviceModel = iosInfo.model;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }

      return DeviceInfo(
        deviceId: deviceId,
        deviceModel: '$deviceModel (App v$appVersion)',
        osVersion: osVersion,
      );
    } catch (e) {
      _logger.e('Failed to retrieve device parameters: $e');
      return DeviceInfo(
        deviceId: 'fallback_device_id',
        deviceModel: 'Fallback Model',
        osVersion: 'Fallback OS',
      );
    }
  }

  @override
  Future<bool> isDeviceBound(String userId) async {
    final uid = await _sessionManager.getUserId();
    
    if (uid == null) {
      _logger.e('Cannot validate device: user_id is null or invalid: $userId');
      return false;
    }

    final deviceInfo = await getDeviceInfo();
    // Cache device_id locally in secure storage
    await _sessionManager.saveDeviceId(deviceInfo.deviceId);
    
    return await _deviceRepository.validateDevice(
      userId: uid,
      deviceId: deviceInfo.deviceId,
    );
  }

  @override
  Future<bool> bindDevice(String userId, DeviceInfo device) async {
    final uid = await _sessionManager.getUserId();
    
    if (uid == null) {
      _logger.e('Cannot register device: user_id is null or invalid: $userId');
      return false;
    }

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String appVersion = packageInfo.version;

    return await _deviceRepository.registerDevice(
      userId: uid,
      deviceId: device.deviceId,
      deviceModel: device.deviceModel,
      osVersion: device.osVersion,
      appVersion: appVersion,
    );
  }
}
