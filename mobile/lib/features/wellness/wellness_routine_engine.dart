import '../../core/database/app_database.dart';

class WellnessRoutineEngine {
  /// Truthful streak calculation: consecutive days logged as Completed.
  /// If a day is missed or skipped, current streak resets.
  static Map<String, dynamic> calculateStreak({
    required HabitModel habit,
    required List<Map<String, dynamic>> logs,
    DateTime? referenceDate,
  }) {
    final ref = referenceDate ?? DateTime.now();
    final refDay = DateTime(ref.year, ref.month, ref.day);

    final completedDates = <DateTime>{};
    for (final log in logs) {
      if (log['habit_id'] == habit.id &&
          (log['status']?.toString().toLowerCase() == 'completed')) {
        final dStr = log['log_date']?.toString();
        if (dStr != null) {
          final parts = dStr.split('-');
          if (parts.length == 3) {
            completedDates.add(DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            ));
          }
        }
      }
    }

    final completedToday = completedDates.contains(refDay);

    int currentStreak = 0;
    var checkDate = completedToday ? refDay : refDay.subtract(const Duration(days: 1));

    while (completedDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Longest streak
    final sortedDates = completedDates.toList()..sort();
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? prev;

    for (final d in sortedDates) {
      if (prev == null || d.difference(prev).inDays == 1) {
        tempStreak++;
      } else if (d.difference(prev).inDays > 1) {
        tempStreak = 1;
      }
      prev = d;
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }
    }
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    final startD = habit.startDate ?? refDay.subtract(const Duration(days: 30));
    final totalDays = (refDay.difference(startD).inDays + 1).clamp(1, 10000);
    final rate = ((completedDates.length / totalDays) * 100.0).clamp(0.0, 100.0);
    final roundedRate = (rate * 10).round() / 10;

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'completionRate': roundedRate,
      'completedToday': completedToday,
    };
  }
}
