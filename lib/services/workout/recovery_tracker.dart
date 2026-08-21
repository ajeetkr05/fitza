import '../../models/workout/exercise.dart';
import 'exercise_history_analyzer.dart';
import 'package:fitza/models/progress/workout_entry.dart';

/// Tracks how recently each muscle group was trained, so the recommendation
/// engine can prefer genuinely recovered muscle groups over a fixed rotation
/// order. Reuses ExerciseHistoryAnalyzer's name-matching (see that file for
/// why WorkoutEntry.workoutType alone isn't enough to know what was trained).
class RecoveryTracker {
  final ExerciseHistoryAnalyzer _analyzer;

  RecoveryTracker(List<Exercise> library) : _analyzer = ExerciseHistoryAnalyzer(library);

  static const List<String> muscleGroups = [
    'Chest', 'Back', 'Legs', 'Shoulders', 'Core', 'Arms', 'Full Body',
  ];

  /// Days since each muscle group was last trained. A group never trained
  /// (or not found in history at all) gets a large sentinel value (999) so
  /// it's always treated as "fully recovered" / highest priority.
  Map<String, int> daysSinceLastTrained(List<WorkoutEntry> workoutHistory) {
    final now = DateTime.now();
    final lastTrainedDate = <String, DateTime>{};

    // History should be scanned oldest-to-newest isn't required here since
    // we just want the MOST RECENT date per group - compare and keep max.
    for (final entry in workoutHistory) {
      final groups = _analyzer.muscleGroupsFor(entry);
      for (final group in groups) {
        final existing = lastTrainedDate[group];
        if (existing == null || entry.recordedAt.isAfter(existing)) {
          lastTrainedDate[group] = entry.recordedAt;
        }
      }
    }

    final result = <String, int>{};
    for (final group in muscleGroups) {
      final lastDate = lastTrainedDate[group];
      if (lastDate == null) {
        result[group] = 999; // never trained - treat as fully recovered
      } else {
        final days = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
        result[group] = days;
      }
    }
    return result;
  }

  /// Human-readable status for the "why this workout" explanation.
  /// THRESHOLD NOTE: 2 days is a simple, commonly-used heuristic for
  /// strength-training muscle recovery, not a personalized/medical figure.
  /// Worth revisiting if you want this to factor in workout intensity,
  /// sleep, or age later.
  static String statusLabel(int daysSince) {
    if (daysSince >= 2) return 'Fully recovered';
    if (daysSince == 1) return 'Recovering (trained yesterday)';
    return 'Recovering (trained today)';
  }
}
