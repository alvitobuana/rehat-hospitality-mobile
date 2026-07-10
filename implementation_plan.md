# Sprint 7.0 Implementation Plan: User Registration & Admin Approval

Sistem registrasi user mandiri yang memerlukan verifikasi dan persetujuan (approval) admin sebelum staf housekeeping dapat login dan menggunakan aplikasi.

## User Review Required

> [!IMPORTANT]
> **1. Keamanan & Penanganan Akun Lama**
> - Akun staf yang sudah terdaftar sebelumnya di database telah dimigrasikan statusnya secara langsung menjadi `APPROVED` untuk mencegah staf lama terkunci.
> - Saat registrasi baru, password akan di-hash menggunakan algoritma `PASSWORD_BCRYPT` (standar `password_hash` PHP) yang aman.
> 
> **2. Alur Device Binding**
> - Saat registrasi, aplikasi Flutter akan mengumpulkan ID Perangkat, Model Perangkat, Versi Android, dan Versi Aplikasi, lalu mengirimkannya ke backend PHP.
> - Namun, pengikatan perangkat (Device Binding) ini baru aktif sepenuhnya setelah status akun diubah menjadi `APPROVED` oleh Admin.

---

## Proposed Changes

### 1. Database MySQL (Hostinger Remote Database)

Kita menambahkan kolom baru pada tabel `users` untuk menampung data registrasi mandiri, status approval, dan metadata penolakan/persetujuan admin:
* `full_name` VARCHAR(100): Nama Lengkap staf.
* `email` VARCHAR(100) UNIQUE: Email staf (harus unik).
* `phone` VARCHAR(20) UNIQUE: Nomor handphone staf (harus unik).
* `department` VARCHAR(50): Departemen (misal: Housekeeping).
* `position` VARCHAR(50): Jabatan (misal: Staff, Leader, Manager).
* `employee_id` VARCHAR(50) NULL: ID Karyawan (opsional).
* `status` VARCHAR(20) DEFAULT 'PENDING': Status akun (`PENDING`, `APPROVED`, `REJECTED`).
* `approved_by` INT, `approved_at` TIMESTAMP: ID admin dan waktu persetujuan.
* `rejected_by` INT, `rejected_at` TIMESTAMP, `rejection_reason` TEXT: Detail penolakan admin.
* `updated_at` TIMESTAMP: Waktu update record.

*Note: Migrasi tabel database remote telah berhasil dijalankan via SSH di langkah pre-plan awal.*

---

### 2. Backend PHP (qa_web_rehat)

#### [NEW] [api_register.php](file:///d:/Rehat_Hospitality/qa_web_rehat/api_register.php)
* Menerima request `POST` untuk pendaftaran akun housekeeping baru.
* Validasi input: Nama, email unik, nomor HP unik, password (min 8 karakter), hotel valid, departemen, dan jabatan.
* Melakukan hash password dengan `password_hash($password, PASSWORD_BCRYPT)`.
* Memasukkan data ke tabel `users` dengan status default `PENDING`.
* Menyimpan detail device yang dikirim (`device_id`, `device_model`, `os_version`, `app_version`) ke tabel `user_devices` jika registrasi sukses.

#### [NEW] [api_registration_status.php](file:///d:/Rehat_Hospitality/qa_web_rehat/api_registration_status.php)
* Menerima request `GET` unauthenticated dengan parameter `email`.
* Mengambil status akun dari database untuk email tersebut dan mengembalikan status (`PENDING`, `APPROVED`, `REJECTED`), beserta `rejection_reason` jika ditolak.

#### [NEW] [api_approve_user.php](file:///d:/Rehat_Hospitality/qa_web_rehat/api_approve_user.php)
* Endpoint admin (memerlukan pengecekan sesi admin).
* Menerima parameter `user_id` untuk mengubah status user dari `PENDING` menjadi `APPROVED` dan mengisi metadata `approved_by` & `approved_at`.

#### [NEW] [api_reject_user.php](file:///d:/Rehat_Hospitality/qa_web_rehat/api_reject_user.php)
* Endpoint admin (memerlukan pengecekan sesi admin).
* Menerima parameter `user_id` dan `reason` untuk mengubah status user menjadi `REJECTED` dan mencatat detail penolakan.

