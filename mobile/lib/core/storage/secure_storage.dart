import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'op_access_token';
  static const _userIdKey = 'op_user_id';
  static const _userEmailKey = 'op_user_email';
  static const _displayNameKey = 'op_display_name';
  static const _onboardingCompletedKey = 'op_onboarding_completed';
  static const _wardrobeCacheKey = 'op_wardrobe_cache';

  static Future<void> saveSession({
    required String token,
    required String userId,
    required String email,
    String? displayName,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userEmailKey, value: email);
    if (displayName != null) {
      await _storage.write(key: _displayNameKey, value: displayName);
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  static Future<String?> getDisplayName() async {
    return await _storage.read(key: _displayNameKey);
  }

  static Future<void> setDisplayName(String name) async {
    await _storage.write(key: _displayNameKey, value: name);
  }

  static Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(key: _onboardingCompletedKey);
    return value == 'true';
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    await _storage.write(key: _onboardingCompletedKey, value: completed ? 'true' : 'false');
  }

  static Future<String?> getWardrobeCache() async {
    return await _storage.read(key: _wardrobeCacheKey);
  }

  static Future<void> saveWardrobeCache(String jsonStr) async {
    await _storage.write(key: _wardrobeCacheKey, value: jsonStr);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _displayNameKey);
    // Note: Do not clear onboarding completion flag on simple logout,
    // so returning user doesn't have to redo onboarding unless explicit reset
  }

  static Future<void> resetAll() async {
    await _storage.deleteAll();
  }
}
