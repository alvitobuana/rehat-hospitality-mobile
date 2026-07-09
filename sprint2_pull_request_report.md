# Laporan Pull Request - Sprint 2 (Access Control & GPS Attendance)
## Metadata
- **Project:** Rehat Housekeeping Mobile
- **Sprint Target:** Sprint 2 (Access Control & GPS Attendance)
- **Status:** Completed & Ready for Review
- **Author:** Lead Flutter Engineer & Technical Lead
- **Date:** 2026-07-09

---

## 1. Ringkasan Pekerjaan (Summary)

Sprint 2 difokuskan pada pembangunan alur keamanan akses masuk staf (Login, Auto Login, Device Binding, Izin GPS) dan fitur absensi sederhana (Check-In & Check-Out) berbasis lokasi geolocator. Integrasi network menggunakan PHP Session Cookie (`PHPSESSID`) secara penuh tanpa menggunakan token JWT. Untuk API backend absensi dan device binding yang belum tersedia, kami menerapkan struktur abstraksi yang rapi dengan model Mock/TODO agar pengerjaan aplikasi Flutter tidak tertahan.

---

## 2. Fitur yang Selesai (Completed Features)

1. **Sesi Login & Auto Login**:
   - Autentikasi credential username + password yang terhubung langsung ke backend PHP.
   - Deteksi auto-login pada saat startup aplikasi menggunakan pengecekan sesi cookie (`api_auth_check.php`).
2. **Device Binding (Validasi Perangkat)**:
   - Integrasi `device_info_plus` dan `package_info_plus` untuk menangkap parameter hardware ID, model, OS version, dan build version.
   - Pembuatan screen perantara validasi pendaftaran dan kecocokan ID perangkat karyawan.
3. **GPS Permission & Tracking**:
   - Integrasi `geolocator` untuk verifikasi GPS aktif dan persetujuan perizinan akses lokasi perangkat.
   - Perekaman koordinat Latitude dan Longitude secara real-time.
4. **Attendance Flow (Absensi)**:
   - Tombol interaktif Check-In dan Check-Out pada dashboard placeholder.
   - Animasi transisi overlay loading dan dialog sukses absensi.

---

## 3. Alur Logika (Operational Flows)

### 3.1 Alur Sesi Masuk (Login & Auto Login Flow)
```
[Startup / Splash] 
       │
       ▼
(Auto Login Check: Cek Cookie lokal ke api_auth_check.php)
       │
       ├───► [GAGAL / EXPIRED] ──► [Form Login Screen] ──► (POST username/password) 
       │                                                          │
       └───► [SUKSES / VALID] ────────────────────────────────────┘
                                   │
                                   ▼
                       (Cek Device Binding)
                                   │
                                   ├───► [BELUM TERIKAT] ──► [Device Binding Screen] ──► (Ikat Perangkat)
                                   │                                                            │
                                   └───► [SUDAH TERIKAT] ───────────────────────────────────────┘
                                               │
                                               ▼
                                      (Cek Izin GPS & Aktif)
                                               │
                                               ├───► [TIDAK AKTIF / TOLAK] ──► [GPS Permission Screen]
                                               │                                         │
                                               └───► [AKTIF & DISETUJUI] ────────────────┘
                                                           │
                                                           ▼
                                               [Dashboard Placeholder]
```

### 3.2 Alur Absensi (Attendance Flow)
```
[Dashboard Placeholder] 
       │
       ├─► [Tombol Check In] (Aktif jika Status = Checked Out)
       │         │
       │         ▼
       │   (Ambil GPS & Device ID) ──► (Kirim payload checkIn ke Repository)
       │         │
       │         ▼
       │   [Loading Overlay] ──► [Success Overlay (2 detik)] ──► [Update Status: Checked In]
       │
       └─► [Tombol Check Out] (Aktif jika Status = Checked In)
                 │
                 ▼
           (Ambil GPS & Device ID) ──► (Kirim payload checkOut ke Repository)
                 │
                 ▼
           [Loading Overlay] ──► [Success Overlay (2 detik)] ──► [Update Status: Checked Out]
```

---

## 4. Perubahan Berkas Kode (File Changes)

### 4.1 Berkas Baru yang Ditambahkan (Files Created)
- **`lib/core/device/device_service_impl.dart`**: Implementasi sensor detail perangkat.
- **`lib/core/location/location_service_impl.dart`**: Implementasi penangkap koordinat lokasi GPS.
- **`lib/features/auth/data/auth_repository.dart`**: Network handler untuk login, session verify, dan logout.
- **`lib/features/auth/presentation/auth_controller.dart`**: Pengatur state mesin otentikasi.
- **`lib/features/auth/presentation/login_screen.dart`**: Form login.
- **`lib/features/auth/presentation/device_binding_screen.dart`**: Layar pendaftaran device binding.
- **`lib/features/auth/presentation/gps_permission_screen.dart`**: Layar perizinan lokasi GPS.
- **`lib/features/attendance/data/attendance_repository.dart`**: Payload absensi (Check-In/Out) dengan penanda TODO backend.
- **`lib/features/attendance/presentation/attendance_controller.dart`**: Pengatur state Check-In / Check-Out.
- **`lib/features/attendance/presentation/dashboard_placeholder_screen.dart`**: UI dashboard sederhana absensi.

