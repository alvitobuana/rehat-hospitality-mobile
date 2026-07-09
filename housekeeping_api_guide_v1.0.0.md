# Panduan Integrasi API Housekeeping - Rehat Hospitality Mobile
## Metadata Dokumen
- **Version:** v1.0.0
- **Status:** Approved Foundation
- **Author:** Senior PHP Backend Engineer & Mobile API Architect
- **Last Updated:** 2026-07-09
- **Dependencies:** `rehat-hospitality-mobile` API Network layer
- **Next Version:** v1.1.0
- **Change Log:**
  - v1.0.0: Dokumen inisiasi integrasi API Housekeeping hasil reverse engineering repositori `qa_web_rehat`.

---

## 1. Pengantar & Pemetaan Modul Housekeeping

Hasil reverse engineering terhadap kode backend PHP (`qa_web_rehat`) menunjukkan bahwa **tidak terdapat modul database atau file khusus bernama "housekeeping"**. 

Seluruh operasional housekeeping (checklist kebersihan kamar, status kamar, upload foto temuan kotor/rusak, pelaporan Lost & Found, serta perbaikan fasilitas) dikelola di bawah modul **QA (Quality Assurance)** dan **CAP (Corrective Action Plan / Action Plans)**. 

Berikut adalah pemetaan bagaimana kebutuhan fitur Flutter Housekeeping dipenuhi oleh API Backend yang ada:
- **Authentication & Profile:** Dilayani oleh `/Core_system_Auth/login.php` dan `/Access_management/api_auth_check.php` menggunakan PHP Session Cookie.
- **Cheklist Kamar & Cleaning:** Dikirim sebagai satu laporan audit utuh melalui `/QA/api_save_qa_audit.php`.
- **Photo Upload:** Dikirim secara inline di dalam payload JSON sebagai string base64 (`data:image/jpeg;base64,...`) yang didecode otomatis oleh server PHP menjadi file fisik di folder `uploads/qa/`.
- **Lost & Found:** Diperiksa di bawah audit departemen Housekeeping (`section_id: 's2'`, item ke-10: "Lost & Found tercatat dan diproses").
- **Maintenance / Penugasan Staff:** Dikelola melalui sistem CAP (`qa_action_plans`), di mana staf dapat memperbarui status tindakan perbaikan, menulis komentar, dan mengunggah bukti foto melalui `/QA/api_update_cap_status.php`.

---

## 2. Tabel Ringkasan Endpoint API (API Summary Table)

| ID | Nama Endpoint | HTTP Method | URL Endpoint | Auth Required | Fungsi Utama | Target Screen Flutter |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **API-01** | Login Karyawan | POST | `/Core_system_Auth/login.php` | No | Membuat PHP Session & cookie | `LoginScreen` |
| **API-02** | Check Session & Profile | GET | `/Access_management/api_auth_check.php` | Yes (Cookie) | Memvalidasi session & mengambil izin peran | `SplashScreen`, `ProfileScreen` |
| **API-03** | Get Audit & CAP History | GET | `/QA/api_get_qa_history.php` | Yes (Cookie) | Mengambil log riwayat audit & daftar CAP | `DashboardScreen`, `HistoryScreen` |
| **API-04** | Get Detail Audit | GET | `/QA/api_get_qa_audit_details.php` | Yes (Cookie) | Mengambil detail skor checklist & draf kamar | `RoomDetailScreen`, `AuditSummaryScreen` |
| **API-05** | Save Audit / Checklist | POST | `/QA/api_save_qa_audit.php` | Yes (Cookie) | Mengirim laporan kebersihan kamar & temuan | `AuditFormScreen`, `ChecklistScreen` |
| **API-06** | Update CAP Task (Maintenance) | POST | `/QA/api_update_cap_status.php` | Yes (Cookie) | Melaporkan perbaikan fasilitas / kebersihan | `TaskDetailScreen`, `CapTrackerScreen` |
| **API-07** | Delete Audit Report | POST | `/QA/api_delete_qa_audit.php` | Yes (Cookie) | Menghapus laporan audit (Admin only) | `HistoryScreen` |
| **API-08** | Logout Karyawan | GET / POST| `/Core_system_Auth/logout.php` | Yes (Cookie) | Menghancurkan session & menghapus cookie | `SettingsScreen`, `LoginScreen` |

