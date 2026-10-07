import 'package:equatable/equatable.dart';
import '../../core/database/app_database.dart';

class ClientScheduleConflict extends Equatable {
  final String eventAId;
  final String eventATitle;
  final String eventBId;
  final String eventBTitle;
  final DateTime overlapStart;
  final DateTime overlapEnd;
  final String message;

  const ClientScheduleConflict({
    required this.eventAId,
    required this.eventATitle,
    required this.eventBId,
    required this.eventBTitle,
    required this.overlapStart,
    required this.overlapEnd,
    required this.message,
  });

  @override
  List<Object?> get props => [eventAId, eventBId, overlapStart, overlapEnd];
}

class ClientTimeBlock extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final bool isFree;

  const ClientTimeBlock({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.isFree = true,
  });

  @override
  List<Object?> get props => [startTime, endTime, durationMinutes, isFree];
}

class ClientTaskSlotSuggestion extends Equatable {
  final String taskId;
  final String taskTitle;
  final DateTime suggestedStart;
  final DateTime suggestedEnd;
  final int durationMinutes;
  final String reason;

  const ClientTaskSlotSuggestion({
    required this.taskId,
    required this.taskTitle,
    required this.suggestedStart,
    required this.suggestedEnd,
    required this.durationMinutes,
    required this.reason,
  });

  @override
  List<Object?> get props => [taskId, suggestedStart, suggestedEnd];
}

class ClientPriorityAssessment extends Equatable {
  final String taskId;
  final String title;
  final String explicitPriority;
  final String calculatedPriority;
  final double urgencyScore; // 0.0 to 1.0
  final bool isBlocked;
  final List<String> blockingTaskIds;
  final String explanation;

  const ClientPriorityAssessment({
    required this.taskId,
    required this.title,
    required this.explicitPriority,
    required this.calculatedPriority,
    required this.urgencyScore,
    required this.isBlocked,
    required this.blockingTaskIds,
    required this.explanation,
  });

  @override
  List<Object?> get props => [taskId, calculatedPriority, urgencyScore, isBlocked];
}

