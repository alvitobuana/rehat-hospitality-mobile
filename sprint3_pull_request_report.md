# Laporan Pull Request - Sprint 3 (Housekeeping Experience)
## Metadata
- **Project:** Rehat Housekeeping Mobile
- **Sprint Target:** Sprint 3 (Housekeeping Experience)
- **Status:** Completed & Ready for Review
- **Author:** Lead Flutter Engineer & Mobile UI Architect
- **Date:** 2026-07-09

---

## 1. Ringkasan Pekerjaan (Summary)

Sprint 3 difokuskan pada pembangunan antarmuka pengguna final (UI Final / Design Freeze) untuk staf Housekeeping lapangan. Seluruh layar dirancang dengan gaya datar (flat design) Material 3 yang sederhana, stabil, dan cepat. Untuk mendukung fase integrasi backend berikutnya, kami menggunakan struktur data dummy lokal yang memiliki rancangan objek identik dengan respon API database PHP, sehingga pada Sprint 4 developer hanya perlu menukar sumber data (*Dummy* ➔ *REST API*).

---

## 2. Layar yang Selesai (Completed Screens)

1. **Dashboard**:
   - Menampilkan greeting staf, pintasan kartu kontrol absensi GPS, kotak ringkasan kuantitas tugas (Antrean, Dikerjakan, Selesai), dan list 3 tugas terdekat hari ini.
2. **My Tasks (Daftar Tugas Saya)**:
   - Halaman daftar lengkap seluruh penugasan kamar aktif yang ditugaskan kepada staf HK bersangkutan.
3. **History (Riwayat Tugas)**:
   - Daftar riwayat tugas kamar yang telah diselesaikan pada hari itu, lengkap dengan thumbnail foto bukti fisik kerja dan komentar penjelas.
4. **Profile (Profil Saya)**:
   - Halaman profil staf berisi nama, peran, nama hotel, versi aplikasi, registered device ID, dan tombol pintasan keluar akun (*Logout*).
5. **Task Detail (Detail Tugas)**:
   - Rincian kamar tamu (nomor kamar, lantai, jenis pembersihan), instruksi kerja, indikator rantai proses (Antrean ➔ Dikerjakan ➔ Selesai), dan tombol status dinamis.
6. **Take Proof Photo (Tangkapan Kamera Bukti)**:
   - Integrasi kamera perangkat untuk menjepret bukti fisik pengerjaan kamar selesai, halaman preview, dan input teks laporan hasil kerja.

---

## 3. Alur Navigasi Utama (Navigation Flow)

```
[Login/Auto-Login Sukses] 
           │
           ▼
 [Main Shell Navigation] ──► Mengatur 4 Tab bawah:
           │
           ├───► [Tab 1: Dashboard] 
           │            │ (klik Task Card)
           │            ▼
           │     [Task Detail] ──► (klik Mulai Kerja: status Pending ➔ In Progress)
           │            │ (klik Ambil Foto Selesai)
           │            ▼
           │     [Take Photo Screen] ──► (buka Kamera ➔ Preview ➔ simpan laporan ➔ status ➔ Completed)
           │            │ (Kembali otomatis)
           │            ▼
           │     [Dashboard / Tab 3: History (Tugas masuk daftar selesai & tampilkan foto bukti)]
           │
           ├───► [Tab 2: My Tasks] ──► (Sama seperti Dashboard: klik Task Card ➔ Detail ➔ Selesai)
           │
           ├───► [Tab 3: History] ──► (Klik item riwayat ➔ Lihat Detail dengan status Completed & bukti foto)
           │
           └───► [Tab 4: Profile] ──► (Klik Logout ➔ Clear Sesi lokal & server ➔ Redirect ke Login Form)
```

---

## 4. Komponen & Widget Bersama yang Dibuat (Shared Widgets)

- **`TaskCard`** (`lib/shared/widgets/task_card.dart`): Card flat dengan detail kamar, lantai, jenis pembersihan, instruksi singkat, batas waktu, dan lencana status.
- **`AttendanceCard`** (`lib/shared/widgets/attendance_card.dart`): Kartu kontrol check-in/out GPS karyawan.
- **`SectionHeader`** (`lib/shared/widgets/section_header.dart`): Judul sub-seksi datar dengan dukungan tombol aksi opsional.
- **`AppCard`** (`lib/shared/widgets/app_card.dart`): Kontainer dasar datar berlatar putih dengan border tipis kelabu tanpa bayangan.
- **`AppTextField`** (`lib/shared/widgets/app_text_field.dart`): Input input field.
- **`StatusBadge`** (`lib/shared/widgets/status_badge.dart`): Lencana warna penanda status.
- **`LoadingOverlay`** (`lib/shared/widgets/loading_overlay.dart`): Blocker aksi klik ganda.
- **`StateWidgets`** (`lib/shared/widgets/state_widgets.dart`): EmptyStateView, ErrorStateView, dan SuccessStateView.

