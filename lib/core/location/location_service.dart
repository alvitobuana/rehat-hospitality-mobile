import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service_impl.dart';

/// Provider global untuk mengakses layanan GPS Location
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationServiceImpl();
});

/// Status permission lokasi yang lebih granular untuk keperluan UX flow.
///
/// Membedakan antara belum diminta, ditolak, dan ditolak permanen,
/// sehingga UI dapat menampilkan tindakan yang tepat kepada pengguna.
enum LocationPermissionStatus {
  /// Permission belum pernah diminta, tampilkan rationale screen
  notDetermined,
  /// Permission sudah diberikan
  granted,
  /// User menolak, masih bisa diminta lagi
  denied,
  /// User memilih 'Don't Ask Again', arahkan ke App Settings
  permanentlyDenied,
  /// GPS service dimatikan di level OS
  serviceDisabled,
}

/// Kontrak abstraksi layanan GPS/Lokasi untuk kebutuhan verifikasi absensi karyawan.
abstract class LocationService {
  /// Memeriksa apakah fitur GPS perangkat aktif di tingkat sistem operasi
  Future<bool> isLocationEnabled();

  /// Mengecek status permission saat ini TANPA memunculkan dialog sistem.
  /// Digunakan untuk menentukan tampilan UI yang tepat sebelum meminta izin.
  Future<LocationPermissionStatus> checkPermissionStatus();

  /// Meminta persetujuan izin akses GPS dari pengguna (Location Permission Guard)
  Future<bool> requestPermission();

  /// Mengambil koordinat lintang (Latitude) dan bujur (Longitude) saat ini.
  /// Mengembalikan Map berisi kunci 'latitude' dan 'longitude'.
  Future<Map<String, double>> getCurrentLocation();

  /// Menghitung jarak lurus (meter) antara posisi saat ini dengan koordinat hotel
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  );

  /// Membuka halaman pengaturan lokasi OS untuk mengaktifkan GPS
  Future<void> openLocationSettings();

  /// Membuka halaman pengaturan app untuk mengelola permission yang ditolak permanen
  Future<void> openAppSettings();
}
