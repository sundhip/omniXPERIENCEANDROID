import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/database/app_database.dart';

class LearningRepository {
  final ApiClient apiClient;

  LearningRepository({required this.apiClient});

  // --- Dashboard ---
  Future<LearnDashboardModel> getDashboard({bool forceRefresh = false}) async {
    try {
      final res = await apiClient.dio.get('/learning/dashboard');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final model = LearnDashboardModel.fromJson(res.data);
        await SecureStorage.saveLearnDashboardCache(jsonEncode(res.data));
        return model;
      }
    } catch (_) {
      final cached = await SecureStorage.getLearnDashboardCache();
      if (cached != null) {
        return LearnDashboardModel.fromJson(jsonDecode(cached));
      }
    }
    return const LearnDashboardModel();
  }

  // --- Learning Items ---
  Future<List<LearningItemModel>> getLearningItems({String? category, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }

      final res = await apiClient.dio.get('/learning', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data is List) {
        final list = (res.data as List).map((x) => LearningItemModel.fromJson(x)).toList();
        await SecureStorage.saveLearningCache(jsonEncode(res.data));
        return list;
      }
    } catch (_) {
      final cached = await SecureStorage.getLearningCache();
      if (cached != null) {
        final list = (jsonDecode(cached) as List).map((x) => LearningItemModel.fromJson(x)).toList();
        if (category != null && category.isNotEmpty && category != 'All') {
          return list.where((i) => i.category == category).toList();
        }
        return list;
      }
    }
    return [];
  }

  Future<LearningItemModel> createLearningItem(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/learning', data: data);
    return LearningItemModel.fromJson(res.data);
  }

  Future<LearningItemModel> updateLearningItem(String id, Map<String, dynamic> data) async {
    final res = await apiClient.dio.put('/learning/$id', data: data);
    return LearningItemModel.fromJson(res.data);
  }

  Future<void> deleteLearningItem(String id) async {
    await apiClient.dio.delete('/learning/$id');
  }

  // --- Goals ---
  Future<List<GoalModel>> getGoals({String? category, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }

      final res = await apiClient.dio.get('/goals', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data is List) {
        final list = (res.data as List).map((x) => GoalModel.fromJson(x)).toList();
        await SecureStorage.saveGoalsCache(jsonEncode(res.data));
        return list;
      }
    } catch (_) {
      final cached = await SecureStorage.getGoalsCache();
      if (cached != null) {
        return (jsonDecode(cached) as List).map((x) => GoalModel.fromJson(x)).toList();
      }
    }
    return [];
  }

  Future<GoalModel> createGoal(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/goals', data: data);
    return GoalModel.fromJson(res.data);
  }

  Future<GoalModel> updateGoal(String id, Map<String, dynamic> data) async {
    final res = await apiClient.dio.put('/goals/$id', data: data);
    return GoalModel.fromJson(res.data);
  }

  Future<void> deleteGoal(String id) async {
    await apiClient.dio.delete('/goals/$id');
  }

  Future<GoalModel> toggleGoalMilestone(String goalId, String milestoneId) async {
    final res = await apiClient.dio.post('/goals/$goalId/milestones/$milestoneId/toggle');
    return GoalModel.fromJson(res.data);
  }

  Future<GoalPlanRecommendationModel> planGoal(String goalId) async {
    final res = await apiClient.dio.post('/goals/$goalId/plan');
    return GoalPlanRecommendationModel.fromJson(res.data);
  }

  // --- Study Sessions ---
  Future<List<StudySessionModel>> getStudySessions() async {
    try {
      final res = await apiClient.dio.get('/study-sessions');
      if (res.statusCode == 200 && res.data is List) {
        final list = (res.data as List).map((x) => StudySessionModel.fromJson(x)).toList();
        await SecureStorage.saveSessionsCache(jsonEncode(res.data));
        return list;
      }
    } catch (_) {
      final cached = await SecureStorage.getSessionsCache();
      if (cached != null) {
        return (jsonDecode(cached) as List).map((x) => StudySessionModel.fromJson(x)).toList();
      }
    }
    return [];
  }

  Future<StudySessionModel> createStudySession(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/study-sessions', data: data);
    return StudySessionModel.fromJson(res.data);
  }

  // --- Knowledge Notes ---
  Future<List<KnowledgeNoteModel>> getKnowledgeNotes({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      final res = await apiClient.dio.get('/notes', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data is List) {
        final list = (res.data as List).map((x) => KnowledgeNoteModel.fromJson(x)).toList();
        await SecureStorage.saveNotesCache(jsonEncode(res.data));
        return list;
      }
    } catch (_) {
      final cached = await SecureStorage.getNotesCache();
      if (cached != null) {
        return (jsonDecode(cached) as List).map((x) => KnowledgeNoteModel.fromJson(x)).toList();
      }
    }
    return [];
  }

  Future<KnowledgeNoteModel> createKnowledgeNote(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/notes', data: data);
    return KnowledgeNoteModel.fromJson(res.data);
  }

  Future<void> deleteKnowledgeNote(String id) async {
    await apiClient.dio.delete('/notes/$id');
  }

  // --- Projects ---
  Future<List<ProjectModel>> getProjects() async {
    try {
      final res = await apiClient.dio.get('/projects');
      if (res.statusCode == 200 && res.data is List) {
        final list = (res.data as List).map((x) => ProjectModel.fromJson(x)).toList();
        await SecureStorage.saveProjectsCache(jsonEncode(res.data));
        return list;
      }
    } catch (_) {
      final cached = await SecureStorage.getProjectsCache();
      if (cached != null) {
        return (jsonDecode(cached) as List).map((x) => ProjectModel.fromJson(x)).toList();
      }
    }
    return [];
  }

  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    final res = await apiClient.dio.post('/projects', data: data);
    return ProjectModel.fromJson(res.data);
  }

  Future<ProjectModel> updateProject(String id, Map<String, dynamic> data) async {
    final res = await apiClient.dio.put('/projects/$id', data: data);
    return ProjectModel.fromJson(res.data);
  }

  Future<void> deleteProject(String id) async {
    await apiClient.dio.delete('/projects/$id');
  }
}
