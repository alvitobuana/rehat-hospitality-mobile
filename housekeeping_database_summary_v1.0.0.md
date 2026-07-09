# Ringkasan Database Housekeeping - Rehat Hospitality Mobile
## Metadata Dokumen
- **Version:** v1.0.0
- **Status:** Approved Foundation
- **Author:** Senior PHP Backend Engineer & Database Architect
- **Last Updated:** 2026-07-09
- **Dependencies:** `qa_web_rehat` MySQL Schema (`db_setup.php`)
- **Next Version:** v1.1.0
- **Change Log:**
  - v1.0.0: Dokumen inisiasi pemetaan skema tabel database MySQL backend untuk sinkronisasi model data mobile.

---

## 1. Diagram Relasi Entitas (Entity Relationship Summary)

Struktur tabel di database MySQL backend yang mendukung operasional housekeeping dan audit kamar adalah sebagai berikut:

```
 ┌──────────────┐
 │    users     │
 └──────────────┘
  (Autentikasi & Izin)

 ┌──────────────┐          1:N           ┌───────────────────┐
 │  qa_audits   │ ─────────────────────► │  qa_audit_rooms   │
 └──────────────┘ (Cascade Delete)       └───────────────────┘
   │          │                            (Kamar yang Diaudit)
   │          │
   │ 1:N      └──────────────────────────┐ 1:N
   │ (Cascade Delete)                    ▼
   │                                   ┌───────────────────┐
   │                                   │  qa_audit_items   │
   │                                   └───────────────────┘
   │                                     (Skor & Temuan Checklist)
   │ 1:N
   └───────────────────────────────────► ┌───────────────────┐
     (Cascade Delete)                    │  qa_action_plans  │
                                         └───────────────────┘
                                           (CAP Tasks / Maintenance)
```

---

## 2. Struktur Detail Tabel Database (Table Schema Details)

### 2.1 Tabel `users`
Tabel ini menyimpan data kredensial login, peran (*role*), tingkat administrator (*level*), dan hak akses izin fitur.
- **SQL Schema DDL:**
  ```sql
  CREATE TABLE users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      username VARCHAR(50) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      role VARCHAR(20) DEFAULT 'staff',
      level VARCHAR(20) DEFAULT 'Non Admin',
      perm_r VARCHAR(1) DEFAULT 'v', -- Revenue permission
      perm_o VARCHAR(1) DEFAULT 'v', -- Overall permission
      perm_q VARCHAR(1) DEFAULT 'v', -- QA (Housekeeping) permission
      perm_f VARCHAR(1) DEFAULT 'v', -- Finance permission
      perm_s VARCHAR(1) DEFAULT 'v', -- Supply permission
      perm_a VARCHAR(1) DEFAULT 'x', -- Admin permission
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB;
  ```
- **Karakteristik Data:**
  - `password_hash` disimpan dalam enkripsi hash bcrypt PHP (`password_hash()`).
  - Flag permission bernilai `'v'` (view/allow) atau `'x'` (deny/no-access). Aplikasi mobile wajib memeriksa kolom `perm_q` untuk modul Housekeeping.

---

### 2.2 Tabel `qa_audits` (Header Audit)
Tabel master yang menyimpan informasi identitas utama laporan audit kebersihan hotel.
- **SQL Schema DDL:**
  ```sql
  CREATE TABLE qa_audits (
      id INT AUTO_INCREMENT PRIMARY KEY,
      hotel_name VARCHAR(150) NOT NULL,
      audit_date DATE NOT NULL,
      audit_type VARCHAR(50) NOT NULL,
      shift VARCHAR(50) DEFAULT '',
      auditor VARCHAR(100) DEFAULT '',
      general_manager VARCHAR(100) DEFAULT '',
      total_score DOUBLE DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB;
  ```
- **Karakteristik Data:**
  - `total_score` merupakan persentase nilai akhir kepatuhan kebersihan hotel.

---

### 2.3 Tabel `qa_audit_rooms` (Kamar Tamu)
Tabel transaksional yang menyimpan metadata dari setiap kamar yang diperiksa di bawah satu laporan audit.
- **SQL Schema DDL:**
  ```sql
  CREATE TABLE qa_audit_rooms (
      id INT AUTO_INCREMENT PRIMARY KEY,
      audit_id INT NOT NULL,
      room_id_code VARCHAR(20) NOT NULL, -- Kode index lokal, misal: 'r1', 'r2'
      room_number VARCHAR(20) DEFAULT '',
      room_type VARCHAR(100) DEFAULT '',
      floor VARCHAR(20) DEFAULT '',
      room_status VARCHAR(50) DEFAULT '', -- Dirty, Clean, Inspected
      FOREIGN KEY (audit_id) REFERENCES qa_audits(id) ON DELETE CASCADE
  ) ENGINE=InnoDB;
  ```
