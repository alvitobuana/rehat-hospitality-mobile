# Laporan Sprint 1.1 Foundation Refinement
## Metadata
- **Project:** Rehat Housekeeping Mobile
- **Sprint Target:** Sprint 1.1 (Foundation Refinement)
- **Status:** Completed & Ready for Review
- **Author:** Lead Flutter Engineer & Mobile Architect
- **Date:** 2026-07-09

---

## 1. Ringkasan Pekerjaan (Summary)

Sprint 1.1 difokuskan pada penyederhanaan dan pematangan fondasi aplikasi sesuai dengan arahan keputusan stakeholder terbaru. Aplikasi dirancang agar **sederhana, stabil, dan cepat** khusus untuk staf Housekeeping. Kami membersihkan fitur-fitur tingkat perusahaan (*enterprise*) yang belum dibutuhkan (seperti mode offline Hive database dan font eksternal Google Fonts) dan meletakkan abstraksi layanan untuk pengerjaan absensi (GPS dan Device Binding) pada sprint berikutnya.

---

## 2. Dependensi yang Dihapus (Dependencies Removed)

Pustaka-pustaka berikut telah dihapus dari `pubspec.yaml` dan dicopot dari proyek Flutter:
1. **`hive_flutter` & `hive`**
   - *Alasan*: Offline Mode belum menjadi MVP untuk fase rilis pertama. Menghapus database lokal NoSQL menyederhanakan siklus bootstrap start-up dan memangkas ukuran biner aplikasi.
2. **`google_fonts`**
   - *Alasan*: Menghindari query font eksternal HTTP di jaringan hotel yang berpotensi lambat. Menggunakan font bawaan sistem OS ponsel (default Flutter) memprioritaskan performa rendering teks instan.

---

## 3. Berkas yang Ditambahkan (Files Created)

1. **`lib/core/device/device_info.dart`**
   - Model representasi detail perangkat fisik (ID, Model, OS Version) untuk keperluan Device Binding.
2. **`lib/core/device/device_service.dart`**
   - Interface kontrak abstraksi Device Binding. Menyediakan tanda tangan fungsi check binding dan registration binding ke REST API.
3. **`lib/core/location/location_service.dart`**
   - Interface kontrak abstraksi GPS Location. Menyediakan fungsi izin GPS, koordinat lintang/bujur saat ini, dan kalkulator jarak lurus radius absensi hotel.
4. **`lib/features/attendance/README.md`**
   - Berkas placeholder penanda struktur folder untuk implementasi modul absensi.
5. **Shared Widgets (`lib/shared/widgets/`)**:
   - **`app_card.dart`**: Kontainer flat dengan border tipis tanpa elevasi bayangan tebal.
   - **`app_text_field.dart`**: Bidang input teks flat modular lengkap dengan validasi.
   - **`status_badge.dart`**: Lencana status datar semi-transparan dengan visualisasi warna datar (Success Green, Warning Orange, Danger Red, Info Blue).

---

## 4. Berkas yang Diubah (Files Modified)

1. **`pubspec.yaml`**
   - Pencopotan dependensi `hive_flutter` dan `google_fonts`.
2. **`lib/main.dart`**
   - Pembersihan impor `hive_flutter` dan penghapusan kode inisialisasi database `Hive.initFlutter()` untuk boot-up yang lebih ringan.
3. **`lib/core/storage/secure_storage_helper.dart`**
   - Pembersihan fungsi generator dan penyimpanan kunci enkripsi AES Hive. Secure Storage kini murni digunakan untuk sesi login.
4. **`lib/core/theme/app_theme.dart`**
   - Penggantian setelan tipografi `GoogleFonts` menjadi font standar sistem. Penyederhanaan warna tema datar (Blue, Green, Orange, Red, White, Dark Grey).
5. **`lib/theme/app_theme.dart` (Prototype Theme)**
   - Pembersihan impor `google_fonts` dan refactoring agar seluruh layar prototipe lama dapat langsung berkompilasi lancar dengan font sistem standar.
6. **`lib/screens/login_screen.dart`**
   - Refactor pembersihan impor `google_fonts` dan penggantian gaya `GoogleFonts.plusJakartaSans` menjadi `TextStyle`.

---

## 5. Checklist Validasi Arsitektur

- [x] **Compile State**: Berhasil dikompilasi dengan **0 errors** di seluruh proyek (melalui pemeriksaan `flutter analyze`).
- [x] **Package Cleanliness**: Bersih dari pustaka Hive dan Google Fonts.
- [x] **Abstraksi GPS & Device**: Abstraksi `LocationService` dan `DeviceService` siap diinjeksikan.
- [x] **Attendance Placeholder**: Folder `features/attendance/` terbentuk.
- [x] **Simplified Widgets**: UI Card, Input Field, dan Status Badge datar siap dipakai.

---

## 6. Rekomendasi untuk Sprint 2 (Sprint 2 Recommendations)

Dengan siapnya fondasi sederhana Sprint 1.1 ini, kami menyarankan fokus Sprint 2 diarahkan pada:
1. **Fitur Login**: Integrasi dengan cookie session PHP (`PHPSESSID`) menggunakan network layer Dio Client.
2. **Implementasi Device Service**: Mengisi `DeviceService` menggunakan package `device_info_plus` untuk merealisasikan pendaftaran Device Binding.
3. **Implementasi Location Service**: Mengisi `LocationService` menggunakan package `geolocator` untuk menangkap koordinat GPS staf.
4. **Attendance Flow**: Menghubungkan Login ➔ Verifikasi Device Binding ➔ Cek Izin GPS & Radius Hotel ➔ Eksekusi Absensi Masuk/Pulang.
