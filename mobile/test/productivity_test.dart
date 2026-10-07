import 'package:flutter_test/flutter_test.dart';
import 'package:omnipresence/core/database/app_database.dart';
import 'package:omnipresence/core/network/api_client.dart';
import 'package:omnipresence/features/productivity/productivity_priority_engine.dart';
import 'package:omnipresence/features/productivity/productivity_notification_service.dart';
import 'package:omnipresence/features/productivity/productivity_repository.dart';
import 'package:omnipresence/features/productivity/productivity_bloc.dart';

class MockProductivityRepository extends ProductivityRepository {
  final List<EventModel> mockEvents = [];
  final List<TaskModel> mockTasks = [];

  MockProductivityRepository() : super(apiClient: ApiClient());

  @override
  Future<List<EventModel>> getEvents({DateTime? startDate, DateTime? endDate, String? category}) async {
    return List.from(mockEvents);
  }

  @override
  Future<EventModel> createEvent(EventModel event) async {
    mockEvents.add(event);
    return event;
  }

  @override
  Future<List<TaskModel>> getTasks({String? status, String? category, String? priority}) async {
    return List.from(mockTasks);
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    mockTasks.add(task);
    return task;
  }

  @override
  Future<TaskModel> toggleTaskCompletion(String taskId) async {
    final idx = mockTasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final current = mockTasks[idx];
      final newStatus = current.status == 'Completed' ? 'Todo' : 'Completed';
      final updated = current.copyWith(
        status: newStatus,
        completedAt: newStatus == 'Completed' ? DateTime.now() : null,
      );
      mockTasks[idx] = updated;
      return updated;
    }
    throw Exception('Task not found');
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    mockEvents.removeWhere((e) => e.id == eventId);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    mockTasks.removeWhere((t) => t.id == taskId);
  }
}

