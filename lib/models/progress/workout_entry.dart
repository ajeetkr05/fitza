import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutEntry {
  final String id;
  final String workoutName;
  final String workoutType;
  final int durationMinutes;
  final String notes;
  final List<Map<String, dynamic>> exercises;
  final DateTime recordedAt;
  final DateTime createdAt;

  const WorkoutEntry({
    required this.id,
    required this.workoutName,
    required this.workoutType,
    required this.durationMinutes,
    required this.notes,
    required this.exercises,
    required this.recordedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'workoutName': workoutName,
      'workoutType': workoutType,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'exercises': exercises,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WorkoutEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final rawExercises = data['exercises'];

    final exercises = rawExercises is List
        ? rawExercises
            .whereType<Map>()
            .map(
              (exercise) => Map<String, dynamic>.from(exercise),
            )
            .toList()
        : <Map<String, dynamic>>[];

    final savedWorkoutName = data['workoutName']?.toString().trim() ?? '';

    String fallbackWorkoutName() {
      if (exercises.isNotEmpty) {
        final firstExerciseName = exercises.first['name']?.toString().trim();

        if (firstExerciseName != null && firstExerciseName.isNotEmpty) {
          return firstExerciseName;
        }
      }

      final type = data['workoutType'] as String? ?? 'Workout';
      return '$type Workout';
    }

    final recordedAtValue = data['recordedAt'];
    final createdAtValue = data['createdAt'];

    return WorkoutEntry(
      id: document.id,
      workoutName:
          savedWorkoutName.isEmpty ? fallbackWorkoutName() : savedWorkoutName,
      workoutType: data['workoutType'] as String? ?? 'Workout',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      notes: data['notes'] as String? ?? '',
      exercises: exercises,
      recordedAt: recordedAtValue is Timestamp
          ? recordedAtValue.toDate()
          : DateTime.now(),
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
    );
  }
}