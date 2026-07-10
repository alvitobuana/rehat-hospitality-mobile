# Sprint 7.0 Report: User Registration & Admin Approval

**Project:** Rehat Housekeeping Mobile  
**Version:** v1.1.0  
**Phase:** Sprint 7.0 Delivery  
**Status:** ✅ COMPLETE & TESTED (E2E PASS 100%)

---

## 1. Executive Summary

Pada Sprint 7.0, kami telah berhasil mengimplementasikan sistem **Registrasi Pengguna Mandiri (Self-Registration) & Alur Persetujuan Admin (Admin Approval)** untuk aplikasi Rehat Housekeeping Mobile. 

Sebelumnya, seluruh akun staf harus dibuat secara manual oleh administrator langsung di database. Dengan implementasi Sprint 7.0:
1. Staf housekeeping dapat melakukan pendaftaran mandiri langsung dari aplikasi mobile dengan mengisi formulir lengkap.
2. Akun baru yang terdaftar akan berstatus `PENDING` dan **tidak dapat masuk (login)** sebelum disetujui oleh admin.
3. Administrator dapat menyetujui (`APPROVED`) atau menolak (`REJECTED`) pendaftaran melalui Supervisor Console (Admin Web).
4. Sesi dan Device Binding baru aktif sepenuhnya setelah status akun dirubah menjadi `APPROVED`.

Semua skenario pengujian E2E (End-to-End) telah berjalan sukses pada backend live Hostinger. Pengujian static analisis Flutter (`flutter analyze`) juga bersih tanpa error.

---

## 2. Database Changes

Kami telah menambahkan kolom status, metadata persetujuan, dan kolom profil baru ke tabel `users` di database remote MySQL Hostinger (`u735435275_rehat_hotel`):

| Nama Kolom | Tipe Data | Default | Keterangan |
|:---|:---|:---|:---|
| `full_name` | VARCHAR(100) | NULL | Nama lengkap staf housekeeping |
| `email` | VARCHAR(100) | NULL | Email unik staf (ditambahkan UNIQUE KEY) |
| `phone` | VARCHAR(20) | NULL | Nomor HP unik staf (ditambahkan UNIQUE KEY) |
| `department` | VARCHAR(50) | NULL | Departemen kerja (misal: Housekeeping) |
| `position` | VARCHAR(50) | NULL | Jabatan staf (Staff / Leader / Manager) |
| `employee_id` | VARCHAR(50) | NULL | Nomor induk karyawan (opsional) |
| `status` | VARCHAR(20) | `'PENDING'` | Status akun (`PENDING`, `APPROVED`, `REJECTED`) |
| `approved_by` | INT | NULL | ID Administrator yang menyetujui |
| `approved_at` | TIMESTAMP | NULL | Waktu persetujuan akun |
| `rejected_by` | INT | NULL | ID Administrator yang menolak |
| `rejected_at` | TIMESTAMP | NULL | Waktu penolakan akun |
| `rejection_reason` | TEXT | NULL | Catatan alasan penolakan admin |
| `updated_at` | TIMESTAMP | CURRENT_TIMESTAMP | Waktu pembaruan record secara otomatis |

*Catatan Migrasi*: Status akun staf lama (eksisting) yang terdaftar sebelum Sprint 7.0 secara otomatis dimigrasikan menjadi `APPROVED` agar operasional tidak terganggu.

---

## 3. API Endpoints

Berikut adalah daftar endpoint PHP baru yang diimplementasikan di folder root `public_html/` server Hostinger:

### A. Registrasi Mandiri
* **POST `/api_register.php`** (Public/Unauthenticated)
  * Menerima payload JSON: `full_name`, `email`, `phone`, `password`, `hotel_id`, `department`, `position`, `employee_id` (opsional), serta info perangkat (`device_id`, `device_model`, `os_version`, `app_version`).
  * Menyimpan user dengan status `PENDING` dan merekam data perangkat di `user_devices`.

### B. Cek Status Registrasi
* **GET `/api_registration_status.php?email=<email>`** (Public/Unauthenticated)
  * Mengambil status pendaftaran (`PENDING`, `APPROVED`, `REJECTED`) beserta alasan penolakan (jika ditolak).

### C. Persetujuan Admin
* **POST `/api_approve_user.php`** (Admin Session Required)
  * Menyetujui pendaftaran staf, merubah status menjadi `APPROVED`.
* **POST `/api_reject_user.php`** (Admin Session Required)
  * Menolak pendaftaran staf, merubah status menjadi `REJECTED`, dan mencatat alasan penolakan (`reason`).

