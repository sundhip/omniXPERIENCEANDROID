import 'dart:math';
import '../../core/database/app_database.dart';

class PriorityCalculationResult {
  final double score;
  final String level; // Urgent, High, Medium, Low
  final String rationale;

  const PriorityCalculationResult({
    required this.score,
    required this.level,
    required this.rationale,
  });
}

class LearningCalculationEngine {
  /// Deterministically calculates priority score (0 to 100) and human-readable explanation
  static PriorityCalculationResult calculatePriority({
    required String priorityLabel,
    DateTime? targetDate,
    double progress = 0.0,
    int estimatedDurationMinutes = 60,
  }) {
    final now = DateTime.now();

    // 1. Importance (max 40)
    final importanceMap = {
      'Urgent': 40.0,
      'High': 30.0,
      'Medium': 20.0,
      'Low': 10.0,
    };
    final importancePts = importanceMap[priorityLabel] ?? 20.0;

    // 2. Urgency (max 40)
    double urgencyPts;
    String urgencyDesc;
    if (targetDate != null) {
      final daysLeft = targetDate.difference(now).inSeconds / 86400.0;
      if (daysLeft < 0) {
        urgencyPts = 40.0;
        urgencyDesc = 'Overdue';
      } else if (daysLeft <= 2) {
        urgencyPts = 35.0;
        urgencyDesc = 'Due in ${max(0, daysLeft.toInt())}d';
      } else if (daysLeft <= 7) {
        urgencyPts = 25.0;
        urgencyDesc = 'Due in ${daysLeft.toInt()}d';
      } else if (daysLeft <= 14) {
        urgencyPts = 15.0;
        urgencyDesc = 'Due in ${daysLeft.toInt()}d';
      } else if (daysLeft <= 30) {
        urgencyPts = 8.0;
        urgencyDesc = 'Due in ${daysLeft.toInt()}d';
      } else {
        urgencyPts = 5.0;
        urgencyDesc = 'Due in ${daysLeft.toInt()}d';
      }
    } else {
      urgencyPts = 5.0;
      urgencyDesc = 'No deadline';
    }

    // 3. Incompletion (max 20)
    final incompletionPct = max(0.0, 100.0 - progress);
    final incompletionPts = (incompletionPct * 0.20 * 10).round() / 10;

    final totalScore = min(100.0, ((importancePts + urgencyPts + incompletionPts) * 10).round() / 10);

    String level;
    if (totalScore >= 75.0) {
      level = 'Urgent';
    } else if (totalScore >= 55.0) {
      level = 'High';
    } else if (totalScore >= 35.0) {
      level = 'Medium';
    } else {
      level = 'Low';
    }

    final rationale = '$urgencyDesc (${urgencyPts.toInt()} pts) + '
        '$priorityLabel importance (${importancePts.toInt()} pts) + '
        '${incompletionPct.toInt()}% incomplete ($incompletionPts pts) = '
        'Score $totalScore/100';

    return PriorityCalculationResult(
      score: totalScore,
      level: level,
      rationale: rationale,
    );
  }

  /// Calculates truthful percentage of completed milestones
  static double calculateMilestonesProgress(List<GoalMilestoneModel> milestones) {
    if (milestones.isEmpty) return 0.0;
    final completedCount = milestones.where((m) => m.completed).length;
    return ((completedCount / milestones.length) * 1000).round() / 10;
  }

  /// Formats duration in minutes to readable hours and minutes
  static String formatDurationMinutes(int minutes) {
    if (minutes < 60) return '$minutes mins';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }

  static bool isOverdue(DateTime? targetDate) {
    if (targetDate == null) return false;
    return DateTime.now().isAfter(targetDate);
  }

  static int daysRemaining(DateTime? targetDate) {
    if (targetDate == null) return 999;
    return targetDate.difference(DateTime.now()).inDays;
  }
}
