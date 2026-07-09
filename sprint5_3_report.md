# Sprint 5.3 Report: Task Detail Integration
## Rehat Housekeeping Mobile

- **Versi Proyek:** v0.6.3
- **Status Milestone:** ✅ COMPLETED (Selesai)
- **Target Integrasi API:** `/Housekeeping/api_get_task.php?id={task_id}`
- **Uji Integrasi Target:** Hostinger Live Server (`https://rehathotelsindonesia.com`)

---

## 1. Summary (Ringkasan)
Sprint 5.3 berhasil membuang seluruh detail penugasan tiruan (dummy task details) dan menghubungkan Halaman Detail Tugas dengan **Task Detail & Checklist API Hostinger secara live**.

Halaman detail kini menerima parameter navigasi `task_id` integer hasil dari tap kartu tugas Sprint 5.2. Data spesifikasi ruangan, tanggal dibuat, instruksi khusus, dan daftar item checklist kamar dimuat secara dinamis. Checklist kamar dirender secara read-only (sesuai batasan Sprint 5.3), sementara tombol penentu status (*Mulai Kelola* & *Kirim Bukti*) dinonaktifkan (`onPressed: null`) guna menghindari modifikasi data prematur sebelum dimulainya Sprint 5.4.

---

## 2. Berkas Ditambahkan (File Added)
1. `lib/features/task/data/task_detail.dart`
   - Mendefinisikan kelas model data `TaskDetail` dan `ChecklistItem` untuk memetakan spesifikasi ruangan, status tugas, petugas penanggung jawab, tanggal pembuatan, serta kumpulan checklist pembersihan kamar.
2. `lib/features/task/data/task_detail_repository.dart`
   - Kelas repositori untuk menangani pemanggilan GET asinkron ke `/Housekeeping/api_get_task.php` berdasarkan parameter `id`. Mengekspos `taskDetailRepositoryProvider`.
3. `lib/features/task/presentation/task_detail_controller.dart`
   - Kelas pengontrol Riverpod keluarga `TaskDetailController` yang mengawasi status detail asinkron (`AsyncValue<TaskDetail>`) per-kunci `taskId`. Mengekspos `taskDetailProvider(taskId)`.

---

## 3. Berkas Dimodifikasi (File Modified)
1. `lib/core/router/app_router.dart`
   - Mengubah deklarasi GoRouter `/task-detail/:id` untuk menangkap parameter String `id` dan melakukan konversi `int.tryParse(id)` sebelum diteruskan ke halaman detail tugas.
2. `lib/features/task/presentation/task_detail_screen.dart`
   - Merefaktor konstruktor agar menerima `int taskId`.
   - Menghapus dependensi model dummy lama.
   - Menghubungkan visual data detail dan status step progress bar secara live dari `taskDetailProvider(taskId)`.
   - Merender list **Item Checklist Kamar** secara dinamis (read-only checkbox).
   - Menampilkan penanganan error asinkron (termasuk deteksi visual error *404 Task Not Found*).
   - Menambahkan gesture pull-to-refresh (`RefreshIndicator`) untuk memicu `refreshTaskDetail()`.

---

## 4. Spesifikasi Integrasi API

### 4.1 Request Details
- **Endpoint:** `/Housekeeping/api_get_task.php`
- **Method:** `GET`
- **Query Parameter:** `id` (integer `task_id`)
- **Header:** `Cookie: PHPSESSID=...` (autentikasi otomatis via interceptor)

### 4.2 Response JSON (Format Data Teruji)
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "task_id": 1,
    "room": "101",
    "description": "Clean the bathroom and change towels.",
    "status": "In Progress",
    "assigned_staff": "hk_dago",
    "created_at": "2026-07-09 14:15:36",
    "checklist": [
      { "id": 1, "item_name": "Clean bathroom", "is_checked": true },
      { "id": 2, "item_name": "Refill soaps", "is_checked": false }
    ]
  }
}
```

---

## 5. Lembar Uji Verifikasi (Testing Checklist)

| Kasus Uji | Skenario Skenario | Hasil yang Diharapkan | Status |
| :--- | :--- | :--- | :---: |
| **Pemuatan Detail Kamar** | Buka detail penugasan kamar 101 | Kamar, deskripsi, PIC, status, dan tanggal terisi data real | ✅ **PASS** |
| **Pemuatan Checklist** | Periksa bagian checklist kamar | Item checklist terisi checkbox tercentang/kosong dari database | ✅ **PASS** |
| **Penanganan Task 404** | Navigasi manual ke detail dengan ID tidak terdaftar (contoh: 999) | Tampil ilustrasi error *Tugas Tidak Ditemukan (404)* | ✅ **PASS** |
| **Checkbox Read-Only** | Tap salah satu item checkbox checklist | Keadaan checkbox tidak berubah (tidak merusak data) | ✅ **PASS** |
| **Pull To Refresh** | Tarik halaman detail ke bawah | Halaman melakukan reload memicu pemanggilan ulang API | ✅ **PASS** |
| **Tombol Aksi Mati** | Periksa tombol aksi di bawah halaman | Tombol status ter-disable dan aman dari update prematur | ✅ **PASS** |

---

## 6. Known Issues (Masalah Diketahui)
- Checkbox checklist dan tombol status penugasan sengaja dinonaktifkan (`onPressed: null` & `onChanged: null`) karena fungsionalitas pengiriman data pembaruan tugas baru akan dikerjakan pada Sprint 5.4.

---

## 7. Rekomendasi Sprint 5.4
1. Sambungkan interaksi checkbox checklist ke endpoint `POST /Housekeeping/api_update_task.php` untuk memperbarui status centang di database Hostinger.
2. Integrasikan tombol status penugasan (*Mulai Kelola*) untuk memposting transisi status tugas (`Pending` ➔ `In Progress`) ke server.
