import '../../models/workout/exercise.dart';
import '../../models/workout/exercise_database.dart';
import '../../models/workout/daily_recommendation.dart';
import '../../models/workout/calorie_summary_placeholder.dart';
import 'exercise_history_analyzer.dart';
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
  DailyRecommendation generateRecommendation({
    required UserProfile profile,
    required List<WorkoutEntry> recentWorkouts,
    CalorieSummary? calorieSummary,
    List<String>? availableEquipment,
    List<String>? injuredMuscleGroups,
    List<Exercise>? exerciseLibrary,
  }) {
    final library = exerciseLibrary ?? kSeedExercises;
    final historyAnalyzer = ExerciseHistoryAnalyzer(library);

    final targetMuscleGroup = _pickMuscleGroup(recentWorkouts, historyAnalyzer);
    final candidates = _filterExercises(
      library: library,
      muscleGroup: targetMuscleGroup,
      profile: profile,
      availableEquipment: availableEquipment,
      injuredMuscleGroups: injuredMuscleGroups,
    );

    final selected = candidates.take(6).toList();
    final prescriptions = selected
        .map((exercise) => _prescribe(exercise, profile, calorieSummary))
        .toList();

    final regionLabel = _regionLabelForMuscleGroup(targetMuscleGroup);

    return DailyRecommendation(
      id: '', // Firestore will assign this on write
      title: '$regionLabel ${_titleSuffixForGoal(profile.goal)}',
      targetMuscles: targetMuscleGroup,
      durationMinutes: _estimateDuration(prescriptions),
      difficulty: profile.fitnessExperience,
      exercises: prescriptions,
      reasonBullets: _buildReasonBullets(
        profile: profile,
        recentWorkouts: recentWorkouts,
        calorieSummary: calorieSummary,
      ),
      generatedAt: DateTime.now(),
    );
  }

  // ---- muscle group selection ----

  String _pickMuscleGroup(
    List<WorkoutEntry> recentWorkouts,
    ExerciseHistoryAnalyzer historyAnalyzer,
  ) {
    if (recentWorkouts.isEmpty) return _defaultRotation.first;

    // Avoid repeating whatever was trained in the most recent 1-2 sessions.
    // Muscle groups are derived by matching each logged exercise's name
    // against the exercise library - see ExerciseHistoryAnalyzer for why
    // workoutType itself (Gym/Cardio/Yoga/Calisthenics) isn't useful here.
    final recentMuscleGroups = <String>{};
    for (final entry in recentWorkouts.take(2)) {
      recentMuscleGroups.addAll(historyAnalyzer.muscleGroupsFor(entry));
    }

    if (recentMuscleGroups.isEmpty) return _defaultRotation.first;

    // BUG FIX: previously this always scanned from index 0, which meant
    // 'Full Body' (index 0) was returned every time unless Full Body itself
    // was just trained - the rotation never actually advanced. Fix: find
    // how far along the rotation we've gotten (the highest index among
    // recently-trained groups) and continue scanning FORWARD from there,
    // wrapping around, so the rotation actually progresses day to day.
    var startIndex = 0;
    for (final group in recentMuscleGroups) {
      final idx = _defaultRotation.indexOf(group);
      if (idx != -1 && idx >= startIndex) startIndex = idx + 1;
    }

    for (var offset = 0; offset < _defaultRotation.length; offset++) {
      final candidate =
          _defaultRotation[(startIndex + offset) % _defaultRotation.length];
      if (!recentMuscleGroups.contains(candidate)) return candidate;
    }

    return _defaultRotation.first; // fallback - everything recently trained
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
    required UserProfile profile,
    List<String>? availableEquipment,
    List<String>? injuredMuscleGroups,
  }) {
    final matches = library.where((exercise) {
      final muscleMatches = exercise.muscleGroup == muscleGroup ||
          muscleGroup == 'Full Body';
      final locationMatches = profile.workoutPreference == 'Both' ||
          exercise.workoutType == 'Both' ||
          exercise.workoutType == profile.workoutPreference;
      final equipmentOk = exercise.isUsableWithEquipment(availableEquipment);
      final safe = exercise.isSafeFor(injuredMuscleGroups);
      return muscleMatches && locationMatches && equipmentOk && safe;
    }).toList();

    // If filtering by exact muscle group leaves too few options (e.g. a
    // small seed library), fall back to any safe/usable exercise so the
    // user still gets a full workout rather than an empty plan.
    if (matches.length >= 4) return matches;

    return library.where((exercise) {
      final locationMatches = profile.workoutPreference == 'Both' ||
          exercise.workoutType == 'Both' ||
          exercise.workoutType == profile.workoutPreference;
      return locationMatches &&
          exercise.isUsableWithEquipment(availableEquipment) &&
          exercise.isSafeFor(injuredMuscleGroups);
    }).toList();
  }

  // ---- prescription (sets/reps/rest) ----

  ExercisePrescription _prescribe(
    Exercise exercise,
    UserProfile profile,
    CalorieSummary? calorieSummary,
  ) {
    // Base sets/reps by goal - standard strength-training heuristics.
    var sets = 3;
    var repsMin = 8;
    var repsMax = 12;
    var restSeconds = 60;

    switch (profile.goal) {
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
    if (profile.fitnessExperience == 'Beginner') {
      sets = (sets - 1).clamp(2, 5);
    } else if (profile.fitnessExperience == 'Advanced') {
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

  int _estimateDuration(List<ExercisePrescription> prescriptions) {
    const warmupMinutes = 5;
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
    CalorieSummary? calorieSummary,
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

    if (calorieSummary != null) {
      bullets.add(
        calorieSummary.isSignificantDeficit
            ? 'Calorie intake: running a deficit - volume trimmed slightly for recovery'
            : 'Calorie intake: on track',
      );
    }

    return bullets;
  }
}