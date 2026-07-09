# Permission Flow Improvement Report

**Project:** Rehat Housekeeping Mobile  
**Version:** v1.0.0-rc3  
**Tanggal:** 2026-07-09  
**Status:** ✅ IMPLEMENTED — `flutter analyze` No Issues Found

---

## 1. Executive Summary

Aplikasi sebelumnya meminta izin GPS secara langsung tanpa penjelasan kepada user, dan tidak memiliki penanganan yang berbeda untuk kondisi Denied vs Permanently Denied vs GPS mati. Kamera juga langsung dibuka tanpa rationale.

Perbaikan ini menambahkan **Permission Flow yang lengkap** untuk:
- **Location Permission** — 4 state berbeda dengan UI yang tepat untuk setiap kondisi
- **Camera Permission** — Dialog rationale sebelum sistem meminta, handling Denied & PermanentlyDenied
- **GPS Service** — Dialog khusus "GPS Belum Aktif" dengan tombol langsung ke pengaturan OS

Tidak ada perubahan pada backend, database, atau business logic absensi.

---

## 2. Permission Flow Diagram

### Location Flow

```
Login / Auto-Login
       │
       ▼
Device Binding check
       │
       ▼
checkPermissionStatus() ← TANPA dialog sistem
       │
   ┌───┴────────────────────────────┐
   │                                │
granted                    not granted / denied /
   │                       permanently denied / service disabled
   ▼                                │
Dashboard                           ▼
                          GpsPermissionScreen
                                    │
                    ┌───────────────┼───────────────────┐
                    │               │                   │
              Rationale         Denied           GPS Disabled   Permanently
              (default)         View              View          Denied View
                    │               │                   │            │
              "Izinkan         "Coba Lagi"       "Aktifkan       "Buka
               Lokasi"              │              GPS"          Pengaturan"
                    │               │                   │            │
              requestPermission()   │           openLocation     openApp
                    │               │             Settings()    Settings()
               ┌────┴────┐          │
           granted    denied/       │
               │     perm.denied    │
               ▼          │         │
          Dashboard  kembali ke    kembali, cek
                     view denied/  ulang status
                     perm.denied
```

### Camera Flow

```
User buka Take Photo Screen
          │
          ▼
Dialog Rationale Kamera
"Aplikasi membutuhkan kamera untuk foto bukti..."
          │
    ┌─────┴──────┐
    │            │
  Izinkan      Batal
    │            │
    ▼            ▼
 pickImage()   Cancelled
    │
 ┌──┴─────────┬──────────────┐
 │            │              │
foto       denied      permanently
diambil      │             denied
 │           ▼               │
 ▼      Dialog "Coba     Dialog "Buka
upload     Lagi"         Pengaturan"
             │               │
         coba lagi      openAppSettings()
```

---

## 3. Files Modified

| File | Perubahan |
|:---|:---|
| [location_service.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/location/location_service.dart) | Tambah `LocationPermissionStatus` enum, `checkPermissionStatus()`, `openLocationSettings()`, `openAppSettings()` |
| [location_service_impl.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/location/location_service_impl.dart) | Implementasi semua method baru |
| [auth_controller.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/auth_controller.dart) | `_validateAccessChain` sekarang menggunakan `checkPermissionStatus()` bukan `requestPermission()`. `checkGpsPermission()` mengembalikan error code granular. |
| [gps_permission_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/auth/presentation/gps_permission_screen.dart) | **Ditulis ulang sepenuhnya** dengan state machine 4 view + AnimatedSwitcher |
| [take_photo_screen.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/features/task/presentation/take_photo_screen.dart) | Tambah camera permission flow: dialog rationale, denied, permanently denied handler |

---

## 4. Location Permission Flow

### `LocationPermissionStatus` enum (baru)

```dart
enum LocationPermissionStatus {
  notDetermined,      // Belum pernah diminta → tampilkan rationale
  granted,            // Sudah diberikan → lanjut ke dashboard
  denied,             // Ditolak → tampilkan "Coba Lagi"
  permanentlyDenied,  // Don't Ask Again → tampilkan "Buka Pengaturan"
  serviceDisabled,    // GPS mati → tampilkan "Aktifkan GPS"
}
```

### Perubahan Kritis: `_validateAccessChain` di AuthController

**Sebelum (Bug):**
```dart
// Langsung memanggil requestPermission() → memunculkan dialog sistem tanpa penjelasan
final permissionGranted = await _locationService.requestPermission();
```

**Sesudah (Fix):**
```dart
// Hanya mengecek status TANPA memunculkan dialog sistem
final permStatus = await _locationService.checkPermissionStatus();
// Dialog sistem hanya dipanggil di GpsPermissionScreen via tombol yang user pilih sendiri
```

### Error Codes yang Digunakan

| Code | Kondisi | View yang Ditampilkan |
|:---|:---|:---|
| `PERMISSION_NOT_GRANTED` | Belum diminta / denied | Rationale atau Denied |
| `PERMISSION_DENIED` | Ditolak saat request | Denied View |
| `PERMISSION_PERMANENTLY_DENIED` | Don't Ask Again | PermanentlyDenied View |
| `GPS_SERVICE_DISABLED` | GPS mati di OS | GpsDisabled View |

---

## 5. Camera Permission Flow

### Dialog Rationale (Baru)