---

## 5. Struktur Data Dummy (Dummy Data Structure)

Dibuat tiga berkas dummy di `lib/core/dummy/` yang mencerminkan skema database backend PHP:
1. **`dummy_user.dart`**: Profil user tunggal HK staff.
2. **`dummy_tasks.dart`**: Array tugas aktif (`initialDummyTasks`) bertipe `TaskItem`. Kolom `status` bernilai `'Pending'` atau `'In Progress'`.
3. **`dummy_history.dart`**: Array tugas selesai (`initialDummyHistory`) bertipe `TaskItem`. Kolom `status` bernilai `'Completed'` dengan isian `staffComment` dan jalur file path `localPhotoPath`.

---

## 6. Berkas yang Ditambah & Diubah

### 6.1 Berkas Baru (Added Files)
- [dummy_user.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/dummy/dummy_user.dart)
- [dummy_tasks.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/dummy/dummy_tasks.dart)
- [dummy_history.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/dummy/dummy_history.dart)
- [main_shell_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/attendance/presentation/main_shell_screen.dart)
- [dashboard_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/attendance/presentation/dashboard_screen.dart)
- [task_list_view.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/task/presentation/task_list_view.dart)
- [task_detail_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/task/presentation/task_detail_screen.dart)
- [take_photo_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/task/presentation/take_photo_screen.dart)
- [task_controller.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/task/presentation/task_controller.dart)
- [history_view.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/history/presentation/history_view.dart)
- [profile_view.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/profile/presentation/profile_view.dart)
- [section_header.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/shared/widgets/section_header.dart)
- [task_card.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/shared/widgets/task_card.dart)
- [attendance_card.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/shared/widgets/attendance_card.dart)

### 6.2 Berkas Diubah (Modified Files)
- [pubspec.yaml](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/pubspec.yaml)
- [app_router.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/router/app_router.dart)
- [app_card.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/shared/widgets/app_card.dart)
- [take_photo_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/task/presentation/take_photo_screen.dart)

---

## 7. Pengujian Checklist (Testing Checklist)

- [ ] **Tab Bar Bawah**: Transisi antar tab lancar (Beranda ➔ Tugas ➔ Riwayat ➔ Profil) tanpa lag rendering.
- [ ] **State Flow Pengerjaan Kamar**: 
  - Tugas berstatus *Pending* diklik ➔ Klik **Mulai Kerja** ➔ Status berubah *In Progress* secara real-time.
  - Tugas berstatus *In Progress* diklik ➔ Klik **Ambil Foto Bukti** ➔ Kamera simulator/perangkat aktif.
  - Setelah memotret ➔ Halaman preview tampil ➔ Isi komentar ➔ Klik **Simpan** ➔ Tugas berpindah ke tab *Riwayat* dan status terupdate *Completed*.
- [ ] **Validasi Bukti Foto**: Foto yang diambil dan komentar penjelas terender rapi di kotak bukti hasil kerja pada halaman detail tugas yang telah diselesaikan.
- [ ] **Logout Profil**: Tombol Logout di tab Profil membersihkan sesi dan me-redirect ke login form.

---

## 8. Rekomendasi untuk Sprint 4 (Sprint 4 Recommendations)

Karena layout visual (Design Freeze) dan penanganan navigasi telah dikunci pada Sprint 3 ini, Sprint 4 disarankan fokus pada:
1. **Pemasangan API Repository**: Mengganti instansiasi controller yang membaca dummy data menjadi memanggil HTTP REST API dari server PHP (`api_get_qa_history.php` dan `api_update_cap_status.php`).
2. **Konversi Foto ke Base64**: Menambahkan fungsi utilitas pengonversi file fisik lokal bukti pengerjaan (`localPhotoPath`) menjadi string base64 (`data:image/jpeg;base64,...`) sebelum diposting ke server.
3. **Penyelarasan ID Real**: Menyesuaikan parsing ID kamar tamu hasil input dinamis audit di server.
