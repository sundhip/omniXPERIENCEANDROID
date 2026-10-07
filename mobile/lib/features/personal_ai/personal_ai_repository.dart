import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import 'models/personal_ai_models.dart';

class PersonalAiRepository {
  final ApiClient apiClient;

  PersonalAiRepository({required this.apiClient});

  Future<AssistantMessageModel> askAssistant(String prompt) async {
    try {
      final res = await apiClient.dio.post('/personal-ai/ask', data: {
        'prompt': prompt,
      });
      final msg = AssistantMessageModel.fromJson(res.data);
      await _appendChatHistory(msg);
      return msg;
    } on DioException catch (_) {
      // Offline fallback: Generate realistic local response
      final fallbackMsg = AssistantMessageModel(
        id: 'msg_offline_${DateTime.now().millisecondsSinceEpoch}',
        prompt: prompt,
        response: 'Currently operating in offline mode. Context will synchronize once your connection is restored.',
        epistemicLevel: 'UNCERTAIN',
        referencedDomains: const ['productivity'],
        citations: const ['Local Cache: Offline fallback'],
        createdAt: DateTime.now(),
      );
      await _appendChatHistory(fallbackMsg);
      return fallbackMsg;
    }
  }

  Future<bool> executeAction(String proposalId, {bool confirm = true}) async {
    try {
      final res = await apiClient.dio.post('/personal-ai/actions/execute', data: {
        'proposal_id': proposalId,
        'confirm': confirm,
      });
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<DailyPersonalBriefModel> getDailyBrief() async {
    try {
      final res = await apiClient.dio.get('/personal-ai/daily-brief');
      final brief = DailyPersonalBriefModel.fromJson(res.data);
      await SecureStorage.saveDailyBriefCache(jsonEncode(brief.toJson()));
      return brief;
    } catch (_) {
      final cached = await SecureStorage.getDailyBriefCache();
      if (cached != null) {
        return DailyPersonalBriefModel.fromJson(jsonDecode(cached));
      }
      return DailyPersonalBriefModel(
        date: DateTime.now().toIso8601String().substring(0, 10),
        greeting: 'Good day',
        userName: 'Alex',
        focus: 'Review your upcoming priorities and tasks.',
        plan: 'Focus on high-priority goals today.',
        prepare: 'Clear day ahead.',
        wellness: 'Stay hydrated and maintain your routines.',
      );
    }
  }

  Future<List<ProactiveInsightModel>> getProactiveInsights() async {
    try {
      final res = await apiClient.dio.get('/personal-ai/insights');
      final list = (res.data as List).map((x) => ProactiveInsightModel.fromJson(x)).toList();
      await SecureStorage.saveInsightsCache(jsonEncode(list.map((i) => i.toJson()).toList()));
      return list;
    } catch (_) {
      final cached = await SecureStorage.getInsightsCache();
      if (cached != null) {
        return (jsonDecode(cached) as List).map((x) => ProactiveInsightModel.fromJson(x)).toList();
      }
      return [];
    }
  }

  Future<bool> dismissInsight(String insightId) async {
    try {
      await apiClient.dio.post('/personal-ai/insights/$insightId/dismiss');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<UserMemoryModel>> getMemories() async {
    try {
      final res = await apiClient.dio.get('/personal-ai/memories');
      final list = (res.data as List).map((x) => UserMemoryModel.fromJson(x)).toList();
      await SecureStorage.saveMemoriesCache(jsonEncode(list.map((m) => m.toJson()).toList()));
      return list;
    } catch (_) {
      final cached = await SecureStorage.getMemoriesCache();
      if (cached != null) {
        return (jsonDecode(cached) as List).map((x) => UserMemoryModel.fromJson(x)).toList();
      }
      return [];
    }
  }

  Future<bool> deleteMemory(String memoryId) async {
    try {
      await apiClient.dio.delete('/personal-ai/memories/$memoryId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<AssistantMessageModel>> getChatHistory() async {
    final cached = await SecureStorage.getChatHistoryCache();
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).map((x) => AssistantMessageModel.fromJson(x)).toList();
        return list;
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<void> _appendChatHistory(AssistantMessageModel msg) async {
    final current = await getChatHistory();
    current.add(msg);
    // Keep max 30 recent messages for privacy and performance
    final trimmed = current.length > 30 ? current.sublist(current.length - 30) : current;
    await SecureStorage.saveChatHistoryCache(jsonEncode(trimmed.map((m) => m.toJson()).toList()));
  }

  Future<void> clearChatHistory() async {
    await SecureStorage.saveChatHistoryCache(jsonEncode([]));
  }
}
