import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/workout/daily_recommendation.dart';
import '../../services/progress/workout_firestore_service.dart';

/// "Workout Summary" (screen 6). Pushed (replacing ActiveWorkoutScreen)
/// when the user finishes their last exercise.
///
/// SAVE BUTTON IS STUBBED: saving this as a WorkoutEntry needs the real
/// method signature from workout_firestore_service.dart (used by
/// GymWorkoutScreen etc.) so the entry lands in the same place Progress
/// Tracker reads from. Wire this up once that's confirmed - see the
/// TODO in _saveWorkout below.
class WorkoutSummaryScreen extends StatelessWidget {
  final DailyRecommendation recommendation;
  final Duration actualDuration;

  const WorkoutSummaryScreen({
    super.key,
    required this.recommendation,
    required this.actualDuration,
  });

  String get _formattedDuration {
    final minutes = actualDuration.inMinutes;
    final seconds = actualDuration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveWorkout(BuildContext context) async {
    try {
      await WorkoutFirestoreService.instance.saveWorkout(
        // 'Gym' is the correct bucket regardless of home/gym location -
        // saveWorkout only recognises Gym/Cardio/other, and every exercise
        // here is a sets/reps strength exercise.
        workoutType: 'Gym',
        workoutName: recommendation.title,
        duration: '${actualDuration.inMinutes} min',
        notes: 'Completed via personalized recommendation: ${recommendation.title}',
        exercises: recommendation.exercises.map((prescription) {
          return {
            'name': prescription.exercise.name,
            'sets': '${prescription.sets}',
            // Logging the top of the prescribed rep range as a placeholder -
            // Active Workout doesn't yet capture actual reps/weight performed.
            'reps': '${prescription.repsMax}',
          };
        }).toList(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout saved!')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save workout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    final darkText = colors.primaryText;
    final greyText = colors.secondaryText;
    final successGreen = colors.successGreen;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: successGreen, size: 64),
              const SizedBox(height: 16),
              Text(
                'Great Job!',
                style: TextStyle(color: darkText, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Text(
                'Workout Completed',
                style: TextStyle(color: greyText, fontSize: 16),
              ),
              const SizedBox(height: 28),
              _statsCard(context),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _saveWorkout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: Text('Skip', style: TextStyle(color: greyText, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsCard(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          _statRow(context, Icons.timer_outlined, 'Duration', _formattedDuration),
          Divider(height: 24, color: colors.border),
          _statRow(context, Icons.fitness_center_rounded, 'Exercises Completed', '${recommendation.exercises.length}'),
          Divider(height: 24, color: colors.border),
          _statRow(context, Icons.bar_chart_rounded, 'Target Muscles', recommendation.targetMuscles),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    return Row(
      children: [
        Icon(icon, color: colors.primaryBlue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: colors.secondaryText, fontSize: 15)),
        ),
        Text(value, style: TextStyle(color: colors.primaryText, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
