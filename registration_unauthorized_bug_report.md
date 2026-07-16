# Bug Report - Registration 401 Unauthorized

## 1. Root Cause

1. **Backend Server Mismatch (Primary)**: 
   A curl analysis of `https://rehathotelsindonesia.com/api_register.php` reveals that the endpoint on the remote server responds with `HTTP/1.1 401 Unauthorized` and the payload `{"status":"error","success":false,"message":"Unauthorized. Please login first.","redirect":"login.html"}`. 
   
   This message is generated exclusively by `api_auth_check.php`. The root-level script `api_register.php` in the current codebase has NO authentication dependencies and is completely public. However, the server is running an incorrect version of `api_register.php` (likely a copied version of the admin-only registration endpoint `Access_management/api_register.php`), which includes the session authorization checker.

2. **Frontend Interceptor (Secondary)**:
   The Flutter app's global `SessionInterceptor` was appending the `Cookie: PHPSESSID=...` header to all outgoing requests. This sent stale/expired session IDs from previous users to public endpoints (like `/api_register.php`), which could conflict with server-side firewall or session routing logic.

---

## 2. Files Modified

- **Flutter Client**:
  - [dio_client.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/network/dio_client.dart)

---

## 3. Before / After

### [dio_client.dart](file:///d:/Rehat_Hospitality/rehat-hospitality-mobile/lib/core/network/dio_client.dart)

#### Before:
```dart
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final phpSessionId = await _sessionManager.getPhpSessionId();
    if (phpSessionId != null && phpSessionId.isNotEmpty) {
      options.headers['Cookie'] = 'PHPSESSID=$phpSessionId';
    }
    handler.next(options);
  }
```

#### After:
```dart
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // KECUALIKAN endpoint registrasi dari pengiriman session cookie
    if (options.path.contains('api_register.php')) {
      handler.next(options);
      return;
    }

    final phpSessionId = await _sessionManager.getPhpSessionId();
    if (phpSessionId != null && phpSessionId.isNotEmpty) {
      options.headers['Cookie'] = 'PHPSESSID=$phpSessionId';
    }
    handler.next(options);
  }
```

---

## 4. Testing & Verification

1. **Local PHP Compilation Check**:
   Ran local syntax compilation check on the root `api_register.php` file:
   ```bash
   No syntax errors detected in api_register.php
   ```

2. **FCM Separation Validation**:
   Audited `AuthController.register()` and confirmed that `syncFcmToken()` is **never** invoked during registration. The FCM token registration flows only trigger upon successful login states or session recoveries where `userId` is valid.

3. **Required Fix Action**:
   Deploy the root `api_register.php` file from the current branch (`feature/sprint-7.8-flexible-checkout`) to the root of the Hostinger web server to overwrite the incorrect file and restore public access to registration.