---

## 3. Spesifikasi Detail Endpoint (Detailed Endpoint Specifications)

### API-01: Login Karyawan
- **File Location:** `Core_system_Auth/login.php`
- **HTTP Method:** `POST`
- **Endpoint URL:** `/Core_system_Auth/login.php`
- **Request Headers:**
  - `Content-Type: application/json` atau `application/x-www-form-urlencoded`
- **Request Parameter (JSON Payload):**
  ```json
  {
    "username": "housekeeper1",
    "password": "securepassword"
  }
  ```
- **Response JSON (Success - 200 OK):**
  ```json
  {
    "status": "success",
    "message": "Login successful.",
    "role": "staff",
    "level": "Non Admin",
    "redirect": "index.html"
  }
  ```
  *(Catatan: Server akan menyertakan header `Set-Cookie: PHPSESSID=xxxxxx; path=/; HttpOnly`)*
- **Response JSON (Error - 400 Bad Request):**
  ```json
  {
    "status": "error",
    "message": "Invalid username or password."
  }
  ```
- **Business Logic:** Backend memvalidasi username di tabel `users` dan mencocokkan password menggunakan `password_verify()`. Jika sukses, data pengguna dimasukkan ke array `$_SESSION` global dan session ID dikirim ke klien.

---

### API-02: Check Session & Profile Information
- **File Location:** `Access_management/api_auth_check.php`
- **HTTP Method:** `GET`
- **Endpoint URL:** `/Access_management/api_auth_check.php`
- **Request Headers:**
  - `Cookie: PHPSESSID=xxxxxx` (Wajib disertakan)
- **Response JSON (Success - 200 OK):**
  ```json
  {
    "status": "success",
    "username": "housekeeper1",
    "role": "staff",
    "level": "Non Admin",
    "perm_r": "v",
    "perm_o": "v",
    "perm_q": "v",
    "perm_f": "v",
    "perm_s": "v",
    "perm_a": "x"
  }
  ```
- **Response JSON (Error - 401 Unauthorized):**
  ```json
  {
    "status": "error",
    "message": "Unauthorized. Please login first.",
    "redirect": "login.html"
  }
  ```
- **Business Logic:** Memeriksa keberadaan `$_SESSION['user_id']`. Jika ada, mengembalikan detail role dan permissions user. Jika tidak ada, mengembalikan status 401.

---

### API-03: Get Audit & CAP History
- **File Location:** `QA/api_get_qa_history.php`
- **HTTP Method:** `GET`
- **Endpoint URL:** `/QA/api_get_qa_history.php`
- **Request Headers:**
  - `Cookie: PHPSESSID=xxxxxx`
- **Response JSON (Success - 200 OK):**
  ```json
  {
    "status": "success",
    "audits": [
      {
        "id": "12",
        "hotel_name": "Rehat at Dago Sky, Bandung",
        "audit_date": "2026-07-09",
        "audit_type": "Weekly",
        "shift": "Pagi",
        "auditor": "Supervisior HK",
        "general_manager": "GM Dago",
        "total_score": "88.5"
      }
    ],
    "action_plans": [
      {
        "id": "24",
        "audit_id": "12",
        "task_no": "1",
        "description": "Lantai kamar mandi berlumut",
        "area": "Kamar 302",
        "corrective_action": "Sikat grouting tile lantai kamar mandi",
        "pic": "housekeeper1",
        "target_date": "2026-07-10",
        "status": "Pending",
        "staff_comment": null,
        "proof_image": null,
        "hotel_name": "Rehat at Dago Sky, Bandung",
        "audit_date": "2026-07-09"
      }
    ]
  }
  ```
