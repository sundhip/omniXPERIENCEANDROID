import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnipresence/features/personal_ai/models/personal_ai_models.dart';
import 'package:omnipresence/features/personal_ai/views/daily_readiness_card.dart';

void main() {
  group('Phase 9 Production Hardening Tests', () {
    testWidgets('DailyReadinessCard renders with live brief data', (WidgetTester tester) async {
      const sampleBrief = DailyPersonalBriefModel(
        date: '2026-10-08',
        greeting: 'Good Morning,',
        userName: 'Aarav',
        eventsCount: 3,
        priorityTasksCount: 2,
        approachingDeadlinesCount: 1,
        pendingHabitsCount: 1,
        focus: 'Submit Machine Learning Project Report',
        plan: 'Dedicated 3-hour focus block before afternoon meeting',
        prepare: 'Light jacket and comfortable trainers; rain expected',
        wellness: 'Drink 2L water and finish evening skincare routine',
        proactiveAlerts: ['ML deadline approaching in 14 hours'],
      );

      var didTapAi = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyReadinessCard(
                brief: sampleBrief,
                onOpenAi: () {
                  didTapAi = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Daily Readiness'), findsOneWidget);
      expect(find.text('What do I need to know & do today?'), findsOneWidget);
      expect(find.text('Submit Machine Learning Project Report'), findsOneWidget);
      expect(find.text('Dedicated 3-hour focus block before afternoon meeting'), findsOneWidget);
      expect(find.text('Light jacket and comfortable trainers; rain expected'), findsOneWidget);
      expect(find.text('Drink 2L water and finish evening skincare routine'), findsOneWidget);

      final discussButton = find.text('Discuss Day with AI');
      expect(discussButton, findsOneWidget);
      await tester.tap(discussButton);
      expect(didTapAi, isTrue);
    });

    testWidgets('DailyReadinessCard renders clean fallback when agenda is clear', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyReadinessCard(
              brief: null,
              onOpenAi: () {},
            ),
          ),
        ),
      );

      expect(find.text('Daily Readiness'), findsOneWidget);
      expect(find.text('All systems aligned'), findsOneWidget);
      expect(find.textContaining('Your live daily agenda is currently clear'), findsOneWidget);
    });

    test('ProactiveInsightModel deserializes severity and recommended actions', () {
      final json = {
        'id': 'ins_test_1',
        'insight_type': 'deadline_approaching',
        'severity': 'urgent',
        'title': 'Deadline in 12h: Cloud Architecture Exam',
        'explanation': 'Study session pending',
        'recommended_action': 'Start 45m review block now.',
        'dismissed': false,
      };

      final model = ProactiveInsightModel.fromJson(json);
      expect(model.id, equals('ins_test_1'));
      expect(model.severity, equals('urgent'));
      expect(model.title, equals('Deadline in 12h: Cloud Architecture Exam'));
      expect(model.recommendedAction, equals('Start 45m review block now.'));
      expect(model.dismissed, isFalse);
    });
  });
}
