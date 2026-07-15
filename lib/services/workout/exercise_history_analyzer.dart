import '../../models/workout/exercise.dart';
import 'exercise_muscle_group_map.dart';
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
/// Instead, each logged exercise inside `workout.exercises` has a `name`
/// field. That name is matched (case-insensitive, trimmed) primarily
/// against `kExerciseMuscleGroupMap` - a comprehensive mapping covering
/// the full ~250-item autocomplete list used in Gym Workout logging - with
/// the curated recommendation-engine library layered on top as a fallback/
/// override. Since the Gym Workout screen's exercise field is an
/// autocomplete tied to that same list, most real logged names should now
/// match correctly.
///
/// REMAINING LIMITATION: a user can still type something outside the
/// autocomplete suggestions (it's a free-text field with suggestions, not
/// a strict picker), so exotic/custom names will still fall through to
/// "unknown" - this is fail-safe (treated as no signal), not incorrect.
class ExerciseHistoryAnalyzer {
  final List<Exercise> library;

  ExerciseHistoryAnalyzer(this.library);

  late final Map<String, String> _nameToMuscleGroup = {
    // Comprehensive map covering the real ~250-item autocomplete list used
    // in Gym Workout logging - this is the primary source, since that's
    // what users actually pick from when logging a workout.
    ...kExerciseMuscleGroupMap,
    // Library entries layered on top (can override) - covers any curated
    // recommendation-engine exercises whose names might differ slightly
    // from the autocomplete list.
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
