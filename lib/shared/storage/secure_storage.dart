import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// KLE HOMECARE — Secure Token Storage
///
/// Platform strategy:
///   Mobile / Desktop  →  flutter_secure_storage  (encrypted keychain/keystore)
///   Web               →  SharedPreferences        (localStorage)
///
/// flutter_secure_storage uses the Web Crypto API which requires HTTPS.
/// On plain http://127.0.0.1 (local dev) it throws OperationError, so we
/// fall back to SharedPreferences on web. In production deploy over HTTPS
/// and you can switch web to flutter_secure_storage too.
class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  // Native secure storage — only used on non-web platforms
  static final _secureStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey  = 'kle_access_token';
  static const _refreshTokenKey = 'kle_refresh_token';
  static const _userRoleKey     = 'kle_user_role';
  static const _userIdKey       = 'kle_user_id';
  static const _userEmailKey    = 'kle_user_email';
  static const _userNameKey     = 'kle_user_name';

  static const _allKeys = [
    _accessTokenKey,
    _refreshTokenKey,
    _userRoleKey,
    _userIdKey,
    _userEmailKey,
    _userNameKey,
  ];

  // ── Internal read/write that routes by platform ───────────────────────────

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return _secureStorage.read(key: key);
    }
  }

  // ── Access Token ──────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) => _write(_accessTokenKey, token);
  Future<String?> getAccessToken()           => _read(_accessTokenKey);

  // ── Refresh Token ─────────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) => _write(_refreshTokenKey, token);
  Future<String?> getRefreshToken()           => _read(_refreshTokenKey);

  // ── User Info ─────────────────────────────────────────────────────────────
  Future<void> saveUserInfo({
    required String userId,
    required String role,
    required String email,
    required String fullName,
  }) async {
    await Future.wait([
      _write(_userIdKey,    userId),
      _write(_userRoleKey,  role),
      _write(_userEmailKey, email),
      _write(_userNameKey,  fullName),
    ]);
  }

  Future<String?> getUserRole()  => _read(_userRoleKey);
  Future<String?> getUserId()    => _read(_userIdKey);
  Future<String?> getUserEmail() => _read(_userEmailKey);
  Future<String?> getUserName()  => _read(_userNameKey);

  // ── Save All (after login) ────────────────────────────────────────────────
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String role,
    required String email,
    required String fullName,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserInfo(
        userId:   userId,
        role:     role,
        email:    email,
        fullName: fullName,
      ),
    ]);
  }

  // ── Clear All (on logout) ─────────────────────────────────────────────────
  Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait(_allKeys.map((k) => prefs.remove(k)));
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // ── Check if logged in ────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