- **Hubungan Relasi:**
  - Hubungan Many-to-One dengan tabel `qa_audits` (`audit_id`). 
  - Constraint `ON DELETE CASCADE` menjamin jika data laporan audit utama dihapus, daftar kamar terkait otomatis ikut terhapus.

---

### 2.4 Tabel `qa_audit_items` (Butir Checklist & Foto Temuan)
Tabel ini sangat fleksibel dan menyimpan seluruh skor penilaian, deskripsi masalah, serta berkas lampiran foto kotor/rusak.
- **SQL Schema DDL:**
  ```sql
  CREATE TABLE qa_audit_items (
      id INT AUTO_INCREMENT PRIMARY KEY,
      audit_id INT NOT NULL,
      section_id VARCHAR(20) NOT NULL, -- Menyimpan 's1'-'s6' (dept) atau 'r1'-'rN' (kamar)
      item_index INT NOT NULL,         # Indeks baris item checklist (0-indexed)
      score TINYINT DEFAULT NULL,      # Nilai rating 0 sampai 5 (atau null)
      finding TEXT DEFAULT NULL,       # Teks catatan temuan kotor/rusak
      attachment_path VARCHAR(255) DEFAULT NULL, -- Path lokasi file foto fisik di server
      FOREIGN KEY (audit_id) REFERENCES qa_audits(id) ON DELETE CASCADE
  ) ENGINE=InnoDB;
  ```
- **Hubungan Relasi & Logika Data:**
  - `section_id` merujuk ke ID departemen (seperti `s2` untuk departemen Housekeeping) **ATAU** merujuk ke kode kamar tamu `room_id_code` di tabel `qa_audit_rooms` (seperti `r1`, `r2`). Ini meminimalkan jumlah tabel relasi checklist.
  - `attachment_path` menyimpan string path relatif dari folder root server, misal: `uploads/qa/audit_12_r1_1_64a2b.jpg`.

---

### 2.5 Tabel `qa_action_plans` (CAP / Penugasan Pemeliharaan Kamar)
Tabel penugasan tindakan korektif (CAP) untuk mengatasi temuan checklist kamar yang kotor atau rusak. Berfungsi sebagai database log penugasan staff housekeeper di lapangan.
- **SQL Schema DDL:**
  ```sql
  CREATE TABLE qa_action_plans (
      id INT AUTO_INCREMENT PRIMARY KEY,
      audit_id INT NOT NULL,
      task_no INT NOT NULL,            # Nomor urut tugas di dalam laporan audit
      description TEXT NOT NULL,       # Deskripsi kerusakan/kekotoran yang ditemukan
      area VARCHAR(100) NOT NULL,      # Lokasi temuan (misal: "Kamar 302", "Lobby")
      corrective_action TEXT NOT NULL, # Tindakan perbaikan yang harus dilakukan
      pic VARCHAR(100) DEFAULT '',     # Nama staf HK yang ditugaskan (PIC)
      target_date DATE DEFAULT NULL,   # Batas waktu pengerjaan (deadline)
      status VARCHAR(50) DEFAULT 'Pending', -- Pending, In Progress, Completed
      staff_comment TEXT DEFAULT NULL, # Komentar staf saat melaporkan penyelesaian
      proof_image VARCHAR(255) DEFAULT NULL, -- Path foto bukti fisik setelah selesai dibersihkan
      FOREIGN KEY (audit_id) REFERENCES qa_audits(id) ON DELETE CASCADE
  ) ENGINE=InnoDB;
  ```
- **Hubungan Relasi & Perilaku:**
  - Relasi Many-to-One dengan tabel `qa_audits` (`audit_id`).
  - Kolom `status` menyimpan siklus kerja penugasan staf HK: `Pending` ➔ `In Progress` ➔ `Completed`.
  - Kolom `staff_comment` dan `proof_image` diisi oleh staf HK ketika mereka mengupdate status menjadi `Completed` melalui API perbaikan.
