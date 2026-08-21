import 'warmup_exercise.dart';

/// Warm-up movements per target muscle group. Keyed directly by the same
/// muscle group values used in DailyRecommendation.targetMuscles (Chest,
/// Back, Legs, Shoulders, Core, Arms, Full Body) - no separate region
/// lookup needed since that field is already exposed.
///
/// GUESSED CONTENT: these are standard, widely-used dynamic warm-up
/// movements for each muscle group - not personalized by injury, age, or
/// fitness level. If a muscle group is flagged injured (see
/// InjurySettingsScreen), consider whether its warm-up should be skipped
/// or modified too - not handled yet, since warm-ups are low-intensity by
/// design and assumed generally safe, but worth revisiting if that
/// assumption turns out wrong for a specific injury type.
class WarmupLibrary {
  static const Map<String, List<WarmupExercise>> _byMuscleGroup = {
    'Chest': [
      WarmupExercise(name: 'Arm Circles', instruction: 'Small to large circles, both directions.', durationSeconds: 30),
      WarmupExercise(name: 'Band Pull-Aparts', instruction: 'Pull an imaginary band apart at chest height.', durationSeconds: 30),
      WarmupExercise(name: 'Push-Up to Downward Dog', instruction: 'Flow between a push-up and downward dog stretch.', durationSeconds: 30),
    ],
    'Back': [
      WarmupExercise(name: 'Cat-Cow Stretch', instruction: 'Arch and round your spine slowly on all fours.', durationSeconds: 30),
      WarmupExercise(name: 'Band Pull-Aparts', instruction: 'Pull an imaginary band apart at chest height.', durationSeconds: 30),
      WarmupExercise(name: 'Superman Hold', instruction: 'Lie face down, lift arms and legs, hold briefly.', durationSeconds: 20),
    ],
    'Shoulders': [
      WarmupExercise(name: 'Arm Circles', instruction: 'Small to large circles, both directions.', durationSeconds: 30),
      WarmupExercise(name: 'Shoulder Rolls', instruction: 'Roll shoulders forward then backward.', durationSeconds: 20),
      WarmupExercise(name: 'Wall Slides', instruction: 'Slide arms up and down a wall, keeping contact.', durationSeconds: 30),
    ],
    'Arms': [
      WarmupExercise(name: 'Arm Circles', instruction: 'Small to large circles, both directions.', durationSeconds: 30),
      WarmupExercise(name: 'Wrist Circles', instruction: 'Rotate wrists slowly in both directions.', durationSeconds: 20),
      WarmupExercise(name: 'Light Band Curls', instruction: 'A few easy curls with light or no resistance.', durationSeconds: 30),
    ],
    'Legs': [
      WarmupExercise(name: 'Leg Swings', instruction: 'Swing each leg forward-back, then side-to-side.', durationSeconds: 30),
      WarmupExercise(name: 'Bodyweight Squats', instruction: 'Slow, controlled squats with no added weight.', durationSeconds: 30),
      WarmupExercise(name: 'Hip Circles', instruction: 'Rotate hips in wide circles, both directions.', durationSeconds: 20),
    ],
    'Core': [
      WarmupExercise(name: 'Cat-Cow Stretch', instruction: 'Arch and round your spine slowly on all fours.', durationSeconds: 30),
      WarmupExercise(name: 'Torso Twists', instruction: 'Gently rotate your torso side to side.', durationSeconds: 30),
      WarmupExercise(name: 'Bird Dog', instruction: 'Extend opposite arm and leg, alternate sides.', durationSeconds: 30),
    ],
    'Full Body': [
      WarmupExercise(name: 'Jumping Jacks', instruction: 'Steady pace to raise your heart rate.', durationSeconds: 30),
      WarmupExercise(name: 'High Knees', instruction: 'Jog in place, driving knees up.', durationSeconds: 30),
      WarmupExercise(name: 'Arm Circles + Leg Swings', instruction: 'Combine both to loosen upper and lower body.', durationSeconds: 30),
    ],
  };

  static List<WarmupExercise> forMuscleGroup(String muscleGroup) {
    return _byMuscleGroup[muscleGroup] ?? _byMuscleGroup['Full Body']!;
  }

  static int totalDurationSeconds(List<WarmupExercise> warmup) {
    return warmup.fold<int>(0, (sum, w) => sum + w.durationSeconds);
  }
}
