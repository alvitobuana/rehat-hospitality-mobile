# Location Source & Geofence Validation Audit

**Project:** Rehat Housekeeping Mobile  
**Audit Target:** Geofence Validation Flow (Check-In / Check-Out)  
**Status:** 🔍 AUDIT COMPLETE (JANGAN mengubah kode)

---

## 1. Flow Diagram

Berikut adalah alur lengkap dari pembacaan koordinat GPS hingga pemunculan pesan kesalahan SnackBar di layar HP pengguna:

```mermaid
sequenceDiagram
    actor User as Karyawan Staf
    participant UI as DashboardScreen (Flutter)
    participant Ctrl as AttendanceController (Riverpod)
    participant Loc as LocationService (Flutter)
    participant Rep as AttendanceRepository (Flutter)
    participant API as api_check_in.php (Hostinger Backend)
    database DB as MySQL Database (Hostinger)

    User->>UI: Tap tombol "Check In" / "Check Out"
    activate UI
    UI->>Ctrl: Panggil checkIn() / checkOut()
    activate Ctrl
    Ctrl->>Loc: Ambil lokasi saat ini (getCurrentLocation)
    activate Loc
    Note over Loc: Geolocator.getCurrentPosition()<br/>High Accuracy (Desired)
    Loc-->>Ctrl: Return {'latitude': 0.0, 'longitude': 0.0} (Null Island)
    deactivate Loc
    
    Ctrl->>Rep: Kirim data Check-In / Check-Out
    activate Rep
    Rep->>API: HTTP POST /Housekeeping/api_check_in.php (Lat=0.0, Lng=0.0)
    activate API
    
    Note over API: 1. Validasi Device Binding
    Note over API: 2. Ambil hotel_id dari tabel 'users'
    API->>DB: SELECT hotel_id FROM users WHERE id = :user_id
    DB-->>API: Return 'dagosky'
    
    Note over API: 3. Ambil koordinat hotel dari 'revenue_properties'
    API->>DB: SELECT latitude, longitude, radius FROM revenue_properties WHERE prop_id = 'dagosky'
    DB-->>API: Return Lat=-6.914, Lng=107.6167, Radius=150
    
    Note over API: 4. Hitung Jarak (Haversine)<br/>(0,0) ke (-6.914, 107.6167)<br/>Hasil = 11,951,729 meter
    Note over API: 5. Bandingkan Jarak vs Radius (11,951,729 > 150)
    
    API-->>Rep: Return HTTP 400 (success: false, message: "You are outside...")
    deactivate API
    Rep-->>Ctrl: Throw AppFailure (CHECKIN_REJECTED)
    deactivate Rep
    Ctrl-->>UI: State update dengan errorMessage & Status.error
    deactivate Ctrl
    
    UI->>User: Tampilkan SnackBar merah (Pesan Error dari Server)
    deactivate UI
```

---

## 2. Source Code Locations

### A. Flutter (Frontend - Snackbox/SnackBar Trigger)
* **File:** [dashboard_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/attendance/presentation/dashboard_screen.dart)
* **Class:** `_DashboardScreenState`
* **Method:** `build(...)` (di dalam closure `ref.listen<AttendanceState>`)
* **Baris Kode:** Baris 90–100:
  ```dart
  ref.listen<AttendanceState>(attendanceControllerProvider, (previous, next) {
    if (next.status == AttendanceStatus.error && next.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      ref.read(attendanceControllerProvider.notifier).clearError();
    }
  });
  ```

