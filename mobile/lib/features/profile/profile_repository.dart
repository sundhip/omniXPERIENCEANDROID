import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import 'models/user_profile_model.dart';

class ProfileRepository {
  final ApiClient apiClient;

  ProfileRepository({required this.apiClient});

  /// Fetches the current user's full profile from the backend,
  /// falling back to local secure storage if offline.
  Future<UserProfileModel> getFullProfile() async {
    UserProfileModel? cached;
    final cachedStr = await SecureStorage.getProfileCache();
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        cached = UserProfileModel.fromJson(jsonDecode(cachedStr));
      } catch (_) {}
    }

    try {
      final res = await apiClient.dio.get('/profile/full');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final profile = UserProfileModel.fromJson(res.data);
        await saveCachedProfile(profile);
        if (profile.displayName.isNotEmpty) {
          await SecureStorage.setDisplayName(profile.displayName);
        }
        if (profile.onboardingCompleted) {
          await SecureStorage.setOnboardingCompleted(true);
        }
        return profile;
      }
    } catch (e) {
      if (cached != null) {
        return cached;
      }
      rethrow;
    }

    if (cached != null) return cached;
    // Default initial profile if neither remote nor cache exist
    final name = await SecureStorage.getDisplayName() ?? 'User';
    final email = await SecureStorage.getUserEmail();
    return UserProfileModel(displayName: name, email: email);
  }

  /// Updates the profile both remotely and in the local cache.
  Future<UserProfileModel> updateFullProfile(UserProfileModel profile) async {
    // 1. Optimistically cache locally
    await saveCachedProfile(profile);
    if (profile.displayName.isNotEmpty) {
      await SecureStorage.setDisplayName(profile.displayName);
    }
    if (profile.onboardingCompleted) {
      await SecureStorage.setOnboardingCompleted(true);
    }

    // 2. Transmit to backend
    final payload = profile.toJson();
    final res = await apiClient.dio.put('/profile/full', data: payload);
    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      final updated = UserProfileModel.fromJson(res.data);
      await saveCachedProfile(updated);
      return updated;
    }
    return profile;
  }

  Future<UserProfileModel?> getCachedProfile() async {
    final cachedStr = await SecureStorage.getProfileCache();
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        return UserProfileModel.fromJson(jsonDecode(cachedStr));
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveCachedProfile(UserProfileModel profile) async {
    await SecureStorage.saveProfileCache(jsonEncode(profile.toJson()));
  }
}
