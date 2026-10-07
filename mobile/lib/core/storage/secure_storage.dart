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

  static Future<void> setWardrobeCache(String jsonStr) async {
    await saveWardrobeCache(jsonStr);
  }

  static const _profileCacheKey = 'op_profile_cache';
  static const _onboardingDraftKey = 'op_onboarding_draft';

  static Future<String?> getProfileCache() async {
    return await _storage.read(key: _profileCacheKey);
  }

  static Future<void> saveProfileCache(String jsonStr) async {
    await _storage.write(key: _profileCacheKey, value: jsonStr);
  }

  static Future<String?> getOnboardingDraft() async {
    return await _storage.read(key: _onboardingDraftKey);
  }

  static Future<void> saveOnboardingDraft(String jsonStr) async {
    await _storage.write(key: _onboardingDraftKey, value: jsonStr);
  }

  static const _eventsCacheKey = 'op_events_cache';
  static const _tasksCacheKey = 'op_tasks_cache';

  static Future<String?> getEventsCache() async {
    return await _storage.read(key: _eventsCacheKey);
  }

  static Future<void> saveEventsCache(String jsonStr) async {
    await _storage.write(key: _eventsCacheKey, value: jsonStr);
  }

  static Future<String?> getTasksCache() async {
    return await _storage.read(key: _tasksCacheKey);
  }

  static Future<void> saveTasksCache(String jsonStr) async {
    await _storage.write(key: _tasksCacheKey, value: jsonStr);
  }

  static const _expensesCacheKey = 'op_expenses_cache';
  static const _budgetsCacheKey = 'op_budgets_cache';
  static const _habitsCacheKey = 'op_habits_cache';
  static const _wellnessCacheKey = 'op_wellness_cache';

  static Future<String?> getExpensesCache() async {
    return await _storage.read(key: _expensesCacheKey);
  }

  static Future<void> saveExpensesCache(String jsonStr) async {
    await _storage.write(key: _expensesCacheKey, value: jsonStr);
  }

  static Future<String?> getBudgetsCache() async {
    return await _storage.read(key: _budgetsCacheKey);
  }

  static Future<void> saveBudgetsCache(String jsonStr) async {
    await _storage.write(key: _budgetsCacheKey, value: jsonStr);
  }

  static Future<String?> getHabitsCache() async {
    return await _storage.read(key: _habitsCacheKey);
  }

  static Future<void> saveHabitsCache(String jsonStr) async {
    await _storage.write(key: _habitsCacheKey, value: jsonStr);
  }

  static Future<String?> getWellnessCache() async {
    return await _storage.read(key: _wellnessCacheKey);
  }

  static Future<void> saveWellnessCache(String jsonStr) async {
    await _storage.write(key: _wellnessCacheKey, value: jsonStr);
  }

  static Future<void> clearOnboardingDraft() async {
    await _storage.delete(key: _onboardingDraftKey);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _displayNameKey);
    await _storage.delete(key: _profileCacheKey);
    await _storage.delete(key: _onboardingCompletedKey);
    await _storage.delete(key: _onboardingDraftKey);
  }

  static Future<void> resetAll() async {
    await _storage.deleteAll();
  }
}