- **Business Logic:** Mengambil seluruh daftar histori audit dari tabel `qa_audits` (diurutkan berdasarkan tanggal terbaru) dan semua daftar rencana perbaikan (CAP) dari tabel `qa_action_plans` yang di-join dengan tabel `qa_audits` untuk mendapatkan konteks nama hotel.

---

### API-04: Get Detail Audit & Checklists
- **File Location:** `QA/api_get_qa_audit_details.php`
- **HTTP Method:** `GET`
- **Endpoint URL:** `/QA/api_get_qa_audit_details.php?id={audit_id}`
- **Request Headers:**
  - `Cookie: PHPSESSID=xxxxxx`
- **Response JSON (Success - 200 OK):**
  ```json
  {
    "status": "success",
    "id": 12,
    "hotel_name": "Rehat at Dago Sky, Bandung",
    "audit_date": "2026-07-09",
    "audit_type": "Weekly",
    "shift": "Pagi",
    "auditor": "Supervisior HK",
    "general_manager": "GM Dago",
    "total_score": 88.5,
    "state": {
      "scores": {
        "s1": { "0": 5, "1": 5 },
        "s2": { "0": 4, "9": 3 }
      },
      "findings": {
        "s2": { "9": "Log Lost & found belum diupdate" }
      },
      "attachments": {
        "s2": { "9": "uploads/qa/audit_12_s2_9_abc.jpg" }
      },
      "rooms": [
        {
          "id": "r1",
          "number": "302",
          "type": "Standard",
          "floor": "3",
          "status": "Dirty",
          "scores": { "0": 5, "1": 3 },
          "findings": { "1": "Seprei ada noda kuning" },
          "attachments": { "1": "uploads/qa/audit_12_r1_1_xyz.jpg" }
        }
      ]
    },
    "action_plans": [
      {
        "id": 24,
        "task_no": 1,
        "description": "Seprei ada noda kuning di Kamar 302",
        "area": "Kamar 302",
        "corrective_action": "Ganti seprei dengan linen standar",
        "pic": "housekeeper1",
        "target_date": "2026-07-10",
        "status": "Pending",
        "staff_comment": null,
        "proof_image": null
      }
    ]
  }
  ```
- **Business Logic:** Membaca detail data audit berdasarkan ID. Mengonstruksi ulang struktur state JSON mencakup skor departemen (`s1` - `s6`), temuan (*findings*), lampiran foto (*attachments*), daftar kamar tamu yang diperiksa (`rooms`), dan tugas perbaikan (`action_plans`).

---

### API-05: Save Audit / Checklist Kamar
- **File Location:** `QA/api_save_qa_audit.php`
- **HTTP Method:** `POST`
- **Endpoint URL:** `/QA/api_save_qa_audit.php`
- **Request Headers:**
  - `Content-Type: application/json`
  - `Cookie: PHPSESSID=xxxxxx`
- **Request Parameter (JSON Payload):**
  *(Payload harus menyertakan data hotel, metadata, data audit departemen, data audit kamar, dan CAP plans. Gambar dikirim sebagai format data URI Base64 di objek `attachments`)*
  ```json
  {
    "hotel_name": "Rehat at Dago Sky, Bandung",
    "audit_date": "2026-07-09",
    "audit_type": "Weekly",
    "shift": "Pagi",
    "auditor": "Supervisior HK",
    "general_manager": "GM Dago",
    "total_score": 92.3,
    "state": {
      "scores": {
        "s2": { "0": 5, "1": 4 }
      },
      "findings": {
        "s2": { "1": "Koridor berdebu sedikit" }
      },
      "attachments": {
        "s2": { "1": "data:image/jpeg;base64,/9j/4AAQSkZJRg..." }
      },
      "rooms": [
        {
          "id": "r1",
          "number": "202",
          "type": "Standard",
          "floor": "2",
          "status": "Dirty",
          "scores": {
            "0": 5,
            "1": 2
          },
          "findings": {
            "1": "Seprei bernoda"
          },
          "attachments": {
            "1": "data:image/jpeg;base64,/9j/4AAQSkZ..."
          }
        }
      ]
    },
    "action_plans": [
      {
        "description": "Seprei bernoda di Kamar 202",
        "area": "Kamar 202",
        "corrective_action": "Ganti seprei baru",
        "pic": "housekeeper1",
        "target_date": "2026-07-10",
        "status": "Pending"
      }
    ]
  }
  ```
