import 'exercise.dart';

/// What the user actually performed for one exercise during Active Workout -
/// as opposed to ExercisePrescription, which is what the engine RECOMMENDED.
/// Previously WorkoutSummaryScreen saved the prescription's target values
/// (e.g. repsMax) as if they were performance data, which meant workout
/// history/recovery tracking was working from fictional numbers. This
/// closes that gap.
class ExercisePerformance {
  final Exercise exercise;
  int setsCompleted;
  int repsCompleted;
  /// Null for bodyweight exercises (no equipment needed) or if the user
  /// didn't enter a weight. Matches WorkoutFirestoreService's existing
  /// pattern of only writing 'weightKg' when a valid value is present.
  double? weightKg;

  ExercisePerformance({
    required this.exercise,
    required this.setsCompleted,
    required this.repsCompleted,
    this.weightKg,
  });

  factory ExercisePerformance.fromPrescriptionDefaults(dynamic prescription) {
    return ExercisePerformance(
      exercise: prescription.exercise as Exercise,
      setsCompleted: prescription.sets as int,
      // Default to the middle of the prescribed rep range as a reasonable
      // starting guess - user can adjust up/down before finishing.
      repsCompleted: (((prescription.repsMin as int) + (prescription.repsMax as int)) / 2).round(),
      weightKg: null,
    );
  }
}
