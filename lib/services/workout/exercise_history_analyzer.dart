import '../../models/workout/exercise.dart';
import 'package:fitza/models/progress/workout_entry.dart';

/// Determines which muscle groups a user actually trained in a given
/// WorkoutEntry.
///
/// CORRECTED APPROACH: `WorkoutEntry.workoutType` is only a broad category -
/// 'Gym', 'Cardio', 'Yoga', or 'Calisthenics' (confirmed from
/// ExerciseDetailScreen's `_isGym` / `workoutType == 'Cardio'` checks). It
/// does NOT indicate a body region, so it can't be used to figure out
/// whether someone trained chest vs legs.
///
/// Instead, each logged exercise inside `workout.exercises` has a free-text
/// `name` field (e.g. "Bench Press", "Squat"). This analyzer matches that
/// name (case-insensitive, trimmed) against the exercise library's `name`
/// field to find the associated muscleGroup.
///
/// KNOWN LIMITATION: if a user typed a custom exercise name that isn't in
/// the library (kSeedExercises today, a Firestore `exercises` collection
/// later), it won't match and that exercise is silently skipped. This is
/// fail-safe (treated as "unknown", not "matches everything"), but it does
/// mean history-based rotation gets weaker as users log more unusual/custom
/// exercises. A more robust fix later would be to store `muscleGroup`
/// directly on each logged exercise at write-time (in the Log Workout
/// screens), rather than re-deriving it after the fact - worth raising with
/// whoever owns the Gym Workout logging screen.
class ExerciseHistoryAnalyzer {
  final List<Exercise> library;

  ExerciseHistoryAnalyzer(this.library);

  late final Map<String, String> _nameToMuscleGroup = {
    for (final exercise in library)
      exercise.name.trim().toLowerCase(): exercise.muscleGroup,
  };

  /// Returns the set of muscle groups trained in this workout entry.
  /// Returns an empty set if no logged exercise names matched the library
  /// AND the workout type isn't a recognised non-strength category.
  Set<String> muscleGroupsFor(WorkoutEntry entry) {
    final matched = <String>{};

    for (final exercise in entry.exercises) {
      final rawName = exercise['name']?.toString().trim().toLowerCase();
      if (rawName == null || rawName.isEmpty) continue;

      final muscleGroup = _nameToMuscleGroup[rawName];
      if (muscleGroup != null) matched.add(muscleGroup);
    }

    if (matched.isNotEmpty) return matched;

    // No name matches - fall back to a coarse guess based on category,
    // since Cardio/Yoga sessions are typically full-body/low-specificity
    // rather than targeting one muscle group.
    switch (entry.workoutType) {
      case 'Cardio':
      case 'Yoga':
      case 'Calisthenics':
        return {'Full Body'};
      default:
        return {}; // truly unknown - e.g. unrecognised Gym exercise names
    }
  }
}