#### [MODIFY] [login.php](file:///d:/Rehat_Hospitality/qa_web_rehat/login.php)
* Menambahkan pengecekan kolom `status` setelah password terverifikasi.
* Jika status = `PENDING`: Mengembalikan HTTP 400 dengan pesan: `"Akun Anda sedang menunggu persetujuan Admin."`
* Jika status = `REJECTED`: Mengembalikan HTTP 400 dengan pesan: `"Registrasi Anda ditolak: <alasan_penolakan>"`
* Jika status = `APPROVED`: Mengizinkan proses login berlanjut seperti biasa.

#### [MODIFY] [rehat_housekeeping_admin.php](file:///d:/Rehat_Hospitality/qa_web_rehat/rehat_housekeeping_admin.php)
* Menambahkan antarmuka visual baru "Registration Approvals" di bawah menu utama supervisor.
* Menampilkan daftar staf dengan filter/tab: **Pending Users**, **Approved Users**, dan **Rejected Users**.
* Tombol aksi **Approve** (mengaktifkan user) dan **Reject** (membuka modal/form isian alasan penolakan).
* Terintegrasi dengan query handler aksi POST approve/reject yang memproses database langsung.

---

### 3. Flutter App (rehat-hospitality-mobile)

#### [MODIFY] [auth_repository.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/data/auth_repository.dart)
* Menambahkan method `register` untuk mengirim formulir registrasi dan info perangkat ke `api_register.php`.
* Menambahkan method `checkRegistrationStatus(String email)` untuk memeriksa status akun dari `api_registration_status.php`.

#### [MODIFY] [auth_controller.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/auth_controller.dart)
* Menambahkan status otentikasi baru di `AuthStatus` (atau penanganan transisi state):
  * `registrationPending`: Mengarahkan ke layar sukses/menunggu persetujuan.
* Mengubah parser error di `login()` agar bisa menangani status PENDING dan REJECTED yang dikembalikan oleh `login.php`.

#### [MODIFY] [app_router.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/router/app_router.dart)
* Mendaftarkan rute baru:
  * `/register`: Layar formulir pendaftaran.
  * `/registration-success`: Layar sukses mendaftar (menampilkan status pending).

#### [MODIFY] [login_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/login_screen.dart)
* Menambahkan link/button *"Belum punya akun? Daftar di sini"* di bagian bawah card login untuk mengalihkan ke rute `/register`.

#### [NEW] [register_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/register_screen.dart)
* Formulir input registrasi yang indah dengan validasi frontend:
  * Nama Lengkap, Email, Nomor HP, Kata Sandi, Konfirmasi Kata Sandi, Hotel (Dropdown dari list hotel), Departemen, Jabatan, dan Employee ID (opsional).
  * Validasi panjang kata sandi, kesesuaian konfirmasi password, format email, dan field wajib diisi.

#### [NEW] [registration_success_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/registration_success_screen.dart)
* Layar yang menginformasikan bahwa registrasi berhasil dan status akun sedang `PENDING` menunggu persetujuan admin.
* Menyediakan tombol *"Cek Status Persetujuan"* untuk memanggil `api_registration_status.php`. Jika status sudah diubah oleh admin menjadi `APPROVED`, otomatis mengalihkan user ke Login Screen dengan indikasi sukses. Jika ditolak (`REJECTED`), menampilkan rincian alasan penolakan admin.

---

## Verification Plan

### Automated Tests
- Menjalankan `flutter analyze` untuk memastikan kode Flutter baru bersih dari error analisis statis.

### Manual Verification
1. **Registrasi Mandiri**: Mengisi formulir pendaftaran di aplikasi mobile menggunakan data testing baru (misal email `staf_baru@rehat.co.id`), memicu submit.
2. **Database Verification**: Memeriksa bahwa record tersimpan di database dengan status `PENDING` dan kolom device info terisi.
3. **Login Blocks**: Mencoba login dengan akun pending tersebut dan memverifikasi pesan *"Akun Anda sedang menunggu persetujuan Admin."* muncul.
4. **Admin Approval**: Membuka dashboard Admin Web `rehat_housekeeping_admin.php`, melihat user baru di bawah tab **Pending Users**, lalu mengklik **Approve**.
5. **Successful Login**: Mencoba login kembali dengan akun yang telah disetujui, memverifikasi login berhasil dan masuk ke dashboard.
6. **Admin Rejection**: Melakukan registrasi akun baru lain, melakukan **Reject** di dashboard Admin Web dengan memasukkan alasan penolakan, mencoba login kembali di HP, dan memverifikasi alasan penolakan admin tertampil dengan benar di layar.
