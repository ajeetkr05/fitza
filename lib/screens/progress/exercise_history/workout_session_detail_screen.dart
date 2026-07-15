import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../models/progress/workout_entry.dart';
import 'exercise_detail_screen.dart';

class WorkoutSessionDetailScreen extends StatelessWidget {
  final WorkoutEntry workout;

  const WorkoutSessionDetailScreen({
    super.key,
    required this.workout,
  });

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color successGreen = Color(0xFF2E7D32);

  Color get _iconColor {
    switch (workout.workoutType) {
      case 'Yoga':
        return Colors.deepPurple;
      case 'Calisthenics':
        return successGreen;
      case 'Cardio':
        return Colors.orange;
      default:
        return primaryBlue;
    }
  }

  IconData get _icon {
    switch (workout.workoutType) {
      case 'Yoga':
        return Icons.self_improvement_outlined;
      case 'Calisthenics':
        return Icons.accessibility_new_rounded;
      case 'Cardio':
        return Icons.monitor_heart_outlined;
      default:
        return Icons.fitness_center_outlined;
    }
  }

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _softBackground(BuildContext context, Color color) {
    return color.withValues(alpha: _isDark(context) ? 0.20 : 0.10);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  num? _numberValue(dynamic value) {
    if (value is num) {
      return value;
    }

    return double.tryParse(value?.toString() ?? '');
  }

  num? _firstNumber(Map<String, dynamic> exercise, List<String> keys) {
    for (final key in keys) {
      final value = _numberValue(exercise[key]);

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _exerciseName(Map<String, dynamic> exercise) {
    final name = exercise['name']?.toString().trim() ?? '';
    return name.isEmpty ? 'Exercise' : name;
  }

  String _exerciseDetails(Map<String, dynamic> exercise) {
    if (workout.workoutType == 'Gym') {
      final parts = <String>[];

      final sets = _firstNumber(exercise, ['sets']);
      final reps = _firstNumber(exercise, ['reps']);
      final weight = _firstNumber(exercise, ['weightKg', 'weight']);

      if (sets != null) {
        parts.add('${_formatNumber(sets)} sets');
      }

      if (reps != null) {
        parts.add('${_formatNumber(reps)} reps');
      }

      if (weight != null) {
        parts.add('${_formatNumber(weight)} kg');
      }

      return parts.isEmpty ? 'No details saved' : parts.join(' × ');
    }

    if (workout.workoutType == 'Cardio') {
      final parts = <String>[];

      final duration = _firstNumber(exercise, ['durationMinutes', 'reps']);
      final distance = _firstNumber(exercise, ['distanceKm', 'distance']);
      final steps = _firstNumber(exercise, ['steps']);
      final calories = _firstNumber(
        exercise,
        ['caloriesBurned', 'calories'],
      );

      if (duration != null) {
        parts.add('${_formatNumber(duration)} min');
      }

      if (distance != null) {
        parts.add('${_formatNumber(distance)} km');
      }

      if (steps != null) {
        parts.add('${_formatNumber(steps)} steps');
      }

      if (calories != null) {
        parts.add('${_formatNumber(calories)} kcal');
      }

      return parts.isEmpty
          ? '${workout.durationMinutes} min'
          : parts.join(' • ');
    }

    final parts = <String>[];

    final duration = _firstNumber(exercise, ['durationMinutes', 'reps']);
    final sets = _firstNumber(exercise, ['sets']);
    final difficulty = exercise['difficulty']?.toString().trim() ?? '';

    if (duration != null) {
      parts.add('${_formatNumber(duration)} min');
    }

    if (sets != null) {
      parts.add('${_formatNumber(sets)} sets');
    }

    if (difficulty.isNotEmpty) {
      parts.add(difficulty);
    }

    return parts.isEmpty ? '${workout.durationMinutes} min' : parts.join(' • ');
  }

  void _openExerciseDetail(
    BuildContext context,
    Map<String, dynamic> exercise,
  ) {
    final name = _exerciseName(exercise);
    final details = _exerciseDetails(exercise);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          exerciseName: name,
          workoutType: workout.workoutType,
          latestDetails: details,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitzaColors = _colors(context);
    final exerciseCount = workout.exercises.length;

    return Scaffold(
      backgroundColor: fitzaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: fitzaColors.primaryText,
                      size: 29,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      workout.workoutName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 18),

              _summaryCard(context, exerciseCount),

              const SizedBox(height: 16),

              Text(
                'Exercises',
                style: TextStyle(
                  color: fitzaColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 10),

              if (workout.exercises.isEmpty)
                _emptyCard(context)
              else
                ...List.generate(
                  workout.exercises.length,
                  (index) {
                    final exercise = workout.exercises[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == workout.exercises.length - 1 ? 0 : 10,
                      ),
                      child: _exerciseCard(context, exercise),
                    );
                  },
                ),

              if (workout.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _notesCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, int exerciseCount) {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: _softBackground(context, _iconColor),
            child: Icon(
              _icon,
              color: _iconColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fitzaColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${workout.workoutType} • $exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'} • ${_formatDate(workout.recordedAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fitzaColors.secondaryText,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(
    BuildContext context,
    Map<String, dynamic> exercise,
  ) {
    final fitzaColors = _colors(context);

    return Material(
      color: fitzaColors.inputSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openExerciseDetail(context, exercise),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: fitzaColors.border,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: _softBackground(context, _iconColor),
                child: Icon(
                  _icon,
                  color: _iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _exerciseName(exercise),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _exerciseDetails(exercise),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fitzaColors.secondaryText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: fitzaColors.secondaryText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notesCard(BuildContext context) {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            workout.notes,
            style: TextStyle(
              color: fitzaColors.secondaryText,
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Text(
        'No exercises saved in this workout.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: fitzaColors.secondaryText,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final fitzaColors = _colors(context);

    return BoxDecoration(
      color: fitzaColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: _isDark(context)
              ? const Color(0x33000000)
              : const Color(0x0F000000),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}