### B. PHP (Backend - Geofence Validation)
* **File:** [api_check_in.php](file:///d:/Rehat_Hospitality/qa_web_rehat/Housekeeping/api_check_in.php) (untuk Check In) dan [api_check_out.php](file:///d:/Rehat_Hospitality/qa_web_rehat/Housekeeping/api_check_out.php) (untuk Check Out)
* **Method:** Eksekusi linear (tidak di dalam kelas)
* **Baris Kode (Validasi & Pembuatan Pesan Error):** Baris 135–142 di `api_check_in.php` (atau 139–146 di `api_check_out.php`):
  ```php
  if ($distance > $allowedRadius) {
      http_response_code(400); // Bad Request
      echo json_encode([
          'success' => false,
          'message' => 'You are outside the hotel premises. (Distance: ' . round($distance, 1) . 'm, Max allowed: ' . $allowedRadius . 'm)'
      ]);
      exit;
  }
  ```

---

## 3. Source of Hotel Coordinates

Koordinat hotel berasal dari **Database MySQL Hostinger** pada tabel **`revenue_properties`** (kolom `latitude`, `longitude`, dan `radius`).

### Alur Kueri Database di Backend:
1. Mengambil `hotel_id` pengguna berdasarkan `user_id` dari tabel `users` (baris 102):
   ```sql
   SELECT hotel_id FROM users WHERE id = :user_id
   ```
2. Mengambil koordinat dan radius hotel dari tabel `revenue_properties` (baris 116):
   ```sql
   SELECT latitude, longitude, radius FROM revenue_properties WHERE prop_id = :hotel_id
   ```

---

## 4. Distance Formula & Calculation

Jarak dihitung menggunakan **Haversine Distance Formula** di backend PHP. Rumus ini menghitung jarak lingkaran besar antara dua pasang koordinat bumi dalam satuan **meter**.

### Kode Rumus Haversine (Backend):
```php
function haversineDistance($lat1, $lon1, $lat2, $lon2) {
    $earthRadius = 6371000; // Radius Bumi dalam meter
    
    $latFrom = deg2rad($lat1);
    $lonFrom = deg2rad($lon1);
    $latTo = deg2rad($lat2);
    $lonTo = deg2rad($lon2);
    
    $latDelta = $latTo - $latFrom;
    $lonDelta = $lonTo - $lonFrom;
    
    $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
        cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));
        
    return $angle * $earthRadius;
}
```

---

## 5. Simulation & Example Coordinates

Berikut adalah simulasi nilai koordinat nyata yang memicu jarak **11,951,729 meter**:

| Parameter | Tipe Koordinat | Nilai | Catatan |
|:---|:---|:---|:---|
| **`$lat1`, `$lon1`** | **User Location** | `(0.00000000, 0.00000000)` | **Null Island** (Ekuator, Teluk Guinea, Afrika) |
| **`$lat2`, `$lon2`** | **Hotel Location** | `(-6.91400000, 107.61670000)` | Hotel **Dago Sky** (Bandung, Indonesia) |
| **`$allowedRadius`** | **Geofence Radius** | `150` | Batas maksimum toleransi (meter) |
| **`$distance`** | **Calculated Distance** | **`11,951,724.77` m** | **~11,951 km** (Sesuai dengan log kesalahan Anda) |

---

## 6. Root Cause Analysis

Pesan kesalahan dengan jarak sekitar **11,951,729 meter** (11,951 kilometer) disebabkan oleh perangkat pengguna yang melaporkan koordinat **`0.0` (Latitude)** dan **`0.0` (Longitude)** ke server (dikenal sebagai *Null Island*).

### Kemungkinan Penyebab Utama:
1. **Mock Location / GPS Emulator Belum Ter-set**: User menggunakan Emulator Android / iOS atau aplikasi Mock GPS yang diaktifkan, tetapi koordinat palsunya belum dimasukkan (sehingga secara default melaporkan titik `0.0, 0.0`).
2. **GPS HP Mengalami Time-Out / Gagal Mengunci Sinyal**: HP fisik mematikan sensor GPS atau terhalang gedung tebal, sehingga koordinat mengembalikan nilai default fallback `0.0, 0.0`.
3. **Pemuatan Awal GPS**: Package `Geolocator` mengambil koordinat terakhir (*last known location*) yang bernilai `null` / `0.0` sebelum sensor GPS aktif sepenuhnya.

---

## 7. Recommendations

Untuk meningkatkan keandalan pelaporan lokasi di sisi aplikasi Flutter:
1. **Validasi Frontend Terhadap Null Island**: Tambahkan pengecekan di `LocationServiceImpl.getCurrentLocation()` atau `AttendanceController`. Jika mendeteksi koordinat tepat `0.0, 0.0`, batalkan request Check In dan tampilkan pesan ramah pengguna: *"Gagal mendapatkan sinyal GPS yang valid. Pastikan GPS Anda aktif dan berada di luar ruangan."*
2. **Memaksa Refresh Koordinat**: Hindari pemakaian *cached location* jika nilainya tidak akurat. Gunakan `Geolocator.getCurrentPosition` dengan memaksa sensor GPS melakukan pemindaian segar.
3. **Penyediaan Tombol Reload Lokasi**: Berikan tombol indikator status GPS dan tombol refresh manual di halaman Dashboard agar staf bisa memperbarui koordinat sebelum menekan tombol absensi.
