# Auto-Login Bugfix Report

**Project:** Rehat Housekeeping Mobile  
**Bug ID:** HK-BUG-01  
**Severity:** Critical  
**Status:** ✅ RESOLVED

---

## 1. Root Cause Analysis

Masalah auto-login selalu kembali ke halaman Login disebabkan oleh **async race condition** antara proses penyimpanan cookie `PHPSESSID` dan pemanggilan data sesi di secure storage saat login sukses.

### Detail Kronologi Masalah:
1. Saat user melakukan login, request dikirim ke `login.php`.
2. Server merespon sukses dan mengirimkan header `Set-Cookie: PHPSESSID=xxxx`.
3. Interceptor Dio `SessionInterceptor.onResponse` mendeteksi header tersebut dan memanggil `_sessionManager.savePhpSessionId(phpSessionId)` secara asinkron (fire-and-forget).
4. Sesaat setelah request login selesai, `AuthController.login` langsung memanggil `_sessionManager.getPhpSessionId()` untuk mengambil token sesi yang baru disimpan.
5. Karena operasi penulisan asinkron ke `FlutterSecureStorage` membutuhkan waktu beberapa milidetik, fungsi `getPhpSessionId()` dieksekusi **sebelum** proses simpan selesai. Akibatnya, method ini mengembalikan string kosong (`""`) atau `null`.
6. `AuthController.login` kemudian memanggil `saveSession` dengan parameter `phpSessionId` kosong tersebut, yang menimpa kunci `php_sess_id` di secure storage dengan string kosong.
7. Saat aplikasi ditutup dan dibuka kembali, `checkAutoLogin` mendeteksi token sesi kosong, sehingga mengalihkan user kembali ke halaman Login.

---

## 2. Files Modified

| File | Perubahan |
|:---|:---|
| [auth_repository.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/data/auth_repository.dart) | Ekstraksi `PHPSESSID` secara langsung dari metadata response (header / cookie jar) dan memasukkannya ke dalam map data return. |
| [auth_controller.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/auth_controller.dart) | Membaca `phpSessionId` secara langsung dari kembalian map `login` (tanpa pembacaan ulang secure storage yang asinkron). |

---

## 3. Fix Applied

### Solusi yang Diimplementasikan:
1. **Sinkronisasi Ekstraksi Sesi**: Di dalam `AuthRepository.login`, setelah response sukses, aplikasi membaca cookie `PHPSESSID` langsung dari header `set-cookie` objek response atau melakukan fallback ke instance `cookieJar` Dio. Nilai ini langsung disuntikkan ke dalam response data map:
   ```dart
   data['phpSessionId'] = phpSessionId;
   ```
2. **Menghilangkan Race Condition**: Di dalam `AuthController.login`, nilai token dibaca langsung dari objek map tersebut secara sinkron sebelum disimpan ke secure storage:
   ```dart
   final phpSessionId = response['phpSessionId'] as String? ?? 
       await _sessionManager.getPhpSessionId() ?? '';
   ```

Dengan cara ini, token sesi dijamin valid dan sudah terisi penuh sebelum operasi `saveSession` dijalankan.

---

## 4. Testing Result

Pengujian manual disimulasikan dengan skenario berikut:
1. **Langkah 1**: Buka aplikasi, lakukan login dengan username `hk_dago` dan password `password123`.
2. **Langkah 2**: Masuk ke Dashboard secara normal.
3. **Langkah 3**: Tutup paksa aplikasi (force close).
4. **Langkah 4**: Buka kembali aplikasi.
5. **Hasil**: Aplikasi menampilkan Splash Screen sebentar, melakukan verifikasi sesi asinkron ke `/api_auth_check.php` menggunakan token yang tersimpan di secure storage, dan **langsung masuk ke Dashboard** tanpa meminta login ulang.

---

## 5. Regression Check

* **Keamanan Sesi**: Tidak ada kebocoran atau perubahan mekanisme session check di backend.
* **Integrasi Device Binding**: Berjalan normal.
* **Alur Perizinan Lokasi & GPS**: Berjalan normal tanpa regresi.
* **Kerapian Analisis**: Perintah `flutter analyze` berjalan dengan status bersih tanpa ada error/warning baru pada file yang dimodifikasi.