### D. Perubahan Login
* **POST `/login.php`** (Modified)
  * Ditambahkan pengecekan status akun setelah validasi password. Mengembalikan pesan error terperinci jika status akun bernilai `PENDING` atau `REJECTED` (lengkap dengan alasan penolakan).

---

## 4. Flutter Screens & Architecture

Mengikuti Clean Architecture dan Repository Pattern yang ada di aplikasi, berikut adalah implementasi komponen Flutter:

### A. Data & Logic Layer:
* [auth_repository.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/data/auth_repository.dart): Menambahkan method `register` dan `checkRegistrationStatus`.
* [auth_controller.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/auth_controller.dart): Menambahkan method asinkron `register` untuk pengiriman form dan pengambilan status pendaftaran.

### B. UI Layer & Router:
* [app_router.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/router/app_router.dart): Menambahkan rute `/register` dan `/registration-success`.
* [login_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/login_screen.dart): Menambahkan link *"Belum punya akun? Daftar sekarang"* yang terhubung ke form registrasi.
* [register_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/register_screen.dart) **[NEW]**: Formulir pendaftaran mandiri dengan validasi form (email unik, password minimum 8 karakter, konfirmasi password cocok, dll.) menggunakan widget UI premium.
* [registration_success_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/registration_success_screen.dart) **[NEW]**: Tampilan sukses pendaftaran yang menginformasikan status akun saat ini (`PENDING` / `REJECTED` / `APPROVED`). Dilengkapi tombol refresh status real-time asinkron ke server.

---

## 5. Admin Pages

Kami memperbarui file supervisor console [rehat_housekeeping_admin.php](file:///d:/Rehat_Hospitality/qa_web_rehat/rehat_housekeeping_admin.php) di server Hostinger:
* **Penambahan Section Baru**: Tab *User Registration Approvals* diposisikan tepat di bawah tabel monitoring tugas housekeeping.
* **Tampilan 3 Kategori**:
  1. **Pending Users**: Daftar antrean staf baru yang meminta persetujuan. Admin dapat mengklik **Approve** langsung atau **Reject** dengan memasukkan alasan penolakan.
  2. **Approved Users**: Daftar staf yang sukses disetujui beserta nama administrator yang menyetujui.
  3. **Rejected Users**: Daftar pengajuan yang ditolak beserta alasan penolakan yang dicatat admin.
* **Interaktivitas Tanpa Refresh Lambat**: Dilengkapi tab switcher berbasis JavaScript vanilla ultra-responsif dan form penolakan inline.

---

## 6. Security Review

Sistem ini didesain dengan prinsip keamanan mobile & web modern:
1. **Password Hashing**: Menggunakan `password_hash($password, PASSWORD_BCRYPT)` untuk pengamanan kata sandi staf di database.
2. **Prepared Statements**: Seluruh SQL query di server menggunakan prepared statement PDO untuk mencegah celah *SQL Injection*.
3. **Session Guards**: Aksi menyetujui/menolak user dibatasi hanya untuk sesi admin yang tervalidasi (`$_SESSION['user_level'] === 'Admin'`).
4. **Rate Limiting**: Endpoint `/api_register.php` dibatasi per IP/Sesi menggunakan time-locking (jeda minimal 5 detik antarsubmit) untuk mencegah serangan bot spamming registrasi.
5. **Input Sanitation & Validation**: Validasi format email, nomor HP, kesesuaian sandi, serta pembatasan minimal 8 karakter di sisi frontend (Flutter) dan backend (PHP).

---

## 7. Testing Checklist (E2E Result)

Semua skenario pengujian fungsional berjalan **100% SUKSES** di server Hostinger (Simulasi E2E berhasil dijalankan otomatis):

- [x] Registrasi Akun Staf Baru berhasil (Data masuk database dengan status default `PENDING`).
- [x] Pencatatan spesifikasi device info pendaftar berhasil disimpan di `user_devices`.
- [x] Login diblokir untuk akun `PENDING` dengan pesan: *"Akun Anda sedang menunggu persetujuan Admin."*
- [x] Admin dapat melakukan **Approve** akun melalui Supervisor Console.
- [x] Akun yang berstatus `APPROVED` dapat login dengan lancar dan masuk ke dashboard.
- [x] Admin dapat melakukan **Reject** akun dengan menyertakan alasan penolakan.
- [x] Login diblokir untuk akun `REJECTED` dengan menampilkan alasan penolakan yang spesifik dari admin.

---

## 8. Future Improvements

1. **Email / SMS Notification**: Mengirim notifikasi otomatis ke email/no HP staf saat pengajuan akun disetujui atau ditolak oleh admin.
2. **2FA/OTP Validation**: Mengirimkan kode OTP satu kali setelah registrasi mandiri untuk memverifikasi keaslian nomor HP staf sebelum masuk antrean admin.
