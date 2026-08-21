import '../../models/workout/exercise.dart';
import '../../models/workout/exercise_database.dart';
import '../../models/workout/daily_recommendation.dart';
import '../../models/workout/calorie_summary.dart';
import '../../models/workout/plan_customization.dart';
import '../../models/workout/warmup_exercise.dart';
import '../../models/workout/warmup_library.dart';
import 'recovery_tracker.dart';
import 'package:fitza/models/profile/user_profile.dart';
import 'package:fitza/models/progress/workout_entry.dart';

/// Generates a personalised daily workout recommendation.
///
/// This is v1: rule-based, no ML. It uses only fields that exist today on
/// UserProfile (goal, activityLevel, fitnessExperience, workoutPreference),
/// plus optional inputs (equipment, injuries, calories) that don't exist
/// yet but are already wired into the signature so adding them later is a
/// one-line change at the call site, not a rewrite of this class.
class RecommendationService {
  /// Muscle group rotation used when the user has no recent workout
  /// history (e.g. brand new user). Order matters: this is the default
  /// "Day 1" split.
  static const List<String> _defaultRotation = [
    'Full Body',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Core',
    'Arms',
  ];

  /// Generates today's recommendation.
  ///
  /// [recentWorkouts] should be the user's last 1-7 WorkoutEntry records,
  /// most recent first - used to avoid recommending the same muscle group
  /// two days in a row and to gauge consistency.
  ///
  /// [availableEquipment] and [injuredMuscleGroups] are optional and unused
  /// until those features exist - passing null is safe and expected today.
  ///
  /// [customization] carries session-level overrides from the Customize
  /// Plan screen (difficulty, workout location, muscle focus, exercise
  /// count). These override the profile's normal values for THIS call only
  /// - nothing is persisted back to UserProfile.
  DailyRecommendation generateRecommendation({
    required UserProfile profile,
    required List<WorkoutEntry> recentWorkouts,
    CalorieSummary? calorieSummary,
    List<String>? availableEquipment,
    List<String>? injuredMuscleGroups,
    List<Exercise>? exerciseLibrary,
    PlanCustomization? customization,
  }) {
    final library = exerciseLibrary ?? kSeedExercises;
    final recoveryTracker = RecoveryTracker(library);
    final daysSinceTrained = recoveryTracker.daysSinceLastTrained(recentWorkouts);

    final effectiveDifficulty = customization?.difficulty ?? profile.fitnessExperience;
    final effectiveWorkoutPreference =
        customization?.workoutPreference ?? profile.workoutPreference;
    final effectiveExerciseCount = customization?.exerciseCount ?? 6;

    final targetMuscleGroup = customization?.targetMuscleGroup ??
        _pickMuscleGroup(daysSinceTrained, injuredMuscleGroups);

    final candidates = _filterExercises(
      library: library,
      muscleGroup: targetMuscleGroup,
      workoutPreference: effectiveWorkoutPreference,
      availableEquipment: availableEquipment,
      injuredMuscleGroups: injuredMuscleGroups,
    );

    final selected = candidates.take(effectiveExerciseCount).toList();
    final prescriptions = selected
        .map((exercise) => _prescribe(
              exercise,
              goal: profile.goal,
              experienceLevel: effectiveDifficulty,
              calorieSummary: calorieSummary,
            ))
        .toList();

    final regionLabel = _regionLabelForMuscleGroup(targetMuscleGroup);
    final warmupExercises = WarmupLibrary.forMuscleGroup(targetMuscleGroup);

    return DailyRecommendation(
      id: '', // Firestore will assign this on write
      title: '$regionLabel ${_titleSuffixForGoal(profile.goal)}',
      targetMuscles: targetMuscleGroup,
      durationMinutes: _estimateDuration(prescriptions, warmupExercises),
      difficulty: effectiveDifficulty,
      exercises: prescriptions,
      warmupExercises: warmupExercises,
      reasonBullets: _buildReasonBullets(
        profile: profile,
        recentWorkouts: recentWorkouts,
        calorieSummary: calorieSummary,
        wasCustomized: customization != null,
        targetMuscleGroup: targetMuscleGroup,
        daysSinceTrained: daysSinceTrained,
        injuredMuscleGroups: injuredMuscleGroups,
      ),
      generatedAt: DateTime.now(),
    );
  }

