/// Representasi metadata identitas perangkat fisik untuk kebutuhan Device Binding
class DeviceInfo {
  final String deviceId;
  final String deviceModel;
  final String osVersion;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_model': deviceModel,
      'os_version': osVersion,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['device_id'] as String,
      deviceModel: json['device_model'] as String,
      osVersion: json['os_version'] as String,
    );
  }

  @override
  String toString() => 'DeviceInfo(deviceId: $deviceId, deviceModel: $deviceModel, osVersion: $osVersion)';
}
