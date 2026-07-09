# Catatan Integrasi Mobile Housekeeping - Rehat Hospitality Mobile
## Metadata Dokumen
- **Version:** v1.0.0
- **Status:** Approved Foundation
- **Author:** Senior Mobile API Architect & Lead Developer
- **Last Updated:** 2026-07-09
- **Dependencies:** `housekeeping_api_guide_v1.0.0.md`
- **Next Version:** v1.1.0
- **Change Log:**
  - v1.0.0: Dokumen inisiasi petunjuk teknis integrasi Flutter Housekeeping dengan API Backend PHP.

---

## 1. Analisis Kesiapan API (API Readiness & Gap Analysis)

Sebagai pengembang Flutter Mobile, berikut adalah ringkasan mengenai endpoint API backend yang telah tersedia secara utuh dan dapat langsung dikonsumsi, serta gap (kekurangan) API yang harus dimintakan atau dibuat oleh tim backend.

### 1.1 API yang Siap Pakai Langsung (Ready to Use)
- **API Otentikasi & Cek Sesi:** `/Core_system_Auth/login.php` dan `/Access_management/api_auth_check.php` sudah berfungsi penuh melayani pertukaran credential login menjadi persistent PHP session cookie.
- **Kirim Formulir Checklist & Foto Audit Kamar:** `/QA/api_save_qa_audit.php` siap menerima payload JSON berskala besar berisi data checklist kamar tamu, skor, temuan teks, dan foto temuan dalam format data URI Base64.
- **Pembaruan Status CAP (Maintenance / Cleaning Resolve):** `/QA/api_update_cap_status.php` sudah siap digunakan oleh staf housekeeper lapangan untuk melaporkan perbaikan, menulis komentar, dan mengunggah foto bukti fisik base64.
- **Log Riwayat Riwayat Audit & CAP:** `/QA/api_get_qa_history.php` siap mengembalikan seluruh histori untuk kebutuhan layar dashboard tugas.

---

## 2. API yang Belum Ada & Rekomendasi Endpoint Baru (Missing APIs)

Untuk menghadirkan aplikasi Housekeeping yang matang dan terpisah dari modul QA umum, tim Backend PHP perlu mengembangkan beberapa endpoint tambahan berikut:

### 2.1 Standalone Room Status API (Pembaruan Cepat Status Kamar)
- **Kondisi Saat Ini:** Status kamar (Dirty, Clean, Inspected) hanya bisa diubah ketika supervisor HK membuat laporan audit utuh melalui `api_save_qa_audit.php`. Staf HK tidak memiliki API mandiri untuk mengupdate status kamar (misal: merubah status kamar 102 dari *Dirty* menjadi *Clean* setelah selesai disapu) tanpa mengisi 37 item checklist audit.
- **Rekomendasi Endpoint Baru:**
  - **URL:** `/Housekeeping/api_update_room_status.php`
  - **Method:** `POST`
  - **Payload:** `{"room_number": "102", "status": "Clean"}`
  - **Tujuan:** Mempermudah staf HK memperbarui status fisik kamar secara cepat di dashboard utama.

### 2.2 Standalone Lost & Found Management API
- **Kondisi Saat Ini:** Fitur Lost & Found hanya diwakili oleh satu baris checklist evaluasi di audit departemen Housekeeping (`s2` item ke-10: "Lost & Found tercatat dan diproses"). Staf tidak memiliki media untuk menginput detail barang hilang (deskripsi barang, lokasi ditemukan, penemu, tanggal, dan foto barang).
- **Rekomendasi Endpoint Baru:**
  - **Tabel Baru:** `lost_founds` (id, item_name, room_found, finder_name, status, description, photo_path, created_at).
  - **Endpoint List:** `/Housekeeping/api_lost_found_list.php` (`GET`)
  - **Endpoint Save:** `/Housekeeping/api_lost_found_save.php` (`POST` JSON dengan image base64).
  - **Tujuan:** Menyediakan modul Lost & Found yang layak dan dapat ditracking oleh staf hotel.

