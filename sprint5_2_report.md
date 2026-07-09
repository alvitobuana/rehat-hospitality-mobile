# Sprint 5.2 Report: Task List Integration
## Rehat Housekeeping Mobile

- **Versi Proyek:** v0.6.2
- **Status Milestone:** ✅ COMPLETED (Selesai)
- **Target Integrasi API:** `/Housekeeping/api_list_tasks.php`
- **Uji Integrasi Target:** Hostinger Live Server (`https://rehathotelsindonesia.com`)

---

## 1. Summary (Ringkasan)
Sprint 5.2 berhasil membuang daftar antrean tugas tiruan (mock dummy tasks) dan menyelaraskan Halaman Daftar Tugas & Beranda utama dengan **Task List API Hostinger secara live**.

Daftar tugas kini terintegrasi reaktif menggunakan Riverpod. Pengambilan antrean memanfaatkan session `user_id` yang tersimpan aman pada `SessionManager`. Urutan kartu penugasan dipetakan secara dinamis langsung dari pengurutan server (berdasarkan tingkat urgensi prioritas) tanpa manipulasi lokal. Jika antrean kosong, UI otomatis merender `EmptyStateView` agar pengguna mendapatkan feedback visual yang jelas.

---

## 2. Berkas Ditambahkan (File Added)
1. `lib/features/task/data/task_model.dart`
   - Berisi definisi data `TaskModel` untuk penugasan housekeeping: `taskId` (int), `roomNumber` (String), `floor` (String), `cleaningType` (String), `status` (String), dan `priority` (String) beserta parser serialisasi.
2. `lib/features/task/data/task_repository.dart`
   - Kelas repositori yang mengelola request HTTP GET asinkron ke `/Housekeeping/api_list_tasks.php`. Mengekspos `taskRepositoryProvider`.
3. `lib/features/task/presentation/task_list_controller.dart`
   - Kelas pengontrol Riverpod `TaskListController` yang mengawasi status list asinkron (`AsyncValue<List<TaskModel>>`) untuk menangani transisi state: *Loading*, *Success*, *Empty*, dan *Error*. Mengekspos `taskListProvider`.

---

## 3. Berkas Dimodifikasi (File Modified)
1. `lib/shared/widgets/task_card.dart`
   - Merefaktor input agar menerima `TaskModel` nyata. Menyesuaikan layout rendering kartu untuk menampilkan 5 parameter utama: Nomor Kamar, Lantai, Jenis Cleaning, Status, dan Priority (yang diwarnai dinamis sesuai bobot urgensinya).
2. `lib/features/task/presentation/task_list_view.dart`
   - Menghapus pembacaan data dummy antrean.
   - Mengikat widget secara reaktif ke `taskListProvider`.
   - Mengintegrasikan pull-to-refresh `RefreshIndicator` untuk memanggil asinkron `refreshActiveTasks()`.
   - Memrogram interaksi tap kartu untuk menavigasi ke halaman detail dengan melampirkan parameter ID integer (`/task-detail/${task.taskId}`).
3. `lib/features/attendance/presentation/dashboard_screen.dart`
   - Menghapus pembacaan controller dummy dan mengikat panel "Tugas Terdekat" di bagian bawah dashboard secara live ke `taskListProvider` (membatasi rendering maksimal 3 tugas teratas).
   - Membersihkan variabel `taskState` dan modul import task dummy yang sudah tidak terpakai.

---

## 4. Spesifikasi Integrasi API

### 4.1 Request Details
- **Endpoint:** `/Housekeeping/api_list_tasks.php`
- **Method:** `GET`
- **Query Parameter:** `user_id` (diambil dari secure storage via `SessionManager`)
- **Header:** `Cookie: PHPSESSID=...` (melampirkan cookie sesi terotentikasi)

### 4.2 Response JSON (Format Data Teruji)
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "task_id": 1,
      "room_number": "101",
      "floor": "1",
      "cleaning_type": "Check-out Cleaning",
      "status": "Pending",
      "priority": "High"
    },
    {
      "task_id": 2,
      "room_number": "102",
      "floor": "1",
      "cleaning_type": "Stayover Cleaning",
      "status": "In Progress",
      "priority": "Medium"
    }
  ]
}
```

---

## 5. Lembar Uji Verifikasi (Testing Checklist)

| Kasus Uji | Langkah Skenario | Hasil yang Diharapkan | Status |
| :--- | :--- | :--- | :---: |
| **Pemuatan Antrean** | Masuk ke tab "Tugas Saya" setelah login | Kartu tugas terisi data real dari Hostinger (Kamar 101, 102, dll) | ✅ **PASS** |
| **Daftar Urutan (Sorting)** | Periksa susunan kartu tugas | Tugas terurut otomatis berdasarkan prioritas dari server (Urgent/High ➔ Low) | ✅ **PASS** |
| **Pull To Refresh** | Tarik halaman tugas ke bawah, lalu lepaskan | Indikator memutar, memicu panggil ulang API, data diperbarui | ✅ **PASS** |
| **Empty State** | Log out dan login dengan staf yang tidak memiliki tugas kamar | Tampil ilustrasi `EmptyStateView` *"Antrean Tugas Kosong"* | ✅ **PASS** |
| **Navigasi ID Parameter** | Tap kartu kamar 101 | Aplikasi berpindah rute mengirimkan integer ID `1` ke detail | ✅ **PASS** |

---

## 6. Known Issues (Masalah Diketahui)
- Halaman detail tugas (`TaskDetailScreen`) saat ini menampilkan teks *"Tugas tidak ditemukan"* atau memuat data dummy lama karena integrasi detail baru akan ditangani pada Sprint 5.3. Hal ini wajar dan sudah sesuai dengan batasan pengerjaan Sprint 5.2.

---

## 7. Rekomendasi Sprint 5.3
1. Integrasikan detail tugas menggunakan endpoint `GET /Housekeeping/api_get_task.php?id={id}` untuk merender spesifikasi, deskripsi detail, serta daftar checklist interaktif.
2. Tambahkan logic *Start Task* (Pending ➔ In Progress) menggunakan endpoint `POST /Housekeeping/api_update_task.php` pada halaman detail.
