/// Konstanta global untuk seluruh aplikasi Rehat Housekeeping Mobile
class AppConstants {
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Endpoint API (Sesuai dengan hasil reverse engineering backend PHP)
  static const String pathLogin = '/login.php';
  static const String pathAuthCheck = '/api_auth_check.php';
  static const String pathQaHistory = '/QA/api_get_qa_history.php';
  static const String pathQaDetails = '/QA/api_get_qa_audit_details.php';
  static const String pathSaveAudit = '/QA/api_save_qa_audit.php';
  static const String pathUpdateCap = '/QA/api_update_cap_status.php';
  static const String pathDeleteAudit = '/QA/api_delete_qa_audit.php';
  static const String pathLogout = '/logout.php';
  static const String pathValidateDevice = '/Housekeeping/api_validate_device.php';
  static const String pathRegisterDevice = '/Housekeeping/api_register_device.php';
  static const String pathRegister = '/api_register.php';
  static const String pathRegistrationStatus = '/api_registration_status.php';

  // Local Storage Keys
  static const String keyUserSession = 'user_session_data';
  static const String keyHiveCacheBox = 'housekeeping_offline_cache';
}
