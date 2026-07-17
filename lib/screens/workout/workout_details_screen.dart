import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/workout/daily_recommendation.dart';
import 'active_workout_screen.dart';

/// "Workout Details" (screen 4 in the wireframe). Pushed from
/// WorkoutHomeScreen's "Start Workout" button. Not part of bottom nav, so
/// no selectedIndex/onTabChanged props - just a normal pushed route with a
/// back arrow, matching ExerciseDetailScreen's pattern.
class WorkoutDetailsScreen extends StatelessWidget {
  final DailyRecommendation recommendation;

  const WorkoutDetailsScreen({super.key, required this.recommendation});

  /// Combined equipment needed across all exercises in this session.
  /// Empty if every exercise is bodyweight, or if equipment tracking
  /// hasn't been populated in the library yet.
  Set<String> get _allEquipment {
    final tags = <String>{};
    for (final prescription in recommendation.exercises) {
      tags.addAll(prescription.exercise.equipmentTags);
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 20),
              _summaryCard(context),
              const SizedBox(height: 20),
              _warmupCard(context),
              const SizedBox(height: 20),
              _exercisesCard(context),
              if (_allEquipment.isNotEmpty) ...[
                const SizedBox(height: 20),
                _equipmentCard(context),
              ],
              const SizedBox(height: 24),
              _startButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    final darkText = colors.primaryText;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: primaryBlue, size: 28),
        ),
        Expanded(
          child: Text(
            recommendation.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 48), // balances the back button for centering
      ],
    );
  }

  Widget _summaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          _summaryStat(context, Icons.timer_outlined, '${recommendation.durationMinutes} min'),
          _summaryStat(context, Icons.fitness_center_rounded, recommendation.targetMuscles),
          _summaryStat(context, Icons.bar_chart_rounded, recommendation.difficulty),
        ],
      ),
    );
  }

  Widget _summaryStat(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    final darkText = colors.primaryText;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: primaryBlue, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: darkText, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// PLACEHOLDER: warm-up isn't modelled yet anywhere (no field on
  /// DailyRecommendation or Exercise). Showing a generic static entry so
  /// the screen matches the wireframe layout; wire up real warm-up content
  /// once that's designed - e.g. a fixed list of mobility drills, or a
  /// per-goal warm-up template.
  Widget _warmupCard(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    final darkText = colors.primaryText;
    final greyText = colors.secondaryText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Icon(Icons.directions_run_rounded, color: primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warm-up (5 min)',
                  style: TextStyle(color: darkText, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Dynamic warm-up routine',
                  style: TextStyle(color: greyText, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: greyText),
        ],
      ),
    );
  }

  Widget _exercisesCard(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final darkText = colors.primaryText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercises',
            style: TextStyle(color: darkText, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(recommendation.exercises.length, (index) {
            final prescription = recommendation.exercises[index];
            return _exerciseRow(context, index + 1, prescription);
          }),
        ],
      ),
    );
  }

  Widget _exerciseRow(BuildContext context, int number, ExercisePrescription prescription) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    final darkText = colors.primaryText;
    final greyText = colors.secondaryText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$number',
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prescription.exercise.name,
              style: TextStyle(color: darkText, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${prescription.sets} sets',
            style: TextStyle(color: greyText, fontSize: 13),
          ),
          const SizedBox(width: 10),
          Text(
            '${prescription.repsMin}-${prescription.repsMax} reps',
            style: TextStyle(color: greyText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _equipmentCard(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    final darkText = colors.primaryText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Equipment',
            style: TextStyle(color: darkText, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allEquipment
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _startButton(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveWorkoutScreen(recommendation: recommendation),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Start Workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 5)),
      ],
    );
  }
}
