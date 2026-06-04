import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// KLE HOMECARE — API Constants
///
/// BASE URL STRATEGY:
/// ─────────────────
/// The base URL is stored in SharedPreferences so it can be changed at
/// runtime without rebuilding the APK. This is critical when using ngrok
/// (which gives a new URL every session) or when switching between
/// local dev / staging / production.
///
/// Priority order:
///   1. Value saved in SharedPreferences (set via the debug settings screen)
///   2. Platform default (see _platformDefault below)
///
/// To update the URL at runtime call:
///   await ApiConstants.setBaseUrl('https://your-new-url.ngrok-free.app/api/v1');
///   DioClient.instance.updateBaseUrl(ApiConstants.baseUrl);
class ApiConstants {
  ApiConstants._();

  // ── Shared-prefs key ──────────────────────────────────────────────────────
  static const String _baseUrlKey = 'kle_api_base_url';

  // ── In-memory cache (set during app init) ─────────────────────────────────
  static String _cachedBaseUrl = _platformDefault;

  /// The active base URL — used by DioClient.
  static String get baseUrl => _cachedBaseUrl;

  // ── Platform defaults ─────────────────────────────────────────────────────
  /// Change this constant to your current ngrok / server URL.
  /// This is the fallback when no URL has been saved in SharedPreferences.
  static const String _ngrokUrl =
      'https://homecarebackend.vercel.app/api/v1';

  static String get _platformDefault {
    // Web browsers cannot reach 127.0.0.1 directly — must use ngrok tunnel
    if (kIsWeb) return _ngrokUrl;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8000/api/v1';
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return _ngrokUrl;
      default:
        return _ngrokUrl;
    }
  }

  // ── Init — call once in main() before runApp ──────────────────────────────
  /// Loads the saved URL from SharedPreferences (if any) into the in-memory
  /// cache. Must be awaited before DioClient.init() is called.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_baseUrlKey);
    _cachedBaseUrl = (saved != null && saved.isNotEmpty) ? saved : _platformDefault;
  }

  /// Persist a new base URL and update the in-memory cache.
  /// Call DioClient.instance.updateBaseUrl(ApiConstants.baseUrl) afterwards.
  static Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/$'), ''); // strip trailing /
    final prefs   = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, trimmed);
    _cachedBaseUrl = trimmed;
  }

  /// Clear the saved URL and revert to the platform default.
  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
    _cachedBaseUrl = _platformDefault;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login    = '/auth/login';
  static const String refresh  = '/auth/refresh';
  static const String logout   = '/auth/logout';

  // ── Patient ───────────────────────────────────────────────────────────────
  static const String patientRequests      = '/patient/requests';
  static const String patientNotifications = '/patient/notifications';

  static String patientRequest(String id) => '/patient/requests/$id';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminRequests    = '/admin/requests';
  static const String adminNurses      = '/admin/nurses';
  static const String adminAssignments = '/admin/assignments';
  static const String adminStats       = '/admin/dashboard/stats';

  static String adminRequest(String id)     => '/admin/requests/$id';
  static String adminAssign(String id)      => '/admin/requests/$id/assign';
  static String adminAssignment(String id)  => '/admin/assignments/$id';
  static String adminNurse(String id)       => '/admin/nurses/$id';
  static String adminNurseToggle(String id) => '/admin/nurses/$id/toggle';
  static const String adminCreateNurse     = '/admin/nurses';
  static String adminNursesByCategory(String category) => '/admin/nurses?is_active=true&category=${Uri.encodeComponent(category)}';

  // ── Nurse ─────────────────────────────────────────────────────────────────
  static const String nurseAlerts        = '/nurse/alerts';
  static const String nurseNotifications = '/nurse/notifications';

  static String nurseJob(String id)       => '/nurse/jobs/$id';
  static String nurseJobStatus(String id) => '/nurse/jobs/$id/status';

  // ── Services (catalogue) ──────────────────────────────────────────────────
  static const String services          = '/services';
  static const String serviceCategories = '/services/categories';

  static String service(String id)       => '/services/$id';
  static String serviceToggle(String id) => '/services/$id/toggle';

  // ── Resource Categories ───────────────────────────────────────────────────
  static const String resourceCategories      = '/resource-categories';
  static const String adminResourceCategories = '/admin/resource-categories';

  static String adminResourceCategory(String id) => '/admin/resource-categories/$id';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
