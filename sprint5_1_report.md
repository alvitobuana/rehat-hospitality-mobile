# Sprint 5.1 Report: Dashboard Integration
## Rehat Housekeeping Mobile

- **Versi Proyek:** v0.6.1
- **Status Milestone:** ✅ COMPLETED (Selesai)
- **Target Integrasi API:** `/Housekeeping/api_get_dashboard.php`
- **Uji Integrasi Target:** Hostinger Live Server (`https://rehathotelsindonesia.com`)

---

## 1. Summary (Ringkasan)
Sprint 5.1 berhasil membuang seluruh alur kalkulasi counter tugas tiruan (dummy) dan mengintegrasikan widget counter pada Dashboard utama housekeeping dengan **Dashboard API Hostinger secara live**. 

Aplikasi mobile kini membaca session `user_id` dari `SessionManager` dan mengirimkan request ber-cookie melalui `DioClient` yang telah dikonfigurasi sebelumnya. Indikator loading berupa skeleton placeholder dirender selama data diproses oleh server, serta kegagalan otentikasi (401) secara otomatis memicu pembersihan sesi lokal dan melakukan navigasi pengalihan (*redirect*) ke layar Login utama.

---

## 2. Berkas Ditambahkan (File Added)
1. `lib/features/attendance/data/dashboard_summary.dart`
   - Berisi kelas model data `DashboardSummary` untuk counters: `pending`, `inProgress`, `completed`, dan `todayTotal` beserta parser `fromJson` dan `toJson`.
2. `lib/features/attendance/data/dashboard_repository.dart`
   - Kelas repositori untuk menangani pemanggilan data HTTP GET ke `/Housekeeping/api_get_dashboard.php` menggunakan global `DioClient`. Mengekspos `dashboardRepositoryProvider`.
3. `lib/features/attendance/presentation/dashboard_controller.dart`
   - Kelas pengontrol Riverpod `DashboardController` yang mewarisi `StateNotifier<AsyncValue<DashboardSummary>>` untuk mengelola transisi state: *Loading*, *Success*, dan *Error*. Mengekspos `dashboardControllerProvider` dan alias pintasan `dashboardSummaryProvider`.

---

## 3. Berkas Dimodifikasi (File Modified)
1. `lib/features/attendance/presentation/dashboard_screen.dart`
   - Menghapus logika penghitungan counter dummy.
   - Menghubungkan visual data counter ke provider reaktif `dashboardSummaryProvider`.
   - Mengintegrasikan `RefreshIndicator` (Pull-To-Refresh) untuk meng-invalidate session data dan memanggil `refreshSummary()` secara asinkron.
   - Menyematkan listener `ref.listen<AuthState>(authControllerProvider)` untuk mendeteksi *session expired* dan mengarahkan pengguna ke rute `/login`.
   - Menyematkan listener `ref.listen<AsyncValue>(dashboardSummaryProvider)` untuk menangkap error basis data/jaringan dan menampilkannya sebagai SnackBar merah.

---

## 4. Spesifikasi Integrasi API

### 4.1 Request Details
- **Endpoint:** `/Housekeeping/api_get_dashboard.php`
- **Method:** `GET`
- **Query Parameter:** `user_id` (diambil dinamis dari `SessionManager.getUserId()`)
- **Header:** `Cookie: PHPSESSID=...` (dilampirkan otomatis oleh interceptor)

### 4.2 Response JSON (Data Cocok)
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "pending": 1,
    "in_progress": 1,
    "completed": 1,
    "today_total": 3
  }
}
```

---

## 5. Lembar Uji Verifikasi (Testing Checklist)

| Kasus Uji | Langkah Skenario | Hasil yang Diharapkan | Status |
| :--- | :--- | :--- | :---: |
| **Pemuatan Counters** | Buka halaman Beranda setelah login | Counters menampilkan data real dari DB Hostinger (contoh: 1, 1, 1) | ✅ **PASS** |
| **Pull To Refresh** | Tarik halaman dashboard ke bawah, lalu lepaskan | Indikator berputar, memicu panggil ulang API, counters diperbarui | ✅ **PASS** |
| **Session Persistence** | Berpindah tab Beranda ➔ Tugas ➔ Profil ➔ Beranda | Cookie PHPSESSID tetap terlampir, dashboard tidak melakukan reload total | ✅ **PASS** |
| **Session Expired** | Hapus sesi lokal / pancing HTTP 401 | Aplikasi otomatis membersihkan data kredensial dan redirect ke `/login` | ✅ **PASS** |
| **Error Handling** | Matikan jaringan internet ponsel, lakukan refresh | Tampil SnackBar error merah: *"Dashboard: Kesalahan jaringan: ..."* | ✅ **PASS** |

---

## 6. Known Issues (Masalah Diketahui)
* Kartu tugas terdekat (*Tugas Terdekat*) di bagian bawah dashboard saat ini masih memuat data dummy dari `taskControllerProvider` karena modul Task List baru akan diintegrasikan di Sprint 5.2. Hal ini normal dan sudah sesuai batasan Sprint 5.1.

---

## 7. Rekomendasi Sprint 5.2
1. Hubungkan `taskControllerProvider` ke `/Housekeeping/api_list_tasks.php` untuk menampilkan daftar tugas real di bagian bawah dashboard dan halaman tab *"Tugas Saya"*.
2. Gunakan relasi data `task_id` bertipe integer yang sesuai dengan respons database.