  // ---- muscle group selection ----

  /// Picks today's muscle group based on actual recovery time (days since
  /// last trained), not a fixed rotation list. Excludes any muscle group
  /// the user has flagged as injured/limited entirely - not just at the
  /// exercise-filtering level, so an injured group is never even
  /// considered as today's focus.
  ///
  /// Ties (e.g. multiple never-trained groups) are broken using
  /// _defaultRotation's order, so a brand-new user still gets a sensible
  /// "Day 1" default (Full Body first) rather than an arbitrary pick.
  String _pickMuscleGroup(
    Map<String, int> daysSinceTrained,
    List<String>? injuredMuscleGroups,
  ) {
    final injured = injuredMuscleGroups?.toSet() ?? const <String>{};
    final eligible = _defaultRotation.where((g) => !injured.contains(g)).toList();

    if (eligible.isEmpty) {
      // Edge case: every muscle group is flagged injured. Nothing safe to
      // recommend - fall back to the gentlest option (Core) rather than
      // crashing or silently ignoring the injury flags. This is a rare
      // scenario worth surfacing to the user in the UI (e.g. "consult a
      // professional") rather than something the engine can solve alone.
      return 'Core';
    }

    eligible.sort((a, b) {
      final daysA = daysSinceTrained[a] ?? 999;
      final daysB = daysSinceTrained[b] ?? 999;
      if (daysA != daysB) return daysB.compareTo(daysA); // most recovered first
      return _defaultRotation.indexOf(a).compareTo(_defaultRotation.indexOf(b));
    });

    return eligible.first;
  }

  /// Human-readable region label for today's title, e.g. so we generate
  /// "Upper Body Strength" rather than just "Chest".
  String _regionLabelForMuscleGroup(String muscleGroup) {
    const mapping = {
      'Chest': 'Upper Body',
      'Back': 'Upper Body',
      'Shoulders': 'Upper Body',
      'Arms': 'Upper Body',
      'Legs': 'Lower Body',
      'Core': 'Core',
      'Full Body': 'Full Body',
    };
    return mapping[muscleGroup] ?? muscleGroup;
  }

  // ---- filtering ----

  List<Exercise> _filterExercises({
    required List<Exercise> library,
    required String muscleGroup,
    required String workoutPreference,
    List<String>? availableEquipment,
    List<String>? injuredMuscleGroups,
  }) {
    final matches = library.where((exercise) {
      final muscleMatches = exercise.muscleGroup == muscleGroup ||
          muscleGroup == 'Full Body';
      final locationMatches = workoutPreference == 'Both' ||
          exercise.workoutType == 'Both' ||
          exercise.workoutType == workoutPreference;
      final equipmentOk = exercise.isUsableWithEquipment(availableEquipment);
      final safe = exercise.isSafeFor(injuredMuscleGroups);
      return muscleMatches && locationMatches && equipmentOk && safe;
    }).toList();

    // If filtering by exact muscle group leaves too few options (e.g. a
    // small seed library), fall back to any safe/usable exercise so the
    // user still gets a full workout rather than an empty plan.
    if (matches.length >= 4) return matches;

    return library.where((exercise) {
      final locationMatches = workoutPreference == 'Both' ||
          exercise.workoutType == 'Both' ||
          exercise.workoutType == workoutPreference;
      return locationMatches &&
          exercise.isUsableWithEquipment(availableEquipment) &&
          exercise.isSafeFor(injuredMuscleGroups);
    }).toList();
  }

  // ---- prescription (sets/reps/rest) ----

