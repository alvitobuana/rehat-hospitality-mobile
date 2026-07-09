# Alur Bisnis Operasional Housekeeping - Rehat Hospitality Mobile
## Metadata Dokumen
- **Version:** v1.0.0
- **Status:** Approved Foundation
- **Author:** Senior PHP Backend Engineer & Mobile API Architect
- **Last Updated:** 2026-07-09
- **Dependencies:** `mobile_implementation_plan_v1.1.0.md`
- **Next Version:** v1.1.0
- **Change Log:**
  - v1.0.0: Dokumen inisiasi rekonstruksi alur bisnis operasional untuk aplikasi Flutter Housekeeping.

---

## 1. Rekonstruksi Alur Bisnis Utama (Housekeeping & QA Flow)

Berdasarkan analisis logika program pada repositori backend, alur bisnis operasional housekeeping terbagi menjadi dua skenario utama: **Alur Audit/Pemeriksaan Kebersihan Kamar** dan **Alur Penyelesaian Penugasan Kebersihan (CAP)**. Kedua alur ini sudah didukung penuh oleh endpoint backend PHP MySQL.

---

## 2. Alur Pemeriksaan & Pembuatan Checklist Kamar (Auditor / Supervisor HK)

```
[1. Login] 
    │
    ▼
[2. Dashboard] ──► (Pilih "Mulai Audit Baru")
    │
    ▼
[3. Pilih Hotel & Shift] ──► (Input Nama Hotel, Auditor, GM, Shift)
    │
    ▼
[4. Tambah Kamar] ──► (Input Nomor Kamar, Floor, Type, Status)
    │
    ▼
[5. Isi Checklist Kamar] ──► (Buka 37-item list, beri skor 1-5)
    │
    ▼
[6. Temuan & Foto] ──► (Jika skor < 5, ketik alasan & ambil foto bukti)
    │
    ▼
[7. Susun CAP Plan] ──► (Tentukan PIC staf HK, deadline perbaikan, deskripsi tugas)
    │
    ▼
[8. Submit Audit] ──► (Kirim JSON ke api_save_qa_audit.php)
    │
    ▼
[9. History Logs] ──► (Tinjau performa skor & status perbaikan di dashboard)
```

### Penjelasan Detail Langkah:
1. **Login:** Karyawan masuk menggunakan username & password. Server PHP menginisialisasi sesi dan menetapkan cookie `PHPSESSID`.
2. **Dashboard:** Aplikasi memvalidasi session cookie. Menu "Pemeriksaan Kamar Baru" aktif jika user memiliki hak akses (`perm_q` bernilai `'v'`).
3. **Pilih Hotel & Shift:** Memilih properti hotel yang diaudit (misal: "Rehat at Dago Sky, Bandung"), menetapkan nama GM, nama auditor, dan shift pengerjaan.
4. **Tambah Kamar:** Menambahkan daftar kamar yang akan diperiksa (misal: Room 202, Room 304). Status awal kamar diset (Dirty / Clean / Inspect).
5. **Isi Checklist Kamar:** Untuk setiap kamar yang ditambahkan, auditor mengisi checklist berisi **37 butir penilaian** yang mencakup Kebersihan & Kerapian, Bed & Linen, Kamar Mandi, Fasilitas Kamar, dan Guest Supplies.
6. **Catat Temuan & Foto:** Jika ada item checklist yang tidak memenuhi standar (skor < 5), auditor mengetik temuan kerusakan/kekotoran dan melampirkan foto temuan. Kamera perangkat diaktifkan via `image_picker` dan dikompresi menjadi format JPEG 720p sebelum dikonversi ke base64.
7. **Penyusunan CAP (Corrective Action Plan):** Untuk setiap temuan cacat, sistem otomatis membuat draft tugas tindakan korektif (misal: "Seprei bernoda di Room 202" ditugaskan kepada PIC Housekeeper Budi dengan deadline besok).
8. **Submit Laporan:** Seluruh payload JSON yang berisi data header, list kamar, detail 37 checklist per kamar, base64 foto lampiran, dan data CAP dikirim ke `/QA/api_save_qa_audit.php`.
9. **History Logs:** Laporan tersimpan di MySQL database, dan skor rata-rata hotel terhitung otomatis.

