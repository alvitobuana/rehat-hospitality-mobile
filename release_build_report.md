# Release Build Report

**Project Name:** Rehat Housekeeping Mobile  
**Release Date:** 2026-07-10  
**Build Status:** 🟢 RELEASE BUILD SUCCESSFUL  

---

## 1. Executive Summary

Proses assembly build untuk versi rilis produksi (**v1.0.0+1**) dari Rehat Housekeeping Mobile telah berhasil dilaksanakan. Seluruh tahapan pengujian (UAT), perbaikan bug kritis, dan optimalisasi alur izin lokasi serta kamera telah terintegrasi penuh.

Build ini dikonfigurasi untuk terhubung langsung ke server backend produksi **Hostinger** melalui domain utama.

---

## 2. Flutter & Dart Environment

| Tools | Version | Channel / Revision |
|:---|:---|:---|
| **Flutter SDK** | `3.27.3` | Stable channel |
| **Dart SDK** | `3.6.1` | Stable |
| **DevTools** | `2.40.2` | Stable |
| **OS Platform** | Windows (x64) | Local build engine |

---

## 3. Android SDK & Build Configurations

* **Compile SDK Version:** `35` (Default SDK target)
* **Target SDK Version:** `35` (Google Play Store compliance)
* **Min SDK Version:** `21` (Android 5.0 Lollipop minimum)
* **Version Name:** `1.0.0`
* **Version Code:** `1`
* **Signing Configuration:** Debug signature key (siap untuk UAT internal dan instalasi manual via APK)

---

## 4. Build Commands

Dua jenis perakitan dilakukan untuk menghasilkan format distribusi yang efisien:

1. **Universal APK (All-in-One)**:
   ```bash
   flutter build apk --release --dart-define=envConfigPath=config/env_prod.json
   ```
2. **Split ABI APKs (Optimized)**:
   ```bash
   flutter build apk --release --split-per-abi --dart-define=envConfigPath=config/env_prod.json
   ```

---

## 5. Build Output & Artifacts

Semua berkas hasil build tersimpan di folder:
`build/app/outputs/flutter-apk/`

| File Name | Architecture Target | File Size (Bytes) | File Size (MB) |
|:---|:---|:---|:---|
| **`app-release.apk`** | Universal (v7a, v8a, x86_64) | `23,543,374` | **22.45 MB** |
| **`app-arm64-v8a-release.apk`** | Modern 64-bit ARM devices | `8,912,029` | **8.50 MB** |
| **`app-armeabi-v7a-release.apk`** | Legacy 32-bit ARM devices | `8,460,783` | **8.07 MB** |
| **`app-x86_64-release.apk`** | Emulator / x86_64 tablets | `9,052,567` | **8.63 MB** |

---

## 6. Release Checklist

| Item Checklist | Status | Detail Keterangan |
|:---|:---:|:---|
| ✓ App Name benar | **PASS** | Nama terdaftar `rehat_hk_mobile` / Rehat Housekeeping |
| ✓ App Icon benar | **PASS** | Default launcher icon tersemat di `@mipmap/ic_launcher` |
| ✓ Version Name benar | **PASS** | Menggunakan versi rilis `1.0.0` |
| ✓ Version Code benar | **PASS** | Menggunakan build number `1` (`1.0.0+1`) |
| ✓ Release Mode | **PASS** | Kompilasi tipe AOT `--release` tanpa VM Service |
| ✓ Bebas Dummy Data | **PASS** | Seluruh data operasional di dashboard/task list dimuat dari server live |
| ✓ Backend Production | **PASS** | Menggunakan `env_prod.json` mengarah ke `https://rehathotelsindonesia.com` |
| ✓ Debug Banner Hilang | **PASS** | Secara otomatis dimatikan dalam build release |
| ✓ Log Debug Bersih | **PASS** | Logging verbose level developer dinonaktifkan (`debug: false`) |
| ✓ `flutter analyze` Bersih | **PASS** | Analisis static code berhasil dilewati tanpa error |

---

## 7. Known Limitations

* **Debug Key Signature**: Berkas APK ini ditandatangani menggunakan kunci debug bawaan Flutter untuk mempermudah distribusi UAT internal. Jika ingin mengunggah ke Google Play Store, berkas harus ditandatangani menggunakan Production Key Keystore perusahaan (`upload-keystore.jks`).
* **Environment Dynamic Switch**: Konfigurasi domain terkunci secara statik pada saat kompilasi (`--dart-define`). Jika endpoint API berubah di masa depan, aplikasi harus dicompile ulang.

---

## 8. Final Release Status

# 🟢 RELEASE BUILD SUCCESSFUL

Aplikasi Rehat Housekeeping Mobile telah sukses dibuild dalam mode rilis produksi. Berkas APK universal dan split ABI telah siap didistribusikan untuk instalasi pengujian lapangan dan UAT tingkat akhir.
