# Sprint 4.1 Report: Authentication & Device Integration
## Rehat Housekeeping Mobile

- **Versi Proyek:** v0.5.1
- **Status Milestone:** ✅ COMPLETED (Selesai)
- **Target Integrasi:** Hostinger Live Server (`https://rehathotelsindonesia.com`)
- **Penyelarasan API Contract:** `integration_contract_v1.md` (v1.1.0)

---

## 1. Summary (Ringkasan Eksekutif)
Sprint 4.1 berfokus pada penghapusan alur autentikasi dan device-binding tiruan (dummy) pada aplikasi mobile, serta menggantinya dengan integrasi langsung (*live integration*) ke server Hostinger. 

Seluruh mekanisme penyimpanan sesi aman menggunakan **Flutter Secure Storage**, manajemen cookie `PHPSESSID` dinamis via **Dio Interceptor**, serta rantai validasi keamanan (Cek Sesi ➔ Cek Device ➔ Izin GPS ➔ Dashboard) telah berjalan 100% menggunakan data backend nyata.

---

## 2. File Changes (Daftar Berkas Terubah)

### File Added (Berkas Baru):
1. `lib/core/storage/session_manager.dart`
   - Mengelola read, write, dan clear data sesi secara aman di secure storage.
2. `lib/features/auth/data/device_repository.dart`
   - Repository baru untuk memanggil endpoint validasi dan registrasi device binding.

### File Modified (Berkas Dimodifikasi):
1. `config/env_dev.json`
   - Mengubah `baseUrl` ke `https://rehathotelsindonesia.com`.
2. `lib/core/constants/app_constants.dart`
   - Memperbarui path login, check session, dan logout ke root server, serta mendaftarkan path device.
3. `lib/core/network/dio_client.dart`
   - Menambahkan `SessionInterceptor` untuk injeksi cookie dan auto-save cookie, serta pembersihan sesi pada error 401.
4. `lib/main.dart`
   - Inisialisasi dan override `SessionManager` ke dalam kontainer Riverpod global.
5. `lib/core/device/device_service.dart` & `device_service_impl.dart`
   - Menghubungkan layanan cek status device dan binding device fisik ke `DeviceRepository`.
6. `lib/features/auth/presentation/auth_controller.dart`
   - Mengintegrasikan penyimpanan sesi `SessionManager` ke dalam alur login dan auto-login aplikasi.
7. `lib/features/auth/data/auth_repository.dart`
   - Pemutakhiran komentar teknis pengembalian `user_id`.

---

## 3. Alur Sistem (System Flows)

### 3.1 Flow Login & Auto-Login
```
Splash Screen
    ↓
Check Auto-Login (SessionManager.getPhpSessionId)
    ↓
    ├── [Tidak Ada] ➔ Redirect ke Login Screen
    └── [Ada] ➔ GET /api_auth_check.php
              ├── [Sesi Expired/401] ➔ Clear Storage ➔ Redirect ke Login Screen
              └── [Sesi Aktif/200] ➔ Update Session ➔ Lanjut ke Device Binding Flow
```

### 3.2 Flow Device Binding
```
Validate Device (POST /Housekeeping/api_validate_device.php)
    ↓
    ├── [registered == true] ➔ Lanjut ke Izin GPS ➔ Dashboard
    └── [registered == false] ➔ Tampilkan Halaman Ikat Perangkat
                              ➔ Tap tombol "Ikat Perangkat"
                              ➔ POST /Housekeeping/api_register_device.php
                              ➔ Sukses ➔ Lanjut ke Izin GPS ➔ Dashboard
```

---

## 4. Spesifikasi Teknis Integrasi

### Endpoint yang Digunakan:
| No | Endpoint | HTTP Method | Keterangan |
| :-: | :--- | :---: | :--- |
| 1 | `/login.php` | `POST` | Login user & inisiasi session cookie |
| 2 | `/api_auth_check.php` | `GET` | Verifikasi status keaktifan session |
| 3 | `/Housekeeping/api_validate_device.php` | `POST` | Validasi kecocokan device binding |
| 4 | `/Housekeeping/api_register_device.php` | `POST` | Registrasi device binding baru |
| 5 | `/logout.php` | `GET` | Penghancuran session di server |

### Storage Keys (Flutter Secure Storage):
- `php_sess_id`: Menyimpan nilai cookie `PHPSESSID`.
- `user_id`: Menyimpan ID Karyawan (integer) untuk request absensi.
- `username`: Menyimpan nama panggul staf.
- `user_role`: Menyimpan hak akses modul (`admin`, `housekeeping`, dll).
- `user_level`: Menyimpan level otorisasi.
- `device_id`: Menyimpan pengidentifikasi unik ponsel saat ini.

### Error Handling:
- **401 (Unauthorized):** Dihandle oleh `SessionInterceptor`. Sesi lokal dibersihkan otomatis, `AuthController` berganti status ke `unauthenticated`, dan router mengarahkan user kembali ke form login.
- **403 (Forbidden):** Memunculkan pesan penolakan otorisasi akun.
- **400 (Bad Request):** Menguraikan pesan error dari server (misal: "Username and password are required" atau "Account already bound to another device").
- **500 (Internal Server Error):** Mengembalikan kesalahan database server.
- **No Internet / Timeout:** Menampilkan notifikasi kesalahan jaringan.

---

## 5. Testing & Verification Checklist

| Kriteria Done | Status | Hasil Pengujian |
| :--- | :---: | :--- |
| Login menggunakan backend Hostinger | ✅ **PASS** | Berhasil masuk menggunakan akun `admin` / `password123`. |
| PHPSESSID berhasil disimpan | ✅ **PASS** | `PHPSESSID` terekstrak dari header `Set-Cookie` dan tersimpan di Secure Storage. |
| user_id berhasil disimpan | ✅ **PASS** | ID integer berhasil ditangkap dan disimpan dari respons sukses. |
| Auto Login berhasil | ✅ **PASS** | Aplikasi berhasil mem-bypass form login setelah ditutup dan dibuka kembali. |
| Logout berhasil | ✅ **PASS** | Menghapus seluruh cookies di server dan secure storage lokal secara bersih. |
| Validate Device berhasil | ✅ **PASS** | Membedakan respon `registered: true` dan `registered: false`. |
| Register Device berhasil | ✅ **PASS** | Menyimpan relasi user-device dengan benar di tabel `user_devices` Hostinger. |
| Tidak ada perubahan UI | ✅ **PASS** | Layout, navigasi GoRouter, dan visual desain Sprint 3 terjaga utuh. |

---

## 6. Known Issues (Kendala yang Diketahui)
- **Status Hotel ID User Test:** User `admin` (id: 1) di database live memiliki `hotel_id = NULL`. Hal ini akan menyebabkan error `"User is not assigned to any hotel"` saat pengujian check-in absensi dilakukan. Ini normal untuk akun admin global, namun **wajib** dibuatkan user test khusus housekeeping yang sudah terasosiasi dengan hotel untuk Sprint 4.2.

---

## 7. Rekomendasi Sprint 4.2 (Attendance Integration)
1. **User Test Seeding:** Lakukan koordinasi dengan tim backend untuk menyiapkan kredensial karyawan housekeeping riil (misal: `hk_staff` / `password123`) yang memiliki `hotel_id = 1` dengan koordinat lintang/bujur hotel yang valid di tabel `revenue_properties`.
2. **Attendance Repositories:** Mulai implementasikan integrasi pemanggilan REST API absensi sesungguhnya pada `AttendanceRepository` menggunakan endpoint `/Housekeeping/api_check_in.php` dan `/Housekeeping/api_check_out.php`.
