import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

/// A single exercise with sets/reps/rest assigned for a specific user.
class ExercisePrescription {
  final Exercise exercise;
  final int sets;
  final int repsMin;
  final int repsMax;
  final int restSeconds;

  const ExercisePrescription({
    required this.exercise,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.restSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exercise.id,
      'exerciseName': exercise.name,
      'sets': sets,
      'repsMin': repsMin,
      'repsMax': repsMax,
      'restSeconds': restSeconds,
    };
  }
}

/// "Today's Recommendation" - matches screen 2 in the wireflow.
/// This is the document that would be saved to Firestore (e.g. under
/// `users/{uid}/recommendations/{date}`), following the same
/// `fromFirestore` / `toMap` pattern as WorkoutEntry and WeightEntry.
class DailyRecommendation {
  final String id;
  final String title; // e.g. "Upper Body Strength"
  final String targetMuscles; // e.g. "Chest, Shoulders, Triceps"
  final int durationMinutes;
  final String difficulty; // matches fitnessExperience-style values
  final List<ExercisePrescription> exercises;
  final List<String> reasonBullets; // "Why this workout?" - shown on screen 2
  final DateTime generatedAt;

  const DailyRecommendation({
    required this.id,
    required this.title,
    required this.targetMuscles,
    required this.durationMinutes,
    required this.difficulty,
    required this.exercises,
    required this.reasonBullets,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetMuscles': targetMuscles,
      'durationMinutes': durationMinutes,
      'difficulty': difficulty,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'reasonBullets': reasonBullets,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }

  factory DailyRecommendation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
    Map<String, Exercise> exerciseLookup,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final rawExercises = data['exercises'] as List? ?? [];
    final exercises = rawExercises
        .whereType<Map>()
        .map((e) {
          final exerciseId = e['exerciseId'] as String?;
          final exercise = exerciseLookup[exerciseId];
          if (exercise == null) return null;
          return ExercisePrescription(
            exercise: exercise,
            sets: (e['sets'] as num?)?.toInt() ?? 3,
            repsMin: (e['repsMin'] as num?)?.toInt() ?? 8,
            repsMax: (e['repsMax'] as num?)?.toInt() ?? 12,
            restSeconds: (e['restSeconds'] as num?)?.toInt() ?? 60,
          );
        })
        .whereType<ExercisePrescription>()
        .toList();

    final generatedAtValue = data['generatedAt'];
    return DailyRecommendation(
      id: document.id,
      title: data['title'] as String? ?? 'Workout',
      targetMuscles: data['targetMuscles'] as String? ?? '',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 45,
      difficulty: data['difficulty'] as String? ?? 'Beginner',
      exercises: exercises,
      reasonBullets: (data['reasonBullets'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      generatedAt: generatedAtValue is Timestamp
          ? generatedAtValue.toDate()
          : DateTime.now(),
    );
  }
}
