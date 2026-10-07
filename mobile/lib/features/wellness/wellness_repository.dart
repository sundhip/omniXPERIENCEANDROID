import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/database/app_database.dart';

class WellnessRepository {
  final ApiClient apiClient;

  WellnessRepository({required this.apiClient});

  Future<TodayWellnessModel> getTodayWellness() async {
    try {
      final res = await apiClient.dio.get('/wellness/today');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        await SecureStorage.saveWellnessCache(jsonEncode(res.data));
        return TodayWellnessModel.fromJson(res.data);
      }
    } catch (_) {
      final cached = await SecureStorage.getWellnessCache();
      if (cached != null) {
        return TodayWellnessModel.fromJson(jsonDecode(cached));
      }
    }
    return TodayWellnessModel(
      date: DateTime.now().toIso8601String().split('T').first,
    );
  }

  Future<List<HabitModel>> getHabits() async {
    try {
      final res = await apiClient.dio.get('/habits');
      if (res.statusCode == 200 && res.data is List) {
        await SecureStorage.saveHabitsCache(jsonEncode(res.data));
        return (res.data as List).map((x) => HabitModel.fromJson(x)).toList();
      }
    } catch (_) {
      final cached = await SecureStorage.getHabitsCache();
      if (cached != null) {
        return (jsonDecode(cached) as List).map((x) => HabitModel.fromJson(x)).toList();
      }
    }
    return [];
  }

  Future<HabitModel> createHabit(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/habits', data: data);
    return HabitModel.fromJson(res.data);
  }

  Future<HabitModel> updateHabit(String id, Map<String, dynamic> data) async {
    final res = await apiClient.dio.put('/habits/$id', data: data);
    return HabitModel.fromJson(res.data);
  }

  Future<void> deleteHabit(String id) async {
    await apiClient.dio.delete('/habits/$id');
  }

  Future<void> logHabit({
    required String habitId,
    required String logDate,
    required String status,
    int count = 1,
  }) async {
    await apiClient.dio.post('/habits/$habitId/log', data: {
      'log_date': logDate,
      'status': status,
      'count': count,
    });
  }

  Future<SkincareProfileModel?> getSkincareProfile() async {
    try {
      final res = await apiClient.dio.get('/wellness/skincare-profile');
      if (res.statusCode == 200 && res.data != null) {
        return SkincareProfileModel.fromJson(res.data);
      }
    } catch (_) {}
    return null;
  }

  Future<SkincareProfileModel> saveSkincareProfile(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/wellness/skincare-profile', data: data);
    return SkincareProfileModel.fromJson(res.data);
  }

  Future<List<RoutineProductModel>> getRoutines({String? timeOfDay}) async {
    try {
      final params = <String, dynamic>{};
      if (timeOfDay != null) params['time_of_day'] = timeOfDay;
      final res = await apiClient.dio.get('/wellness/routines', queryParameters: params);
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((x) => RoutineProductModel.fromJson(x)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<RoutineProductModel> createRoutineProduct(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/wellness/routines', data: data);
    return RoutineProductModel.fromJson(res.data);
  }

  Future<RoutineProductModel> updateRoutineProduct(String id, Map<String, dynamic> data) async {
    final res = await apiClient.dio.put('/wellness/routines/$id', data: data);
    return RoutineProductModel.fromJson(res.data);
  }

  Future<void> deleteRoutineProduct(String id) async {
    await apiClient.dio.delete('/wellness/routines/$id');
  }

  Future<RoutineProductModel> toggleRoutineProduct(String id) async {
    final res = await apiClient.dio.post('/wellness/routines/$id/toggle');
    return RoutineProductModel.fromJson(res.data);
  }
}
