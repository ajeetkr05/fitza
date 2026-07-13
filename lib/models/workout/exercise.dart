import 'package:cloud_firestore/cloud_firestore.dart';

/// A single exercise in the exercise library.
///
/// EXTENSIBILITY NOTES:
/// - `equipmentTags` defaults to an empty list, meaning "bodyweight / no
///   equipment required". Once an Equipment Manager feature exists, exercises
///   that need gear should list tags matching whatever equipment IDs/names
///   that feature defines (e.g. 'dumbbells', 'barbell', 'pull_up_bar').
///   Nothing here needs to change to support that - the filtering logic in
///   RecommendationService already treats equipmentTags as optional.
/// - `contraindicatedFor` defaults to an empty list, meaning "safe for
///   everyone". Once injury tracking exists, add muscle-group/joint tags
///   here (e.g. 'shoulder', 'lower_back') and the engine will automatically
///   start excluding these exercises for affected users.
class Exercise {
  final String id;
  final String name;
  final String muscleGroup; // e.g. 'Chest', 'Back', 'Legs', 'Core', 'Full Body'
  final String difficultyLevel; // matches fitnessExperience options
  final String workoutType; // 'Gym', 'Home', or 'Both' - matches workoutPreference
  final String instructions;
  final List<String> equipmentTags; // empty = bodyweight, no equipment needed
  final List<String> contraindicatedFor; // empty = safe for all; muscle/joint tags
  final String? videoUrl;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.difficultyLevel,
    required this.workoutType,
    required this.instructions,
    this.equipmentTags = const [],
    this.contraindicatedFor = const [],
    this.videoUrl,
  });

  factory Exercise.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    return Exercise(
      id: document.id,
      name: data['name'] as String? ?? 'Unnamed Exercise',
      muscleGroup: data['muscleGroup'] as String? ?? 'Full Body',
      difficultyLevel: data['difficultyLevel'] as String? ?? 'Beginner',
      workoutType: data['workoutType'] as String? ?? 'Both',
      instructions: data['instructions'] as String? ?? '',
      equipmentTags: (data['equipmentTags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      contraindicatedFor: (data['contraindicatedFor'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      videoUrl: data['videoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'muscleGroup': muscleGroup,
      'difficultyLevel': difficultyLevel,
      'workoutType': workoutType,
      'instructions': instructions,
      'equipmentTags': equipmentTags,
      'contraindicatedFor': contraindicatedFor,
      'videoUrl': videoUrl,
    };
  }

  /// True if the user's available equipment covers this exercise's needs.
  /// If `availableEquipment` is null, equipment isn't being tracked yet -
  /// so every exercise is assumed usable (fail-open, not fail-closed).
  bool isUsableWithEquipment(List<String>? availableEquipment) {
    if (equipmentTags.isEmpty) return true; // bodyweight, always usable
    if (availableEquipment == null) return true; // not tracked yet
    return equipmentTags.every((tag) => availableEquipment.contains(tag));
  }

  /// True if none of this exercise's contraindications match the user's
  /// injured/limited muscle groups. If `injuredMuscleGroups` is null or
  /// empty, injuries aren't being tracked yet - so nothing is excluded.
  bool isSafeFor(List<String>? injuredMuscleGroups) {
    if (injuredMuscleGroups == null || injuredMuscleGroups.isEmpty) {
      return true;
    }
    return !contraindicatedFor.any((tag) => injuredMuscleGroups.contains(tag));
  }
}