void main() {
  group('Phase 5 Productivity Intelligence Unit Tests', () {
    test('EventModel serialization round-trip', () {
      final now = DateTime(2026, 10, 7, 10, 0);
      final event = EventModel(
        id: 'evt_test_1',
        userId: 'usr_123',
        title: 'DBMS Lecture',
        description: 'Relational algebra',
        startTime: now,
        endTime: now.add(const Duration(hours: 2)),
        category: 'College',
        priority: 'High',
        occasion: 'Lecture',
        reminderSettings: const [15, 60],
        createdAt: now,
        updatedAt: now,
      );

      final json = event.toJson();
      final restored = EventModel.fromJson(json);

      expect(restored.id, 'evt_test_1');
      expect(restored.title, 'DBMS Lecture');
      expect(restored.category, 'College');
      expect(restored.priority, 'High');
      expect(restored.reminderSettings, [15, 60]);
    });

    test('TaskModel serialization round-trip', () {
      final now = DateTime(2026, 10, 7, 14, 0);
      final task = TaskModel(
        id: 'tsk_test_1',
        userId: 'usr_123',
        title: 'Submit Lab Report',
        priority: 'Urgent',
        dueDate: now.add(const Duration(days: 1)),
        estimatedDurationMinutes: 45,
        category: 'College',
        dependencyTaskIds: const ['tsk_dep_1'],
        reminderSettings: const [30],
        createdAt: now,
        updatedAt: now,
      );

      final json = task.toJson();
      final restored = TaskModel.fromJson(json);

      expect(restored.id, 'tsk_test_1');
      expect(restored.title, 'Submit Lab Report');
      expect(restored.priority, 'Urgent');
      expect(restored.estimatedDurationMinutes, 45);
      expect(restored.dependencyTaskIds, ['tsk_dep_1']);
    });

    test('ProductivityPriorityEngine detects schedule conflicts', () {
      final day = DateTime(2026, 10, 7);
      final ev1 = EventModel(
        id: 'ev1',
        userId: 'u',
        title: 'Team Standup',
        startTime: DateTime(day.year, day.month, day.day, 10, 0),
        endTime: DateTime(day.year, day.month, day.day, 11, 30),
        createdAt: day,
        updatedAt: day,
      );

      final ev2 = EventModel(
        id: 'ev2',
        userId: 'u',
        title: 'Doctor Appointment',
        startTime: DateTime(day.year, day.month, day.day, 11, 0),
        endTime: DateTime(day.year, day.month, day.day, 12, 0),
        createdAt: day,
        updatedAt: day,
      );

      final conflicts = ProductivityPriorityEngine.detectConflicts([ev1, ev2]);
      expect(conflicts.length, 1);
      expect(conflicts.first.eventAId, 'ev1');
      expect(conflicts.first.eventBId, 'ev2');
      expect(conflicts.first.message.contains('Schedule conflict'), isTrue);
    });

    test('ProductivityPriorityEngine flags blocked tasks when dependency is uncompleted', () {
      final now = DateTime(2026, 10, 7, 12, 0);
      final taskA = TaskModel(
        id: 't_research',
        userId: 'u',
        title: 'Gather Sources',
        status: 'Todo',
        createdAt: now,
        updatedAt: now,
      );

      final taskB = TaskModel(
        id: 't_write',
        userId: 'u',
        title: 'Write Paper',
        status: 'Todo',
        dependencyTaskIds: const ['t_research'],
        createdAt: now,
        updatedAt: now,
      );

      final assessment = ProductivityPriorityEngine.calculate(taskB, [taskA, taskB], now: now);
      expect(assessment.isBlocked, isTrue);
      expect(assessment.blockingTaskIds, contains('t_research'));
      expect(assessment.calculatedPriority, 'Low');
      expect(assessment.explanation.contains('Blocked by incomplete prerequisite'), isTrue);
    });

    test('ProductivityPriorityEngine identifies free blocks and suggests task slots', () {
      final day = DateTime(2026, 10, 7);
      final ev1 = EventModel(
        id: 'e1',
        userId: 'u',
        title: 'Morning Class',
        startTime: DateTime(day.year, day.month, day.day, 9, 0),
        endTime: DateTime(day.year, day.month, day.day, 10, 0),
        createdAt: day,
        updatedAt: day,
      );
      final ev2 = EventModel(
        id: 'e2',
        userId: 'u',
        title: 'Afternoon Lab',
        startTime: DateTime(day.year, day.month, day.day, 14, 0),
        endTime: DateTime(day.year, day.month, day.day, 16, 0),
        createdAt: day,
        updatedAt: day,
      );

      final workStart = DateTime(day.year, day.month, day.day, 8, 0);
      final workEnd = DateTime(day.year, day.month, day.day, 18, 0);

      final freeBlocks = ProductivityPriorityEngine.identifyFreeBlocks([ev1, ev2], workStart, workEnd);
      expect(freeBlocks.length, 3); // 08-09, 10-14, 16-18

      final midBlock = freeBlocks.firstWhere((b) => b.durationMinutes == 240);
      expect(midBlock.startTime.hour, 10);
      expect(midBlock.endTime.hour, 14);

      final task = TaskModel(
        id: 't_study',
        userId: 'u',
        title: 'Study Algorithms',
        estimatedDurationMinutes: 60,
        priority: 'High',
        createdAt: day,
        updatedAt: day,
      );

      final suggestions = ProductivityPriorityEngine.suggestTaskSlots(freeBlocks, [task]);
      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.first.taskId, 't_study');
      expect(suggestions.first.durationMinutes, 60);
    });

    test('ProductivityBloc handles load, create, toggle completion, and delete', () async {
      final mockRepo = MockProductivityRepository();
      final notif = ProductivityNotificationService();
      final bloc = ProductivityBloc(repository: mockRepo, notificationService: notif);

      bloc.add(const LoadProductivityData());
      final state1 = await bloc.stream.firstWhere((s) => s is ProductivityLoaded) as ProductivityLoaded;
      expect(state1.allEvents.isEmpty, isTrue);

      // Create event
      final now = DateTime.now();
      final newEv = EventModel(
        id: 'ev_bloc_1',
        userId: 'u',
        title: 'Project Sync',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );
      bloc.add(CreateEventAction(newEv));
      final state2 = await bloc.stream.firstWhere((s) => s is ProductivityLoaded && s.allEvents.length == 1) as ProductivityLoaded;
      expect(state2.allEvents.first.title, 'Project Sync');

      // Create task
      final newTsk = TaskModel(
        id: 'tsk_bloc_1',
        userId: 'u',
        title: 'Review Code PR',
        priority: 'Urgent',
        createdAt: now,
        updatedAt: now,
      );
      bloc.add(CreateTaskAction(newTsk));
      final state3 = await bloc.stream.firstWhere((s) => s is ProductivityLoaded && s.allTasks.length == 1) as ProductivityLoaded;
      expect(state3.allTasks.first.title, 'Review Code PR');

      // Toggle completion
      bloc.add(const ToggleTaskCompletionAction('tsk_bloc_1'));
      final state4 = await bloc.stream.firstWhere((s) => s is ProductivityLoaded && s.allTasks.first.status == 'Completed') as ProductivityLoaded;
      expect(state4.allTasks.first.status, 'Completed');
    });
  });
}
