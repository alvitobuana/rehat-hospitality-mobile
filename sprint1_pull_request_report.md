# Laporan Pull Request - Sprint 1 (Foundation)
## Metadata
- **Project:** Rehat Housekeeping Mobile
- **Sprint Target:** Sprint 1 (Foundation)
- **Status:** Completed & Ready for Review
- **Author:** Lead Flutter Engineer & Senior Flutter Developer
- **Date:** 2026-07-09

---

## 1. Ringkasan Pekerjaan (Summary of Changes)

Pondasi dasar arsitektur Flutter untuk aplikasi `Rehat Housekeeping Mobile` telah selesai dibangun dan divalidasi. Seluruh konfigurasi perutean, manajemen status (*state management*), jaringan (*network client*), dan sistem tema premium telah terintegrasi dengan baik.

Dalam sprint ini, **kami tidak memprogram fitur bisnis seperti Login, Absensi, Dashboard, atau integrasi API transaksional**, melainkan fokus sepenuhnya pada kestabilan fondasi aplikasi.

---

## 2. Dependensi yang Ditambahkan (`pubspec.yaml`)

Pustaka inti berikut telah berhasil ditambahkan dan disinkronkan via `flutter pub get`:
- `flutter_riverpod` (^2.6.0) - Kontainer manajemen state.
- `go_router` (^14.2.0) - Navigasi deklaratif berbasis URL.
- `dio` (^5.5.0) - Klien HTTP untuk interaksi REST API.
- `cookie_jar` (^4.0.8) & `dio_cookie_manager` (^3.1.2) - Manajemen persistent cookie session PHP (`PHPSESSID`).
- `flutter_secure_storage` (^9.2.2) - Penyimpanan kunci enkripsi sensitif di tingkat OS.
- `hive_flutter` (^1.1.0) - Database NoSQL ringan untuk antrean offline mode.
- `shared_preferences` (^2.2.3) - Caching sederhana non-sensitif.
- `connectivity_plus` (^6.0.3) - Pendeteksi sinyal internet real-time.
- `logger` (^2.3.0) - Utilitas pencatatan log berformat rapi.
- `path_provider` (^2.1.3) - Memperoleh path direktori penyimpanan internal OS.

---

## 3. Berkas Fondasi yang Dibuat & Kegunaannya

Seluruh kode diletakkan pada struktur folder modular Feature-First di bawah `lib/core/` dan `lib/shared/`:

1. **`lib/core/constants/app_constants.dart`**
   - Menyimpan seluruh endpoints REST API (hasil reverse engineering backend `qa_web_rehat`) dan limitasi timeout.
2. **`lib/core/exceptions/app_failure.dart`**
   - Memetakan error HTTP (400, 401, 403, 404, 500, timeout, offline) menjadi model standardisasi `AppFailure` yang ramah bagi pengguna mobile.
3. **`lib/core/network/dio_client.dart`**
   - Mengonfigurasi singleton Dio dengan `PersistCookieJar` (mengarah ke folder dokumen aplikasi) untuk menjamin cookie sesi tetap aktif setelah aplikasi ditutup.
4. **`lib/core/router/app_router.dart`**
   - Menyediakan instance `GoRouter` beserta halaman placeholder untuk Splash, Login, dan Dashboard.
5. **`lib/core/storage/secure_storage_helper.dart`**
   - Wrapper enkripsi `FlutterSecureStorage` untuk memegang kunci AES database Hive secara aman di Keystore/Keychain.
6. **`lib/core/theme/app_theme.dart`**
   - Menghadirkan skema tema premium Light & Dark (Deep Indigo `#1A365D` & Warm Amber `#D69E2E`) menggunakan tipografi Google Fonts Inter.
7. **`lib/core/utils/env_config.dart`**
   - Kelas pemuat konfigurasi file JSON di runtime berdasarkan parameter Dart Define.
8. **Shared Widgets (`lib/shared/widgets/`)**
   - `custom_button.dart`: Tombol premium dengan indicator loading.
   - `loading_overlay.dart`: Layar transparan penghalang klik ganda (double-click prevention).
   - `state_widgets.dart`: Tampilan visual terstandar untuk Empty, Error, dan Success.
9. **`lib/main.dart`**
   - Titik masuk utama aplikasi yang menjamin penginisialisasian berurutan: Membaca Env JSON ➔ Membuat instance Cookie Jar ➔ Mengaktifkan Hive ➔ Membungkus ProviderScope ➔ Menjalankan MaterialApp.router.

---

## 4. Konfigurasi File Environment

Telah dibuat tiga berkas konfigurasi environment di direktori `config/` (dan didaftarkan dalam `assets:` di `pubspec.yaml`):
- `config/env_dev.json` (Menunjuk ke `http://localhost/qa_web_rehat`)
- `config/env_staging.json` (Menunjuk ke server testing staging)
- `config/env_prod.json` (Menunjuk ke server live production)

Aplikasi dapat dijalankan dengan memilih konfigurasi tertentu menggunakan perintah:
```bash
flutter run --dart-define=envConfigPath=config/env_dev.json
```

---

## 5. Hasil Validasi (Validation Results)

- **Instalasi Paket**: Sukses (`exit code: 0`).
- **Analisis Lints**: Menjalankan `flutter analyze` dan mengonfirmasi **0 compilation errors/warnings** di seluruh berkas baru yang dibuat (`lib/core` dan `lib/shared`).

---

## Mohon Ulasan & Persetujuan (Request for Review)
Pondasi ini siap digunakan. Silakan meninjau kode implementasi dan memberikan persetujuan sebelum kami melanjutkan ke **Sprint 2 (Fitur Login & Autentikasi)**.
