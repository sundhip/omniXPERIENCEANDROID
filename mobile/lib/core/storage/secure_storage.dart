import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const _tokenKey = 'op_access_token';
  static const _userIdKey = 'op_user_id';
  static const _userEmailKey = 'op_user_email';
  static const _displayNameKey = 'op_display_name';
  static const _onboardingCompletedKey = 'op_onboarding_completed';
  static const _wardrobeCacheKey = 'op_wardrobe_cache';
  static const _profileCacheKey = 'op_profile_cache';
  static const _onboardingDraftKey = 'op_onboarding_draft';
  static const _eventsCacheKey = 'op_events_cache';
  static const _tasksCacheKey = 'op_tasks_cache';
  static const _expensesCacheKey = 'op_expenses_cache';
  static const _budgetsCacheKey = 'op_budgets_cache';
  static const _habitsCacheKey = 'op_habits_cache';
  static const _wellnessCacheKey = 'op_wellness_cache';
  static const _learningCacheKey = 'op_learning_cache';
  static const _goalsCacheKey = 'op_goals_cache';
  static const _sessionsCacheKey = 'op_sessions_cache';
  static const _notesCacheKey = 'op_notes_cache';
  static const _projectsCacheKey = 'op_projects_cache';
  static const _learnDashboardCacheKey = 'op_learn_dashboard_cache';
  static const _dailyBriefCacheKey = 'op_daily_brief_cache';
  static const _insightsCacheKey = 'op_insights_cache';
  static const _chatHistoryCacheKey = 'op_chat_history_cache';
  static const _memoriesCacheKey = 'op_memories_cache';

  // --- Safe Core Primitives ---
  static Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      try {
        await _storage.delete(key: key);
      } catch (_) {}
      return null;
    }
  }

  static Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      try {
        await _storage.deleteAll();
        await _storage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  static Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  // --- Session Methods ---
  static Future<void> saveSession({
    required String token,
    required String userId,
    required String email,
    String? displayName,
  }) async {
    await _safeWrite(_tokenKey, token);
    await _safeWrite(_userIdKey, userId);
    await _safeWrite(_userEmailKey, email);
    if (displayName != null) {
      await _safeWrite(_displayNameKey, displayName);
    }
  }

  static Future<String?> getToken() async => _safeRead(_tokenKey);
  static Future<String?> getUserId() async => _safeRead(_userIdKey);
  static Future<String?> getUserEmail() async => _safeRead(_userEmailKey);
  static Future<String?> getDisplayName() async => _safeRead(_displayNameKey);
  static Future<void> setDisplayName(String name) async => _safeWrite(_displayNameKey, name);

  static Future<bool> isOnboardingCompleted() async {
    final value = await _safeRead(_onboardingCompletedKey);
    return value == 'true';
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    await _safeWrite(_onboardingCompletedKey, completed ? 'true' : 'false');
  }

  // --- Caches ---
  static Future<String?> getWardrobeCache() async => _safeRead(_wardrobeCacheKey);
  static Future<void> saveWardrobeCache(String jsonStr) async => _safeWrite(_wardrobeCacheKey, jsonStr);
  static Future<void> setWardrobeCache(String jsonStr) async => saveWardrobeCache(jsonStr);

  static Future<String?> getProfileCache() async => _safeRead(_profileCacheKey);
  static Future<void> saveProfileCache(String jsonStr) async => _safeWrite(_profileCacheKey, jsonStr);

  static Future<String?> getOnboardingDraft() async => _safeRead(_onboardingDraftKey);
  static Future<void> saveOnboardingDraft(String jsonStr) async => _safeWrite(_onboardingDraftKey, jsonStr);

  static Future<String?> getEventsCache() async => _safeRead(_eventsCacheKey);
  static Future<void> saveEventsCache(String jsonStr) async => _safeWrite(_eventsCacheKey, jsonStr);

  static Future<String?> getTasksCache() async => _safeRead(_tasksCacheKey);
  static Future<void> saveTasksCache(String jsonStr) async => _safeWrite(_tasksCacheKey, jsonStr);

  static Future<String?> getExpensesCache() async => _safeRead(_expensesCacheKey);
  static Future<void> saveExpensesCache(String jsonStr) async => _safeWrite(_expensesCacheKey, jsonStr);

  static Future<String?> getBudgetsCache() async => _safeRead(_budgetsCacheKey);
  static Future<void> saveBudgetsCache(String jsonStr) async => _safeWrite(_budgetsCacheKey, jsonStr);

  static Future<String?> getHabitsCache() async => _safeRead(_habitsCacheKey);
  static Future<void> saveHabitsCache(String jsonStr) async => _safeWrite(_habitsCacheKey, jsonStr);

  static Future<String?> getWellnessCache() async => _safeRead(_wellnessCacheKey);
  static Future<void> saveWellnessCache(String jsonStr) async => _safeWrite(_wellnessCacheKey, jsonStr);

  static Future<String?> getLearningCache() async => _safeRead(_learningCacheKey);
  static Future<void> saveLearningCache(String jsonStr) async => _safeWrite(_learningCacheKey, jsonStr);

  static Future<String?> getGoalsCache() async => _safeRead(_goalsCacheKey);
  static Future<void> saveGoalsCache(String jsonStr) async => _safeWrite(_goalsCacheKey, jsonStr);

  static Future<String?> getSessionsCache() async => _safeRead(_sessionsCacheKey);
  static Future<void> saveSessionsCache(String jsonStr) async => _safeWrite(_sessionsCacheKey, jsonStr);

  static Future<String?> getNotesCache() async => _safeRead(_notesCacheKey);
  static Future<void> saveNotesCache(String jsonStr) async => _safeWrite(_notesCacheKey, jsonStr);

  static Future<String?> getProjectsCache() async => _safeRead(_projectsCacheKey);
  static Future<void> saveProjectsCache(String jsonStr) async => _safeWrite(_projectsCacheKey, jsonStr);

  static Future<String?> getLearnDashboardCache() async => _safeRead(_learnDashboardCacheKey);
  static Future<void> saveLearnDashboardCache(String jsonStr) async => _safeWrite(_learnDashboardCacheKey, jsonStr);

  static Future<String?> getDailyBriefCache() async => _safeRead(_dailyBriefCacheKey);
  static Future<void> saveDailyBriefCache(String jsonStr) async => _safeWrite(_dailyBriefCacheKey, jsonStr);

  static Future<String?> getInsightsCache() async => _safeRead(_insightsCacheKey);
  static Future<void> saveInsightsCache(String jsonStr) async => _safeWrite(_insightsCacheKey, jsonStr);

  static Future<String?> getChatHistoryCache() async => _safeRead(_chatHistoryCacheKey);
  static Future<void> saveChatHistoryCache(String jsonStr) async => _safeWrite(_chatHistoryCacheKey, jsonStr);

  static Future<String?> getMemoriesCache() async => _safeRead(_memoriesCacheKey);
  static Future<void> saveMemoriesCache(String jsonStr) async => _safeWrite(_memoriesCacheKey, jsonStr);

  static Future<void> clearOnboardingDraft() async => _safeDelete(_onboardingDraftKey);

  static Future<void> clearSession() async {
    await _safeDelete(_tokenKey);
    await _safeDelete(_userIdKey);
    await _safeDelete(_userEmailKey);
    await _safeDelete(_displayNameKey);
    await _safeDelete(_profileCacheKey);
    await _safeDelete(_onboardingCompletedKey);
    await _safeDelete(_onboardingDraftKey);
  }

  static Future<void> resetAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
