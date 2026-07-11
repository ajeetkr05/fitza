import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/progress/workout_entry.dart';

class WorkoutFirestoreService {
  WorkoutFirestoreService._();

  static final WorkoutFirestoreService instance =
      WorkoutFirestoreService._();

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No signed-in user found.');
    }

    return user.uid;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    return _firestore.collection('users').doc(_currentUserId);
  }

  CollectionReference<Map<String, dynamic>> get _workoutsCollection {
    return _userDocument.collection('workouts');
  }

  Future<void> saveWorkout({
    required String workoutType,
    required String duration,
    required String notes,
    required List<Map<String, String>> exercises,
    DateTime? recordedAt,
    String? workoutName,
  }) async {
    final workoutDocument = _workoutsCollection.doc();
    final now = DateTime.now();
    final workoutDate = recordedAt ?? now;

    final workoutEntry = WorkoutEntry(
      id: workoutDocument.id,
      workoutName: (workoutName ?? '').trim().isEmpty
          ? '$workoutType Workout'
          : workoutName!.trim(),
      workoutType: workoutType,
      durationMinutes: _durationMinutes(duration),
      notes: notes.trim(),
      exercises: exercises
          .map(
            (exercise) => _normaliseExercise(
              workoutType: workoutType,
              exercise: exercise,
            ),
          )
          .toList(),
      recordedAt: workoutDate,
      createdAt: now,
    );

    final batch = _firestore.batch();

    batch.set(
      _userDocument,
      {
        'lastWorkoutUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(workoutDocument, workoutEntry.toMap());

    await batch.commit();
  }

  Stream<List<WorkoutEntry>> getWorkoutEntriesStream() {
    return _workoutsCollection
        .orderBy('recordedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WorkoutEntry.fromFirestore)
              .toList(),
        );
  }

  int _durationMinutes(String duration) {
    final match = RegExp(r'\d+').firstMatch(duration);

    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  Map<String, dynamic> _normaliseExercise({
    required String workoutType,
    required Map<String, String> exercise,
  }) {
    final exerciseName = (exercise['name'] ?? 'Workout').trim();

    final normalisedExercise = <String, dynamic>{
      'name': exerciseName.isEmpty ? 'Workout' : exerciseName,
    };

    if (workoutType == 'Gym') {
      _addIntIfPresent(normalisedExercise, 'sets', exercise['sets']);
      _addIntIfPresent(normalisedExercise, 'reps', exercise['reps']);
      _addDoubleIfPresent(
        normalisedExercise,
        'weightKg',
        exercise['weight'],
      );
    } else if (workoutType == 'Cardio') {
      _addIntIfPresent(
        normalisedExercise,
        'durationMinutes',
        exercise['reps'],
      );
      _addDoubleIfPresent(
        normalisedExercise,
        'distanceKm',
        exercise['distance'],
      );
      _addIntIfPresent(normalisedExercise, 'steps', exercise['steps']);
      _addIntIfPresent(
        normalisedExercise,
        'caloriesBurned',
        exercise['calories'],
      );
    } else {
      _addIntIfPresent(
        normalisedExercise,
        'durationMinutes',
        exercise['reps'],
      );
      _addIntIfPresent(normalisedExercise, 'sets', exercise['sets']);

      final difficulty = (exercise['difficulty'] ?? '').trim();

      if (difficulty.isNotEmpty) {
        normalisedExercise['difficulty'] = difficulty;
      }
    }

    return normalisedExercise;
  }

  void _addIntIfPresent(
    Map<String, dynamic> target,
    String fieldName,
    String? value,
  ) {
    final parsedValue = int.tryParse((value ?? '').trim());

    if (parsedValue != null) {
      target[fieldName] = parsedValue;
    }
  }

  void _addDoubleIfPresent(
    Map<String, dynamic> target,
    String fieldName,
    String? value,
  ) {
    final parsedValue = double.tryParse((value ?? '').trim());

    if (parsedValue != null) {
      target[fieldName] = parsedValue;
    }
  }
}