import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service_impl.dart';

/// Provider global untuk mengakses layanan GPS Location
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationServiceImpl();
});

/// Kontrak abstraksi layanan GPS/Lokasi untuk kebutuhan verifikasi absensi karyawan.
abstract class LocationService {
  /// Memeriksa apakah fitur GPS perangkat aktif di tingkat sistem operasi
  Future<bool> isLocationEnabled();

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
}