  ExercisePrescription _prescribe(
    Exercise exercise, {
    required String goal,
    required String experienceLevel,
    CalorieSummary? calorieSummary,
  }) {
    // Base sets/reps by goal - standard strength-training heuristics.
    var sets = 3;
    var repsMin = 8;
    var repsMax = 12;
    var restSeconds = 60;

    switch (goal) {
      case 'Build Strength':
        sets = 4;
        repsMin = 4;
        repsMax = 6;
        restSeconds = 120;
        break;
      case 'Gain Muscle':
        sets = 4;
        repsMin = 8;
        repsMax = 12;
        restSeconds = 75;
        break;
      case 'Lose Weight':
        sets = 3;
        repsMin = 12;
        repsMax = 15;
        restSeconds = 45;
        break;
      case 'Improve Endurance':
        sets = 3;
        repsMin = 15;
        repsMax = 20;
        restSeconds = 30;
        break;
      case 'Stay Fit':
      default:
        sets = 3;
        repsMin = 10;
        repsMax = 12;
        restSeconds = 60;
    }

    // Beginners: reduce volume slightly to build consistency without burnout.
    if (experienceLevel == 'Beginner') {
      sets = (sets - 1).clamp(2, 5);
    } else if (experienceLevel == 'Advanced') {
      sets = sets + 1;
    }

    // If in a significant calorie deficit, trim volume a bit to protect
    // recovery - this is the only place calorie data currently influences
    // the plan; expand here once the real calorie tracker is integrated.
    if (calorieSummary?.isSignificantDeficit ?? false) {
      sets = (sets - 1).clamp(2, 5);
    }

    return ExercisePrescription(
      exercise: exercise,
      sets: sets,
      repsMin: repsMin,
      repsMax: repsMax,
      restSeconds: restSeconds,
    );
  }

  // ---- helpers ----

  String _titleSuffixForGoal(String goal) {
    switch (goal) {
      case 'Build Strength':
        return 'Strength';
      case 'Gain Muscle':
        return 'Hypertrophy';
      case 'Lose Weight':
        return 'Fat Burn';
      case 'Improve Endurance':
        return 'Endurance';
      default:
        return 'Session';
    }
  }

  int _estimateDuration(List<ExercisePrescription> prescriptions, List<WarmupExercise> warmupExercises) {
    final warmupMinutes = (WarmupLibrary.totalDurationSeconds(warmupExercises) / 60).ceil();
    final workMinutes = prescriptions.fold<int>(0, (total, p) {
      final avgReps = ((p.repsMin + p.repsMax) / 2).round();
      final secondsPerSet = (avgReps * 3) + p.restSeconds; // ~3s per rep
      return total + ((secondsPerSet * p.sets) / 60).round();
    });
    return warmupMinutes + workMinutes;
  }

  List<String> _buildReasonBullets({
    required UserProfile profile,
    required List<WorkoutEntry> recentWorkouts,
    required String targetMuscleGroup,
    required Map<String, int> daysSinceTrained,
    CalorieSummary? calorieSummary,
    List<String>? injuredMuscleGroups,
    bool wasCustomized = false,
  }) {
    final bullets = <String>[
      'Your fitness goal: ${profile.goal}',
      'Experience level: ${profile.fitnessExperience}',
    ];

    if (recentWorkouts.isNotEmpty) {
      bullets.add('Previous workout: ${recentWorkouts.first.workoutType}');
      bullets.add('Workout consistency: ${recentWorkouts.length} sessions logged recently');
    } else {
      bullets.add('This is your first recommended workout - starting with a full body session');
    }

    final daysSince = daysSinceTrained[targetMuscleGroup] ?? 999;
    bullets.add('Recovery status: ${RecoveryTracker.statusLabel(daysSince)}');

    if (calorieSummary != null) {
      bullets.add(
        calorieSummary.isSignificantDeficit
            ? 'Calorie intake: running a deficit - volume trimmed slightly for recovery'
            : 'Calorie intake: on track',
      );
    }

    if (injuredMuscleGroups != null && injuredMuscleGroups.isNotEmpty) {
      bullets.add('Avoiding: ${injuredMuscleGroups.join(', ')} (flagged as injured/limited)');
    }

    if (wasCustomized) {
      bullets.add('This plan reflects your custom preferences for today');
    }

    return bullets;
  }
}
