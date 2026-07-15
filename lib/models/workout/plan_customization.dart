/// Session-level overrides applied on top of a UserProfile when generating
/// a recommendation - e.g. from the Customize Plan screen. These are NOT
/// persisted to the user's profile; they only affect today's plan.
///
/// All fields are optional. Null means "use the profile's normal value".
class PlanCustomization {
  final String? difficulty; // overrides profile.fitnessExperience
  final String? workoutPreference; // overrides profile.workoutPreference
  final String? targetMuscleGroup; // overrides the auto-picked rotation
  final int? exerciseCount; // overrides the default 6-exercise session

  const PlanCustomization({
    this.difficulty,
    this.workoutPreference,
    this.targetMuscleGroup,
    this.exerciseCount,
  });

  PlanCustomization copyWith({
    String? difficulty,
    String? workoutPreference,
    String? targetMuscleGroup,
    int? exerciseCount,
  }) {
    return PlanCustomization(
      difficulty: difficulty ?? this.difficulty,
      workoutPreference: workoutPreference ?? this.workoutPreference,
      targetMuscleGroup: targetMuscleGroup ?? this.targetMuscleGroup,
      exerciseCount: exerciseCount ?? this.exerciseCount,
    );
  }
}