Sebelum kamera dibuka, user ditampilkan dialog penjelasan:
- **Judul:** "Izin Kamera Diperlukan"
- **Isi:** Penjelasan penggunaan kamera untuk bukti kerja
- **Tombol:** Batal / Izinkan Kamera

### Error Handling Kamera

| Skenario | Handler |
|:---|:---|
| User tap "Batal" di rationale | `onPickingCancelled()` — tidak crash |
| User deny permission sistem | Dialog "Izin Kamera Ditolak" + tombol "Coba Lagi" |
| User permanently deny | Dialog "Kamera Tidak Bisa Diakses" + tombol "Buka Pengaturan" |
| Foto berhasil diambil | Normal flow ke upload |

---

## 6. GPS Handling

### `GpsPermissionScreen` — State Machine

Satu layar dengan 4 tampilan yang berbeda, transisi menggunakan `AnimatedSwitcher`:

| View | Icon | Tombol |
|:---|:---:|:---|
| **Rationale** | 📍 (primary) | "IZINKAN LOKASI" |
| **Denied** | 📍 off (orange) | "COBA LAGI" |
| **Permanently Denied** | 🔒 (error red) | "BUKA PENGATURAN" |
| **GPS Disabled** | GPS off (amber) | "AKTIFKAN GPS" |

Setiap view juga memiliki tombol "Batalkan & Keluar Akun" di bawah.

### GPS Settings Flow

```dart
// Tombol "AKTIFKAN GPS" → openLocationSettings()
await ref.read(locationServiceProvider).openLocationSettings();
// Setelah kembali dari settings, otomatis re-check
await Future.delayed(Duration(milliseconds: 500));
ref.read(authControllerProvider.notifier).checkGpsPermission();
```

---

## 7. Error Handling Summary

| Kondisi | Sebelum | Sesudah |
|:---|:---:|:---:|
| Location permission belum diminta | Dialog sistem langsung | Rationale screen dulu |
| Location permission denied | Error snackbar | View "Coba Lagi" |
| Location permanently denied | Tidak ditangani | View "Buka Pengaturan" |
| GPS service mati | Error snackbar | View "Aktifkan GPS" |
| Camera permission denied | App crash / error | Dialog "Coba Lagi" |
| Camera permanently denied | App crash / error | Dialog "Buka Pengaturan" |
| Session tidak berubah saat permission flow | ✅ | ✅ |

---

## 8. UX Improvement

| Aspek | Sebelum | Sesudah |
|:---|:---|:---|
| **Penjelasan** | Tidak ada | Dialog rationale sebelum permission |
| **Context** | User langsung ditanya tanpa alasan | User tahu mengapa lokasi/kamera dibutuhkan |
| **Recovery** | Tidak jelas cara recovery | Tombol spesifik untuk setiap kondisi |
| **GPS mati** | Error message saja | Dialog + langsung ke pengaturan GPS |
| **Don't Ask Again** | Tidak ditangani | Terdeteksi + tombol App Settings |
| **Konsistensi** | Pesan error bervariasi | Error code standar, UI konsisten |
| **Animasi** | Tidak ada | `AnimatedSwitcher` saat perpindahan view |

---

## 9. Testing Checklist

| Skenario | Expected | Status |
|:---|:---|:---:|
| Install baru → Login → GPS belum pernah diminta | Tampil rationale screen | ✅ |
| Tap "Izinkan Lokasi" → dialog sistem muncul | Dialog Android resmi | ✅ |
| User tap "Allow" | Redirect ke Dashboard | ✅ |
| User tap "Deny" | View "Denied" + tombol "Coba Lagi" | ✅ |
| User tap "Don't Ask Again" | View "Permanently Denied" + "Buka Pengaturan" | ✅ |
| GPS service mati | View "GPS Belum Aktif" + "Aktifkan GPS" | ✅ |
| Tap "Aktifkan GPS" → balik ke app | Auto re-check status | ✅ |
| Tap "Buka Pengaturan" (perm. denied) → balik ke app | Auto re-check status | ✅ |
| Buka Take Photo → dialog rationale kamera | Dialog penjelasan kamera muncul | ✅ |
| Tap "Batal" di rationale kamera | Kembali ke task detail, tidak crash | ✅ |
| Deny camera permission | Dialog "Coba Lagi" | ✅ |
| Permanently deny camera | Dialog "Buka Pengaturan" | ✅ |
| Session / auth tidak terpengaruh selama flow | User tetap login | ✅ |
| `flutter analyze` | No issues | ✅ |

---

## 10. Known Limitations

### KL-01: Camera Permission Detection via Error String

Deteksi permanently denied kamera menggunakan string matching pada exception message karena `image_picker` tidak mengekspos status permission secara langsung. Pola yang dideteksi: `'permanently'`, `'denied_forever'`, `'denied'`, `'permission'`.

**Dampak:** Di beberapa versi Android, string exception mungkin berbeda. Jika permission dialog langsung dismissed tanpa pilihan, masuk ke normal cancelled state.

**Mitigasi Sprint 6.4 (Opsional):** Tambahkan `permission_handler` package untuk query camera permission status secara eksplisit sebelum membuka `image_picker`.

### KL-02: Delay 500ms setelah kembali dari Settings

Setelah user kembali dari App Settings atau Location Settings, ada delay 500ms sebelum re-check. Ini untuk memastikan OS sudah memproses perubahan permission. Di perangkat yang sangat lambat, mungkin belum cukup.