class ProductivityPriorityEngine {
  /// Detects pairwise overlapping events in a collection.
  static List<ClientScheduleConflict> detectConflicts(List<EventModel> events) {
    final conflicts = <ClientScheduleConflict>[];
    final active = events.where((e) => e.status != 'cancelled' && !e.allDay).toList();
    final n = active.length;

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final e1 = active[i];
        final e2 = active[j];

        final overlapStart = e1.startTime.isAfter(e2.startTime) ? e1.startTime : e2.startTime;
        final overlapEnd = e1.endTime.isBefore(e2.endTime) ? e1.endTime : e2.endTime;

        if (overlapStart.isBefore(overlapEnd)) {
          final fmtStart = "${overlapStart.hour.toString().padLeft(2, '0')}:${overlapStart.minute.toString().padLeft(2, '0')}";
          final fmtEnd = "${overlapEnd.hour.toString().padLeft(2, '0')}:${overlapEnd.minute.toString().padLeft(2, '0')}";
          conflicts.add(ClientScheduleConflict(
            eventAId: e1.id,
            eventATitle: e1.title,
            eventBId: e2.id,
            eventBTitle: e2.title,
            overlapStart: overlapStart,
            overlapEnd: overlapEnd,
            message: "Schedule conflict: '${e1.title}' and '${e2.title}' overlap ($fmtStart - $fmtEnd).",
          ));
        }
      }
    }
    return conflicts;
  }

  /// Calculates deterministic urgency score, blocked dependencies, and suggested priority.
  static ClientPriorityAssessment calculate(
    TaskModel task,
    List<TaskModel> allTasks, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final taskMap = {for (var t in allTasks) t.id: t};

    // Check dependencies
    final blockingIds = <String>[];
    bool isBlocked = false;
    for (final depId in task.dependencyTaskIds) {
      final depTask = taskMap[depId];
      if (depTask != null && depTask.status != 'Completed') {
        isBlocked = true;
        blockingIds.add(depId);
      }
    }

    const pWeights = {'Urgent': 1.0, 'High': 0.8, 'Medium': 0.5, 'Low': 0.2};
    final userWeight = pWeights[task.priority] ?? 0.5;

    double dueWeight = 0.2;
    String dueStatusText = "No deadline";

    if (task.dueDate != null) {
      final diff = task.dueDate!.difference(current);
      if (diff.isNegative) {
        dueWeight = 1.0;
        final hoursAgo = diff.inHours.abs();
        dueStatusText = hoursAgo > 0 ? "Overdue by ${hoursAgo}h" : "Overdue";
      } else if (diff.inHours <= 12) {
        dueWeight = 0.95;
        dueStatusText = "Due in ${diff.inHours}h";
      } else if (diff.inHours <= 24) {
        dueWeight = 0.85;
        dueStatusText = "Due today";
      } else if (diff.inHours <= 48) {
        dueWeight = 0.70;
        dueStatusText = "Due tomorrow";
      } else if (diff.inDays <= 7) {
        dueWeight = 0.45;
        dueStatusText = "Due in ${diff.inDays} days";
      } else {
        dueWeight = 0.25;
        dueStatusText = "Due in ${diff.inDays} days";
      }
    }

    double urgencyScore;
    String suggestedPriority;
    String explanation;

    if (isBlocked) {
      urgencyScore = (userWeight * 0.4).clamp(0.0, 0.35);
      suggestedPriority = 'Low';
      final blockingTitles = blockingIds.map((id) => taskMap[id]?.title ?? 'prerequisite').join(', ');
      explanation = "Blocked by incomplete prerequisite: $blockingTitles.";
    } else if (dueWeight >= 0.95) {
      urgencyScore = userWeight.clamp(0.9, 1.0);
      suggestedPriority = 'Urgent';
      explanation = "$dueStatusText. Immediate action required.";
    } else if (dueWeight >= 0.70) {
      urgencyScore = ((userWeight * 0.4) + (dueWeight * 0.6)).clamp(0.0, 1.0);
      suggestedPriority = urgencyScore > 0.65 ? 'High' : 'Medium';
      explanation = "$dueStatusText with ${task.priority} priority → Elevated urgency.";
    } else {
      urgencyScore = ((userWeight * 0.6) + (dueWeight * 0.4)).clamp(0.0, 1.0);
      suggestedPriority = task.priority;
      explanation = "$dueStatusText with ${task.priority} priority.";
    }

    return ClientPriorityAssessment(
      taskId: task.id,
      title: task.title,
      explicitPriority: task.priority,
      calculatedPriority: suggestedPriority,
      urgencyScore: double.parse(urgencyScore.toStringAsFixed(2)),
      isBlocked: isBlocked,
      blockingTaskIds: blockingIds,
      explanation: explanation,
    );
  }

  /// Identifies open windows between events.
  static List<ClientTimeBlock> identifyFreeBlocks(
    List<EventModel> events,
    DateTime dayStart,
    DateTime dayEnd, {
    int minDurationMinutes = 15,
  }) {
    final active = events
        .where((e) => e.status != 'cancelled' && !e.allDay && e.endTime.isAfter(dayStart) && e.startTime.isBefore(dayEnd))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final freeBlocks = <ClientTimeBlock>[];
    DateTime cursor = dayStart;

    for (final e in active) {
      final eStart = e.startTime.isAfter(cursor) ? e.startTime : cursor;
      if (eStart.isAfter(cursor)) {
        final gapMinutes = eStart.difference(cursor).inMinutes;
        if (gapMinutes >= minDurationMinutes) {
          freeBlocks.add(ClientTimeBlock(
            startTime: cursor,
            endTime: eStart,
            durationMinutes: gapMinutes,
            isFree: true,
          ));
        }
      }
      if (e.endTime.isAfter(cursor)) {
        cursor = e.endTime;
      }
    }

    if (cursor.isBefore(dayEnd)) {
      final gapMinutes = dayEnd.difference(cursor).inMinutes;
      if (gapMinutes >= minDurationMinutes) {
        freeBlocks.add(ClientTimeBlock(
          startTime: cursor,
          endTime: dayEnd,
          durationMinutes: gapMinutes,
          isFree: true,
        ));
      }
    }

    return freeBlocks;
  }

  /// Suggests free time blocks for uncompleted tasks without mutating events.
  static List<ClientTaskSlotSuggestion> suggestTaskSlots(
    List<ClientTimeBlock> freeBlocks,
    List<TaskModel> tasks,
  ) {
    final suggestions = <ClientTaskSlotSuggestion>[];
    const pOrder = {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3};
    final candidates = tasks.where((t) => t.status != 'Completed' && t.status != 'Cancelled').toList()
      ..sort((a, b) => (pOrder[a.priority] ?? 2).compareTo(pOrder[b.priority] ?? 2));

    final availableBlocks = freeBlocks
        .map((b) => {'start': b.startTime, 'end': b.endTime, 'duration': b.durationMinutes})
        .toList();

    for (final t in candidates) {
      final est = t.estimatedDurationMinutes > 0 ? t.estimatedDurationMinutes : 30;
      for (final blk in availableBlocks) {
        final dur = blk['duration'] as int;
        if (dur >= est) {
          final sStart = blk['start'] as DateTime;
          final sEnd = sStart.add(Duration(minutes: est));
          suggestions.add(ClientTaskSlotSuggestion(
            taskId: t.id,
            taskTitle: t.title,
            suggestedStart: sStart,
            suggestedEnd: sEnd,
            durationMinutes: est,
            reason: "Fits '${t.title}' (${est}m) into ${dur}m free block.",
          ));
          blk['start'] = sEnd;
          blk['duration'] = dur - est;
          break;
        }
      }
      if (suggestions.length >= 4) break;
    }
    return suggestions;
  }
}