### 4.2 Berkas yang Diubah (Files Modified)
- **`pubspec.yaml`**: Penambahan package `geolocator`, `device_info_plus`, dan `package_info_plus`.
- **`lib/core/device/device_service.dart`**: Menghubungkan provider ke concrete impl.
- **`lib/core/location/location_service.dart`**: Menghubungkan provider ke concrete impl.
- **`lib/core/router/app_router.dart`**: Integrasi SplashScreen, LoginScreen, DeviceBindingScreen, GpsPermissionScreen, dan DashboardPlaceholderScreen ke GoRouter.

---

## 5. Integrasi API (API Status Mapping)

### 5.1 API yang Digunakan Aktif (Active APIs)
1. **POST `/Core_system_Auth/login.php`**
   - Payload: `username` & `password`
   - Fungsi: Otentikasi credential dan pertukaran session ID.
2. **GET `/Access_management/api_auth_check.php`**
   - Fungsi: Validasi keaktifan cookie PHPSESSID lokal (Auto Login check).
3. **GET `/Core_system_Auth/logout.php`**
   - Fungsi: Reset session cookie di server.

### 5.2 API yang masih TODO (Mocked on Client - Awaiting Backend Implementation)
1. **GET `/Housekeeping/api_check_device_binding.php?user_id={userId}&device_id={deviceId}`**
   - *Fungsi*: Memeriksa status kecocokan device binding di database hotel.
2. **POST `/Housekeeping/api_bind_device.php`**
   - *Fungsi*: Mendaftarkan ID perangkat baru untuk diikat ke akun karyawan.
3. **POST `/Housekeeping/api_check_in.php`**
   - *Payload*: `{"latitude": double, "longitude": double, "device_id": String}`
   - *Fungsi*: Pengiriman koordinat Check-In staf HK untuk dihitung radiusnya di server.
4. **POST `/Housekeeping/api_check_out.php`**
   - *Payload*: `{"latitude": double, "longitude": double, "device_id": String}`
   - *Fungsi*: Pengiriman koordinat Check-Out staf HK.

---

## 6. Testing Checklist (Rencana Pengujian Manual)

- [ ] **Sesi Login**: Memasukkan username/password salah menampilkan SnackBar error dari server. Memasukkan credential benar berhasil login.
- [ ] **Auto Login**: Setelah login sukses, tutup paksa aplikasi lalu buka kembali. Aplikasi melewati Splash Screen dan langsung masuk ke Dashboard tanpa meminta login ulang.
- [ ] **Logout**: Menekan ikon Logout di pojok kanan atas Dashboard menghapus cookie lokal, memutuskan koneksi sesi di server, dan me-redirect paksa kembali ke form Login.
- [ ] **Izin GPS**: Menolak izin lokasi pada GPS Permission Screen menahan user di layar tersebut. Menyalakan GPS dan memberikan izin sukses me-redirect ke Dashboard.
- [ ] **Verifikasi Koordinat**: Melakukan Check-In / Check-Out mencetak log Latitude & Longitude perangkat secara akurat di konsol debugging Flutter.

---

## 7. Batasan & Rekomendasi (Limitations & Recommendations)

### Batasan Sistem Saat Ini (Known Limitations)
- **Simulasi API**: Fitur absensi (Check-In/Out) dan validasi pengikatan perangkat (Device Binding) masih bersifat simulatif (client-side mocking) dikarenakan backend PHP belum menyediakan tabel dan endpoint yang bersangkutan.
- **Deteksi Mock Location**: Aplikasi belum memfilter atau menolak pembacaan lokasi palsu (Fake GPS) dari aplikasi pihak ketiga (Mock Location).

### Rekomendasi untuk Sprint 3 (Sprint 3 Recommendations)
1. **Integrasi Nyata API Absensi**: Menghubungkan fungsionalitas Check-In dan Check-Out ke endpoint backend PHP setelah database absensi di-deploy.
2. **Task Board (My Tasks)**: Membangun modul penugasan pembersihan kamar (My Tasks) yang bersumber dari API CAP (`api_get_qa_history.php`).
3. **Status Kamar**: Menampilkan data detail daftar kamar hotel yang diaudit.
