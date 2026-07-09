# Sprint 4.2 Report: Attendance Integration
## Rehat Housekeeping Mobile

- **Versi Proyek:** v0.5.2
- **Status Milestone:** ✅ COMPLETED (Selesai)
- **Target Integrasi:** Hostinger Live Server (`https://rehathotelsindonesia.com`)
- **Penyelarasan API Contract:** `integration_contract_v1.md` (v1.1.0)
- **Preflight Audit Rujukan:** `attendance_preflight_report.md`

---

## 1. Summary (Ringkasan Eksekutif)
Sprint 4.2 berfokus pada penghapusan alur absensi koordinat palsu (dummy) dan menghubungkannya dengan API Absensi GPS real-time Hostinger. 

Aplikasi mobile kini membaca data lokasi perangkat secara langsung lewat **Geolocator**, mengirimkannya bersama parameter identitas sesi terenkripsi (`PHPSESSID`, `user_id`, `device_id`) ke server, dan menampilkan hasil penolakan (seperti di luar geofence/radius hotel) atau persetujuan check-in/out dengan benar.

---

## 2. Berkas Terubah (File Changes)

### File Modified (Berkas Dimodifikasi):
1. `lib/core/storage/session_manager.dart`
   - Menambahkan struktur `SessionData` dan `sessionDataProvider` untuk memfasilitasi pembacaan metadata sesi secara sinkron/reaktif di halaman UI.
2. `lib/features/attendance/data/attendance_repository.dart`
   - Menghubungkan metode `checkIn` dan `checkOut` ke endpoint live `/Housekeeping/api_check_in.php` dan `api_check_out.php` dengan payload terstruktur.
3. `lib/features/attendance/presentation/attendance_controller.dart`
   - Integrasi `SessionManager` untuk menyuntikkan ID Karyawan dan ID Perangkat dinamis ke repositori, serta pengaturan transisi state absensi.
4. `lib/features/attendance/presentation/dashboard_screen.dart`
   - Memasang `ref.listen` untuk penangkapan error SnackBar, visual `SuccessStateView` overlay, serta penggantian data tiruan greeting dengan data nama staf & properti hotel nyata dari secure storage.
5. `lib/features/profile/presentation/profile_view.dart`
   - Menggantikan nama profil, peran, lokasi properti hotel, dan parameter metadata perangkat keras tiruan dengan data reaktif sesi aktif.

---

## 3. Alur Absensi & Integrasi GPS (Flows)

### 3.1 Alur Absensi Kehadiran
```
Tap Tombol Absensi (Dashboard)
    ↓
Location Permission Guard (Memastikan izin GPS aktif)
    ↓
GPS Service Check (Memastikan hardware GPS menyala)
    ↓
Fetch Current Location (Mengambil koordinat Latitude & Longitude)
    ↓
Extract Session Data (user_id & device_id dari SessionManager)
    ↓
POST /Housekeeping/api_check_in.php (atau api_check_out.php)
    ↓
Backend Geofence & Database Validation
    ↓
    ├── [Success / 200] ➔ Simpan State Checked In ➔ Tampilkan Success Overlay
    └── [Failed / 400 / 401 / 500] ➔ Tangkap Error ➔ Tampilkan Pesan di SnackBar
```

### 3.2 Alur GPS Lokasi (Geolocator)
- **Akurasi Tinggi:** Menggunakan setelan akurasi `LocationAccuracy.high` untuk meminimalkan deviasi jarak di sekitar batas radius geofence hotel (150 meter).
- **Timeout Protection:** Pengambilan lokasi dibatasi timeout maksimal 10 detik guna mencegah aplikasi macet saat sinyal GPS lemah.

---

## 4. Spesifikasi Endpoint & Parameter Payload

### 4.1 Check-In Endpoint
- **URL:** `/Housekeeping/api_check_in.php`
- **Method:** `POST`
- **Payload:**
  ```json
  {
    "user_id": 5,
    "device_id": "HK-DEV-XXXX",
    "latitude": -6.91400000,
    "longitude": 107.60900000
  }
  ```

### 4.2 Check-Out Endpoint
- **URL:** `/Housekeeping/api_check_out.php`
- **Method:** `POST`
- **Payload:** Sama dengan Check-In.

---

## 5. Mekanisme Penanganan Error (Error Handling)

- **Di Luar Radius (Outside Geofence):** Server mengembalikan status 400 dengan pesan `"You are outside the hotel premises."`. Ditangkap oleh repositori dan ditampilkan sebagai SnackBar merah.
- **Sesi Expired / Tidak Valid (401):** Interceptor Dio mendeteksi kode 401, membersihkan sesi lokal, dan `GoRouter` secara reaktif memindahkan user kembali ke `/login`.
- **GPS Tidak Aktif / Izin Ditolak:** Aplikasi menangkap exception di tingkat lokal dan menampilkan pesan `"GPS Anda tidak aktif. Mohon hidupkan GPS ponsel."` atau `"Izin GPS ditolak."`.
- **Mode Offline (Tidak Ada Internet):** Menampilkan error `"Tidak ada koneksi internet. Silakan periksa jaringan Anda."`.

---

## 6. Hasil Pengujian Manual (Manual Testing Checklist)

| Kasus Uji | Langkah Skenario | Hasil yang Diharapkan | Status |
| :--- | :--- | :--- | :---: |
| **GPS Perangkat Mati** | Matikan GPS di pengaturan ponsel, tap "Check In" | Tampil SnackBar error: *"GPS Anda tidak aktif. Mohon hidupkan GPS ponsel."* | ✅ **PASS** |
| **Permission GPS Ditolak** | Tolak akses izin lokasi saat pop-up, tap "Check In" | Tampil SnackBar error: *"Izin GPS ditolak"* | ✅ **PASS** |
| **Di Luar Geofence** | Tap "Check In" pada jarak > 150m dari hotel Dago Sky | Tampil SnackBar error dari server: *"You are outside the hotel premises."* | ✅ **PASS** |
| **Double Check-In** | Tap "Check In" berturut-turut pada hari yang sama | Tampil SnackBar error dari server: *"Sudah melakukan check-in hari ini."* | ✅ **PASS** |
| **Sesi Kerja Habis (401)**| Server mengembalikan 401 Unauthorized | Pembersihan data secure storage dan kembali ke halaman Login | ✅ **PASS** |
| **Tidak Ada Koneksi** | Matikan paket data seluler & Wi-Fi, tap "Check In" | Tampil SnackBar error: *"Gagal mengirim data Check-In: Tidak ada koneksi internet."* | ✅ **PASS** |

---

## 7. Rekomendasi Sprint 5
1. **Pemisahan API Endpoint Modul Lain:** Untuk pengerjaan Sprint 5 (Dashboard, Tugas Kamar, Unggah Foto Audit, dan Riwayat Kerja), pastikan kontrak API diselesaikan terlebih dahulu oleh tim backend.
2. **Koordinat Hotel Tambahan:** Pastikan hotel-hotel properti lainnya selain `dagosky` di-seed koordinat lintang/bujurnya di database sebelum modul tugas diuji secara langsung oleh staf unit hotel lain.
