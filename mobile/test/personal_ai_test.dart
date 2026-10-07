import 'package:flutter_test/flutter_test.dart';
import 'package:omnipresence/core/network/api_client.dart';
import 'package:omnipresence/features/personal_ai/models/personal_ai_models.dart';
import 'package:omnipresence/features/personal_ai/personal_ai_bloc.dart';
import 'package:omnipresence/features/personal_ai/personal_ai_repository.dart';

class MockPersonalAiRepository extends PersonalAiRepository {
  MockPersonalAiRepository() : super(apiClient: ApiClient());

  @override
  Future<AssistantMessageModel> askAssistant(String prompt) async {
    return AssistantMessageModel(
      id: 'msg_test_1',
      prompt: prompt,
      response: 'I recommend focusing on your system architecture presentation.',
      epistemicLevel: 'CALCULATED',
      referencedDomains: const ['productivity', 'learning'],
      citations: const ['Calendar: Presentation tomorrow', 'Tasks: 1 high priority'],
      actionProposal: const ActionProposalModel(
        id: 'prop_123',
        actionType: 'create_study_session',
        title: 'Schedule Study Session: Raft',
        description: 'Plan 45m session',
        payload: {'duration': 45},
        requiresConfirmation: true,
        status: 'pending',
      ),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<bool> executeAction(String proposalId, {bool confirm = true}) async {
    return true;
  }

  @override
  Future<DailyPersonalBriefModel> getDailyBrief() async {
    return const DailyPersonalBriefModel(
      date: '2026-10-08',
      greeting: 'Good morning, Alex',
      userName: 'Alex',
      eventsCount: 2,
      priorityTasksCount: 3,
      approachingDeadlinesCount: 1,
      pendingHabitsCount: 2,
      focus: 'Finish system architecture doc',
      plan: 'Study Distributed Systems at 6 PM',
      prepare: 'Rain expected tomorrow',
      wellness: 'Evening routine pending',
    );
  }

  @override
  Future<List<ProactiveInsightModel>> getProactiveInsights() async {
    return [
      ProactiveInsightModel(
        id: 'ins_1',
        insightType: 'high_spending',
        severity: 'urgent',
        title: 'Budget Alert',
        explanation: 'Spent 85% of budget',
        createdAt: DateTime.now(),
      )
    ];
  }

  @override
  Future<List<UserMemoryModel>> getMemories() async {
    return [
      UserMemoryModel(
        id: 'mem_1',
        key: 'preferred_style',
        value: 'Minimalist & Casual',
        domain: 'wardrobe',
        source: 'user_confirmed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    ];
  }

  @override
  Future<List<AssistantMessageModel>> getChatHistory() async {
    return [];
  }

  @override
  Future<bool> dismissInsight(String insightId) async => true;

  @override
  Future<void> clearChatHistory() async {}
}

void main() {
  group('Phase 8 — Models Serialization & Deserialization', () {
    test('ActionProposalModel serialization round-trip', () {
      final prop = ActionProposalModel(
        id: 'prop_001',
        actionType: 'create_task',
        title: 'Prepare Exam Notes',
        description: 'Add urgent task',
        payload: const {'priority': 'Urgent', 'duration': 45},
        requiresConfirmation: true,
        status: 'pending',
        createdAt: DateTime.parse('2026-10-08T10:00:00Z'),
      );

      final json = prop.toJson();
      final fromJson = ActionProposalModel.fromJson(json);

      expect(fromJson.id, 'prop_001');
      expect(fromJson.actionType, 'create_task');
      expect(fromJson.requiresConfirmation, isTrue);
      expect(fromJson.payload['priority'], 'Urgent');
      expect(fromJson.status, 'pending');
    });

    test('AssistantMessageModel preserves epistemicLevel and citations', () {
      final msg = AssistantMessageModel(
        id: 'msg_001',
        prompt: 'What should I wear tomorrow?',
        response: 'Pairs Oxford shirt with tailored trousers.',
        epistemicLevel: 'RECOMMENDED',
        referencedDomains: const ['wardrobe', 'weather'],
        citations: const ['Wardrobe: Available items', 'Weather: 24°C Clear'],
        suggestedFollowups: const ['Show alternative outfit'],
        createdAt: DateTime.parse('2026-10-08T12:00:00Z'),
      );

      final json = msg.toJson();
      final fromJson = AssistantMessageModel.fromJson(json);

      expect(fromJson.epistemicLevel, 'RECOMMENDED');
      expect(fromJson.referencedDomains, contains('wardrobe'));
      expect(fromJson.referencedDomains, contains('weather'));
      expect(fromJson.citations.length, 2);
      expect(fromJson.isUser, isFalse);
    });

    test('DailyPersonalBriefModel round-trip preserves all brief sections', () {
      const brief = DailyPersonalBriefModel(
        date: '2026-10-08',
        greeting: 'Good morning, Alex',
        userName: 'Alex',
        eventsCount: 3,
        priorityTasksCount: 2,
        approachingDeadlinesCount: 1,
        pendingHabitsCount: 1,
        focus: 'Submit Final Report',
        plan: 'Study Go Concurrency',
        prepare: 'Rain showers anticipated',
        wellness: 'Evening skincare completed',
        proactiveAlerts: ['Overloaded schedule detected'],
      );

      final json = brief.toJson();
      final fromJson = DailyPersonalBriefModel.fromJson(json);

      expect(fromJson.eventsCount, 3);
      expect(fromJson.priorityTasksCount, 2);
      expect(fromJson.focus, 'Submit Final Report');
      expect(fromJson.prepare, contains('Rain'));
      expect(fromJson.proactiveAlerts.length, 1);
    });

    test('ProactiveInsightModel round-trip', () {
      final insight = ProactiveInsightModel(
        id: 'ins_100',
        insightType: 'deadline_approaching',
        severity: 'urgent',
        title: 'Deadline in 12h',
        explanation: 'Submit assignment soon',
        supportingData: const {'hours_left': 12},
        recommendedAction: 'Start work block now',
        dismissed: false,
        createdAt: DateTime.parse('2026-10-08T08:00:00Z'),
      );

      final json = insight.toJson();
      final fromJson = ProactiveInsightModel.fromJson(json);

      expect(fromJson.id, 'ins_100');
      expect(fromJson.severity, 'urgent');
      expect(fromJson.insightType, 'deadline_approaching');
      expect(fromJson.dismissed, isFalse);
    });
  });

  group('Phase 8 — PersonalAiBloc Unit Tests', () {
    late PersonalAiBloc bloc;
    late MockPersonalAiRepository repository;

    setUp(() {
      repository = MockPersonalAiRepository();
      bloc = PersonalAiBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state is PersonalAiStatus.initial', () {
      expect(bloc.state.status, PersonalAiStatus.initial);
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.dailyBrief, isNull);
    });

    test('LoadPersonalAiOverviewEvent populates daily brief, insights, and memories', () async {
      bloc.add(const LoadPersonalAiOverviewEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<PersonalAiState>((s) => s.status == PersonalAiStatus.loading),
          predicate<PersonalAiState>((s) =>
              s.status == PersonalAiStatus.success &&
              s.dailyBrief != null &&
              s.dailyBrief!.eventsCount == 2 &&
              s.insights.length == 1 &&
              s.memories.length == 1),
        ]),
      );
    });

    test('AskAssistantEvent appends user prompt and assistant response with action proposal', () async {
      bloc.add(const AskAssistantEvent('What should I focus on?'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<PersonalAiState>((s) => s.isAsking == true && s.messages.length == 1 && s.messages.first.isUser),
          predicate<PersonalAiState>((s) =>
              s.isAsking == false &&
              s.messages.length == 2 &&
              s.messages.last.epistemicLevel == 'CALCULATED' &&
              s.messages.last.actionProposal != null),
        ]),
      );
    });

    test('ConfirmProposalEvent marks proposal as executed in messages list', () async {
      bloc.add(const AskAssistantEvent('Suggest a study plan'));
      await bloc.stream.firstWhere((s) => !s.isAsking && s.messages.length == 2);

      bloc.add(const ConfirmProposalEvent('prop_123'));

      await expectLater(
        bloc.stream,
        emits(predicate<PersonalAiState>((s) =>
            s.messages.last.actionProposal?.status == 'executed' &&
            s.actionFeedback == 'Action executed successfully.')),
      );
    });
  });
}
