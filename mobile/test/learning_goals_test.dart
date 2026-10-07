import 'package:flutter_test/flutter_test.dart';
import 'package:omnipresence/core/database/app_database.dart';
import 'package:omnipresence/features/learning/learning_calculation_engine.dart';

void main() {
  group('Phase 7 — LearningCalculationEngine & Priority Calculations', () {
    test('Calculates truthful milestone completion progress', () {
      const milestones = [
        GoalMilestoneModel(id: '1', title: 'Step 1', completed: true, order: 1),
        GoalMilestoneModel(id: '2', title: 'Step 2', completed: false, order: 2),
        GoalMilestoneModel(id: '3', title: 'Step 3', completed: false, order: 3),
      ];
      final progress = LearningCalculationEngine.calculateMilestonesProgress(milestones);
      expect(progress, equals(33.3));

      final allCompleted = milestones.map((m) => m.copyWith(completed: true)).toList();
      final fullProgress = LearningCalculationEngine.calculateMilestonesProgress(allCompleted);
      expect(fullProgress, equals(100.0));
    });

    test('Computes deterministic priority score and rationale', () {
      final overdue = DateTime.now().subtract(const Duration(days: 1));
      final resultUrgent = LearningCalculationEngine.calculatePriority(
        priorityLabel: 'Urgent',
        targetDate: overdue,
        progress: 10.0,
      );
      expect(resultUrgent.level, equals('Urgent'));
      expect(resultUrgent.score, greaterThanOrEqualTo(80.0));
      expect(resultUrgent.rationale, contains('Overdue'));
      expect(resultUrgent.rationale, contains('Urgent importance'));

      final resultLow = LearningCalculationEngine.calculatePriority(
        priorityLabel: 'Low',
        targetDate: null,
        progress: 90.0,
      );
      expect(resultLow.level, equals('Low'));
      expect(resultLow.score, lessThan(35.0));
      expect(resultLow.rationale, contains('No deadline'));
    });

    test('Formats duration correctly', () {
      expect(LearningCalculationEngine.formatDurationMinutes(45), equals('45 mins'));
      expect(LearningCalculationEngine.formatDurationMinutes(60), equals('1h'));
      expect(LearningCalculationEngine.formatDurationMinutes(90), equals('1h 30m'));
    });
  });

  group('Phase 7 — Models JSON Serialization & Deserialization', () {
    test('LearningItemModel round-trip preserves hierarchy and status', () {
      final item = LearningItemModel(
        id: 'learn_123',
        userId: 'user_456',
        title: 'Binary Trees',
        type: 'topic',
        category: 'Academic',
        status: 'In Progress',
        priority: 'High',
        progress: 45.0,
        parentId: 'parent_algo',
        targetDate: DateTime.parse('2026-10-15T00:00:00.000Z'),
        estimatedDurationMinutes: 90,
      );

      final json = item.toJson();
      final recovered = LearningItemModel.fromJson(json);

      expect(recovered.id, equals('learn_123'));
      expect(recovered.title, equals('Binary Trees'));
      expect(recovered.type, equals('topic'));
      expect(recovered.progress, equals(45.0));
      expect(recovered.parentId, equals('parent_algo'));
      expect(recovered.estimatedDurationMinutes, equals(90));
    });

    test('GoalModel round-trip preserves milestones and financial target', () {
      const goal = GoalModel(
        id: 'goal_789',
        userId: 'user_456',
        title: 'Buy Work Laptop',
        category: 'Financial',
        priority: 'Medium',
        status: 'Active',
        progress: 50.0,
        financialTargetAmount: 85000.0,
        financialSavedAmount: 42500.0,
        milestones: [
          GoalMilestoneModel(id: 'm1', title: 'Save ₹30,000', completed: true, order: 1),
          GoalMilestoneModel(id: 'm2', title: 'Save remaining ₹55,000', completed: false, order: 2),
        ],
      );

      final json = goal.toJson();
      final recovered = GoalModel.fromJson(json);

      expect(recovered.id, equals('goal_789'));
      expect(recovered.category, equals('Financial'));
      expect(recovered.financialTargetAmount, equals(85000.0));
      expect(recovered.milestones.length, equals(2));
      expect(recovered.milestones.first.title, equals('Save ₹30,000'));
      expect(recovered.milestones.first.completed, isTrue);
    });

    test('GoalPlanRecommendationModel round-trip correctly parses AI suggestions', () {
      final rawJson = {
        'goal_id': 'goal_789',
        'goal_title': 'Master System Design',
        'feasible': true,
        'total_estimated_hours': 35.0,
        'weekly_hours_required': 7.0,
        'deadline_status': 'On Track',
        'suggested_milestones': [
          {
            'title': 'Scalability Basics',
            'target_date': '2026-10-20',
            'estimated_hours': 8.0,
            'order': 1,
          },
          {
            'title': 'Database Sharding & Caching',
            'target_date': '2026-10-30',
            'estimated_hours': 12.0,
            'order': 2,
          }
        ],
        'recommended_next_action': 'Schedule two 90-min sessions on Scalability Basics.',
        'detected_conflicts': [],
        'rationale': 'Feasible plan requiring ~7 hrs/week over 5 weeks.',
      };

      final plan = GoalPlanRecommendationModel.fromJson(rawJson);
      expect(plan.goalId, equals('goal_789'));
      expect(plan.feasible, isTrue);
      expect(plan.suggestedMilestones.length, equals(2));
      expect(plan.suggestedMilestones[0].title, equals('Scalability Basics'));
      expect(plan.weeklyHoursRequired, equals(7.0));
    });

    test('StudySessionModel round trip', () {
      const session = StudySessionModel(
        id: 'sess_1',
        userId: 'u_1',
        title: 'Algorithms Practice',
        sessionType: 'Coding',
        plannedDurationMinutes: 60,
        actualDurationMinutes: 50,
        status: 'Completed',
        notes: 'Solved 2 medium problems',
      );

      final json = session.toJson();
      final recovered = StudySessionModel.fromJson(json);
      expect(recovered.title, equals('Algorithms Practice'));
      expect(recovered.actualDurationMinutes, equals(50));
      expect(recovered.sessionType, equals('Coding'));
    });
  });
}
