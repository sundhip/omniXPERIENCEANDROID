import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import 'models/visual_profile_model.dart';

class VisualProfileRepository {
  final ApiClient apiClient;

  VisualProfileRepository({required this.apiClient});

  /// Fetches the user's existing visual profile, if any
  Future<VisualProfileModel?> getVisualProfile() async {
    try {
      final res = await apiClient.dio.get('/profile/visual-profile');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return VisualProfileModel.fromJson(res.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Profile does not exist yet
      }
      rethrow;
    }
  }

  /// Sends image for real computer-vision analysis
  /// (MediaPipe BlazeFace + 478 Landmark Proportions + CIELAB/ITA + Frequency Texture)
  Future<VisualProfileModel> analyzeImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'selfie.jpg',
      ),
    });

    try {
      final res = await apiClient.dio.post(
        '/profile/visual-profile/analyze',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final profileData = data['visual_profile'] ?? data['profile'];
        if (profileData != null && profileData is Map<String, dynamic>) {
          return VisualProfileModel.fromJson(profileData);
        } else if (data['success'] == false) {
          throw Exception(data['error']?.toString() ?? data['message']?.toString() ?? 'Face analysis could not be completed.');
        }
      }
      throw Exception('Unexpected response format from face analysis server.');
    } on DioException catch (e) {
      final errorMsg = ApiClient.getErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// User review confirmation & manual override
  Future<VisualProfileModel> confirmVisualProfile({
    String? confirmedFaceShape,
    String? confirmedSkinTone,
    String? confirmedUndertone,
    String? confirmedHairType,
    String? hairColor,
  }) async {
    final payload = <String, dynamic>{};
    if (confirmedFaceShape != null) payload['confirmed_face_shape'] = confirmedFaceShape;
    if (confirmedSkinTone != null) payload['confirmed_skin_tone'] = confirmedSkinTone;
    if (confirmedUndertone != null) {
      payload['confirmed_skin_undertone'] = confirmedUndertone;
      payload['confirmed_undertone'] = confirmedUndertone;
    }
    if (confirmedHairType != null) {
      payload['confirmed_hair_texture'] = confirmedHairType;
      payload['confirmed_hair_type'] = confirmedHairType;
    }
    if (hairColor != null) payload['hair_color'] = hairColor;

    try {
      final res = await apiClient.dio.put(
        '/profile/visual-profile/confirm',
        data: payload,
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return VisualProfileModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update confirmed visual profile');
    } on DioException catch (e) {
      final errorMsg = ApiClient.getErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// Deletes the visual profile and associated image
  Future<void> deleteVisualProfile() async {
    try {
      await apiClient.dio.delete('/profile/visual-profile');
    } on DioException catch (e) {
      final errorMsg = ApiClient.getErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// Retrieves Context Engine personal visual context for downstream AI
  Future<Map<String, dynamic>?> getVisualContext() async {
    try {
      final res = await apiClient.dio.get('/profile/visual-profile/context');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
