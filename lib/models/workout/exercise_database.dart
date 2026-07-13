import 'exercise.dart';

/// TEMPORARY seed data. The wireflow shows a global "Exercise Library"
/// (search, filter, custom exercises), which implies exercises will
/// eventually live in their own Firestore collection with the same shape
/// as `Exercise.fromFirestore` expects. Until that collection exists,
/// RecommendationService can pull from this local list so the feature
/// is testable end-to-end today.
///
/// To migrate later: replace `kSeedExercises` reads in
/// RecommendationService with a Firestore query against an `exercises`
/// collection - no changes needed to the Exercise model itself.
const List<Exercise> kSeedExercises = [
  Exercise(
    id: 'bench_press',
    name: 'Barbell Bench Press',
    muscleGroup: 'Chest',
    difficultyLevel: 'Intermediate',
    workoutType: 'Gym',
    instructions: 'Lie on a flat bench, lower the bar to chest, press up.',
    equipmentTags: ['barbell', 'bench'],
    contraindicatedFor: ['shoulder'],
  ),
  Exercise(
    id: 'pushup',
    name: 'Push-Up',
    muscleGroup: 'Chest',
    difficultyLevel: 'Beginner',
    workoutType: 'Both',
    instructions: 'Hands under shoulders, lower chest to floor, push up.',
  ),
  Exercise(
    id: 'db_row',
    name: 'Dumbbell Row',
    muscleGroup: 'Back',
    difficultyLevel: 'Beginner',
    workoutType: 'Both',
    instructions: 'Hinge at hips, row dumbbell to hip, squeeze shoulder blade.',
    equipmentTags: ['dumbbells'],
  ),
  Exercise(
    id: 'pull_up',
    name: 'Pull-Up',
    muscleGroup: 'Back',
    difficultyLevel: 'Advanced',
    workoutType: 'Both',
    instructions: 'Hang from bar, pull chin over bar, lower with control.',
    equipmentTags: ['pull_up_bar'],
  ),
  Exercise(
    id: 'squat',
    name: 'Bodyweight Squat',
    muscleGroup: 'Legs',
    difficultyLevel: 'Beginner',
    workoutType: 'Both',
    instructions: 'Feet shoulder-width, lower hips back and down, stand up.',
    contraindicatedFor: ['knee'],
  ),
  Exercise(
    id: 'barbell_squat',
    name: 'Barbell Back Squat',
    muscleGroup: 'Legs',
    difficultyLevel: 'Advanced',
    workoutType: 'Gym',
    instructions: 'Bar on upper back, squat to depth, drive through heels.',
    equipmentTags: ['barbell', 'squat_rack'],
    contraindicatedFor: ['knee', 'lower_back'],
  ),
  Exercise(
    id: 'shoulder_press',
    name: 'Dumbbell Shoulder Press',
    muscleGroup: 'Shoulders',
    difficultyLevel: 'Intermediate',
    workoutType: 'Both',
    instructions: 'Press dumbbells overhead from shoulder height, lower slowly.',
    equipmentTags: ['dumbbells'],
    contraindicatedFor: ['shoulder'],
  ),
  Exercise(
    id: 'plank',
    name: 'Plank',
    muscleGroup: 'Core',
    difficultyLevel: 'Beginner',
    workoutType: 'Both',
    instructions: 'Forearms and toes on floor, hold body in a straight line.',
  ),
  Exercise(
    id: 'bicep_curl',
    name: 'Dumbbell Bicep Curl',
    muscleGroup: 'Arms',
    difficultyLevel: 'Beginner',
    workoutType: 'Both',
    instructions: 'Curl dumbbells toward shoulders, lower with control.',
    equipmentTags: ['dumbbells'],
  ),
  Exercise(
    id: 'burpee',
    name: 'Burpee',
    muscleGroup: 'Full Body',
    difficultyLevel: 'Intermediate',
    workoutType: 'Both',
    instructions: 'Squat, kick back to plank, push-up, jump feet in, jump up.',
    contraindicatedFor: ['knee', 'shoulder'],
  ),
];