### 2.3 Dynamic Room Checklist Template API
- **Kondisi Saat Ini:** Daftar 37 butir checklist kamar tamu dikodekan secara statis (*hardcoded*) di sisi front-end HTML/JS. Jika hotel ingin menambah atau mengurangi butir checklist (misal: menambah check "Suhu kulkas minibar"), developer Flutter terpaksa harus merevisi aplikasi mobile dan merilis ulang file APK/IPA.
- **Rekomendasi Endpoint Baru:**
  - **URL:** `/QA/api_get_room_checklist_template.php`
  - **Method:** `GET`
  - **Tujuan:** Mengembalikan daftar kategori dan butir checklist kamar secara dinamis dari database MySQL, sehingga aplikasi Flutter dapat merender form checklist secara dinamis.

---

## 3. Poin Kritis Integrasi Flutter (Critical Flutter Integration Notes)

Seluruh developer Flutter wajib memperhatikan aspek teknis berikut saat menyusun kode integrasi network dan storage layer:

### 3.1 Otomatisasi Cookie Session (`PHPSESSID`)
- **Warning:** Jangan mencoba mengekstrak cookie `PHPSESSID` secara manual dari response login lalu menyimpannya di secure storage untuk diinjeksi manual ke header API berikutnya.
- **Praktek Terbaik:** Daftarkan `PersistedCookieJar` dari package `cookie_jar` ke dalam interceptor `Dio` (menggunakan `dio_cookie_manager`). Dio akan menangani penyimpanan dan pengiriman ulang cookie secara otomatis di latar belakang. Jika sesi kedaluwarsa di server PHP, Dio Interceptor wajib menangkap status **HTTP 401** dan mengarahkan paksa pengguna kembali ke halaman Login.

### 3.2 Batasan Ukuran Payload Base64 & Enforce Kompresi Gambar
- **Warning:** Mengunggah foto beresolusi tinggi (4MB ke atas dari kamera HP modern) dalam format base64 langsung di dalam JSON body akan melipatgandakan ukuran data kiriman hingga ~5.5MB (dikarenakan overhead encoding Base64). Payload sebesar ini berpotensi memicu error **Request Entity Too Large (HTTP 413)** atau memory crash (*Out Of Memory*) di ponsel staf hotel.
- **Praktek Terbaik:**
  - Wajib jalankan kompresi gambar menggunakan `flutter_image_compress` sebelum melakukan konversi file ke base64 string.
  - Konfigurasi batas kompresi: resolusi maksimum **1280x720px (720p)**, format **JPEG**, dan kualitas **80-85%**. Ini akan memangkas ukuran payload foto hingga kurang dari **300KB** per gambar tanpa merusak visual pembuktian kerusakan/kebersihan kamar.

### 3.3 Penanganan Nilai Null pada Deserialisasi JSON (Null Safety)
- **Warning:** Kolom `score`, `finding`, dan `attachment_path` di tabel `qa_audit_items` bersifat nullable (boleh bernilai NULL). Apabila data model Flutter dideklarasikan sebagai tipe data non-nullable (`int` atau `String` tanpa tanda tanya `?`), parser `fromJson` bawaan Dart akan mengalami crash (`TypeError: Null is not a subtype of type String`).
- **Praktek Terbaik:**
  - Seluruh variabel penampung butir checklist wajib dideklarasikan nullable pada model data Freezed Dart:
    ```dart
    @freezed
    class QaItemModel with _$QaItemModel {
      const factory QaItemModel({
        @JsonKey(name: 'section_id') required String sectionId,
        @JsonKey(name: 'item_index') required int itemIndex,
        int? score,
        String? finding,
        @JsonKey(name: 'attachment_path') String? attachmentPath,
      }) = _QaItemModel;
    }
    ```

### 3.4 Sinkronisasi Data Offline Mode & Auto-Increment ID
- **Warning:** Saat aplikasi dalam kondisi offline, staf HK dapat menyelesaikan tugas CAP lokal. Tugas CAP lokal ini belum memiliki ID primer (`id` auto-increment) yang sah dari database MySQL server.
- **Praktek Terbaik:** Gunakan flag lokal seperti `isSynced = false` dan ID lokal sementara berbasis UUID pada aplikasi Flutter saat menyimpan draf di Hive. Ketika jaringan internet terdeteksi pulih, lakukan sinkronisasi master audit (`api_save_qa_audit.php`) terlebih dahulu untuk mendapatkan ID audit resmi, baru kemudian lakukan update terhadap status CAP penugasan terkait.