---

## 3. Alur Pengerjaan & Penyelesaian Tugas Kebersihan (Staff Housekeeper / PIC)

Staf Housekeeping di lapangan memantau tugas perbaikan (CAP) yang diberikan kepada mereka dan melaporkan penyelesaiannya melalui aplikasi mobile:

```
[1. Login Staff HK] 
         │
         ▼
[2. View Tasks / Dashboard] ──► (Aplikasi memanggil api_get_qa_history.php)
         │
         ▼
[3. Filter My Tasks (PIC)] ──► (Menyaring list CAP dengan status "Pending" & PIC nama staf)
         │
         ▼
[4. Ubah Status ke "In Progress"] ──► (Memulai pengerjaan perbaikan di area hotel)
         │
         ▼
[5. Selesai Pengerjaan & Ambil Foto Bukti] ──► (Memotret area kamar yang sudah bersih/diperbaiki)
         │
         ▼
[6. Kirim Laporan Selesai] ──► (Kirim data ke api_update_cap_status.php dengan status "Completed")
         │
         ▼
[7. Selesai (Completed)] ──► (Tugas hilang dari list pending, database terupdate)
```

### Penjelasan Detail Langkah:
1. **Login Staff HK:** Staf masuk menggunakan akun masing-masing.
2. **View Tasks / Dashboard:** Dashboard memanggil API `/QA/api_get_qa_history.php` dan mengambil array `action_plans`.
3. **Filter My Tasks:** Aplikasi memfilter daftar CAP berdasarkan nama PIC staf yang masuk (misal: "Budi") dan status tugas yang masih `"Pending"`.
4. **Ubah Status ke "In Progress":** Staf mengubah status CAP ke `"In Progress"` untuk menandakan barang sedang dikerjakan (opsional, dikirim ke `/QA/api_update_cap_status.php`).
5. **Ambil Foto Bukti (Proof of Work):** Setelah kamar dibersihkan atau fasilitas diperbaiki (misal: seprei bernoda telah diganti), staf mengambil foto hasil perbaikan menggunakan kamera ponsel.
6. **Kirim Laporan Selesai:** Staf mengetik komentar penutup (misal: "Seprei Room 202 sudah diganti baru yang bersih") dan mengirimkan payload JSON berisi ID CAP, status `"Completed"`, komentar staf, dan string base64 foto bukti ke `/QA/api_update_cap_status.php`.
7. **Selesai (Completed):** Backend PHP menyimpan foto ke server, memperbarui baris data CAP di MySQL. Di aplikasi Flutter, status tugas terupdate menjadi centang hijau dan dipindahkan ke daftar riwayat tugas selesai.

---

## 4. Penanganan Offline Mode & Sinkronisasi

Karena area operasional kamar hotel sering berada di basemen atau lorong tebal beton yang minim sinyal internet, aplikasi menerapkan alur sinkronisasi offline sebagai berikut:

1. **Pendeteksi Jaringan:** Aplikasi secara berkala membaca status internet via `connectivity_plus`.
2. **Koneksi Terputus (Offline):** Jika koneksi terputus saat auditor menekan tombol "Submit Laporan Audit", aplikasi Flutter tidak menampilkan error crash.
3. **Simpan Ke Antrean Hive:** Payload JSON audit dibungkus bersama metadata waktu dan disimpan ke dalam antrean lokal Hive database (`OfflineSyncQueue`). Layar beralih ke dashboard dan menampilkan notifikasi: *"Laporan disimpan di draf lokal (Offline Mode)"*.
4. **Pendeteksi Koneksi Pulih (Online):** Begitu perangkat mendeteksi sinyal internet pulih, background worker `QueueSyncWorker` aktif di latar belakang.
5. **Background Re-post:** Worker mengirimkan payload JSON yang tersimpan di Hive antrean lokal ke `/QA/api_save_qa_audit.php` secara otomatis.
6. **Notifikasi Sinkronisasi Berhasil:** Setelah backend merespon sukses, draf di Hive dihapus, dan antarmuka dashboard memperbarui status sinkronisasi menjadi hijau centang.