- **Response JSON (Success - 200 OK):**
  ```json
  {
    "status": "success",
    "message": "Audit report successfully saved to database.",
    "audit_id": 13
  }
  ```
- **Business Logic:** Membuka transaksi database (`beginTransaction()`). Menyimpan data header ke `qa_audits`. Menyimpan isian checklist departemen ke `qa_audit_items`. Menyimpan data list kamar ke `qa_audit_rooms`. Menyimpan checklist per kamar ke `qa_audit_items` dengan `section_id` diset sesuai ID kamar (misal: `r1`). Menyimpan penugasan ke `qa_action_plans`. Mendecode string base64 gambar dan menyimpannya sebagai file fisik di folder `uploads/qa/`.

---

### API-06: Update CAP Task (Maintenance / Cleaning Resolve)
- **File Location:** `QA/api_update_cap_status.php`
- **HTTP Method:** `POST`
- **Endpoint URL:** `/QA/api_update_cap_status.php`
- **Request Headers:**
  - `Content-Type: application/json`
  - `Cookie: PHPSESSID=xxxxxx`
- **Request Parameter (JSON Payload):**
  ```json
  {
    "cap_id": 24,
    "status": "Completed",
    "staff_comment": "Seprei kotor sudah diganti dengan seprei baru yang bersih.",
    "proof_image": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  }
  ```
- **Response JSON (Success - 200 OK):**
  ```json
  {
    "status": "success",
    "message": "Action plan progress updated successfully.",
    "proof_image": "uploads/qa/proof_24_64a2b9c7.jpeg"
  }
  ```
- **Business Logic:** Membaca data CAP berdasarkan `cap_id`. Mendecode foto bukti perbaikan (`proof_image`) yang dikirim dalam format base64 dan menyimpannya ke `uploads/qa/`. Memperbarui kolom `status`, `staff_comment`, dan `proof_image` di tabel `qa_action_plans`.

---

### API-07: Delete Audit Report (Admin Only)
- **File Location:** `QA/api_delete_qa_audit.php`
- **HTTP Method:** `POST`
- **Endpoint URL:** `/QA/api_delete_qa_audit.php`
- **Request Headers:**
  - `Content-Type: application/json`
  - `Cookie: PHPSESSID=xxxxxx`
- **Request Parameter (JSON Payload):**
  ```json
  {
    "audit_id": 12
  }
  ```
- **Response JSON (Success - 200 OK):**
  ```json
  {
    "status": "success",
    "message": "Audit report and all related items successfully deleted."
  }
  ```
- **Business Logic:** Menghapus data di tabel `qa_audits` berdasarkan ID. Skema database menggunakan constraint `ON DELETE CASCADE` sehingga seluruh data relasi kamar, checklist item, dan CAP terkait akan otomatis terhapus dari MySQL database.

---

### API-08: Logout Karyawan
- **File Location:** `Core_system_Auth/logout.php`
- **HTTP Method:** `GET` / `POST`
- **Endpoint URL:** `/Core_system_Auth/logout.php`
- **Request Headers:**
  - `Cookie: PHPSESSID=xxxxxx`
- **Response JSON / Redirect:**
  - Redirect otomatis ke `login.html` (jika diakses via browser).
  - *Untuk Mobile, Flutter cukup menghapus database cookie lokal dan mengabaikan isi redirect HTML.*
- **Business Logic:** Menghapus seluruh array `$_SESSION`, mematikan session cookie di server dengan menetapkan waktu kedaluwarsa mundur (`time() - 42000`), dan memanggil `session_destroy()`.
