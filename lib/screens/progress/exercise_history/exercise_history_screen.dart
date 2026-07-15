import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../models/progress/workout_entry.dart';
import '../../../services/progress/workout_firestore_service.dart';
import 'workout_session_detail_screen.dart';
import 'exercise_detail_screen.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color successGreen = Color(0xFF2E7D32);

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Gym';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<WorkoutEntry> _filteredWorkouts(List<WorkoutEntry> workouts) {
    final searchText = _searchController.text.trim().toLowerCase();

    final filtered = workouts.where((workout) {
      final matchesCategory = workout.workoutType == _selectedCategory;
      final matchesSearch =
          workout.workoutName.toLowerCase().contains(searchText) ||
              workout.exercises.any(
                (exercise) {
                  final name = exercise['name']?.toString().toLowerCase() ?? '';
                  return name.contains(searchText);
                },
              );

      return matchesCategory && matchesSearch;
    }).toList();

    filtered.sort(
      (first, second) => second.recordedAt.compareTo(first.recordedAt),
    );

    return filtered;
  }

  Color _categoryColor(String category) {
    switch (category) {
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

  IconData _categoryIcon(String category) {
    switch (category) {
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

  String _lastLoggedText(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = todayOnly.difference(dateOnly).inDays;

    if (difference <= 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (difference < 7) {
      return '$difference days ago';
    }

    if (difference < 14) {
      return '1 week ago';
    }

    return '${difference ~/ 7} weeks ago';
  }

  String _cardioWorkoutDetails(WorkoutEntry workout) {
    final parts = <String>['Cardio'];

    if (workout.exercises.isNotEmpty) {
      final exercise = workout.exercises.first;

      final distance = _firstNumber(exercise, ['distanceKm', 'distance']);
      final duration = _firstNumber(exercise, ['durationMinutes', 'reps']);
      final steps = _firstNumber(exercise, ['steps']);
      final calories = _firstNumber(
        exercise,
        ['caloriesBurned', 'calories'],
      );

      if (distance != null) {
        parts.add('${_formatNumber(distance)} km');
      }

      if (duration != null) {
        parts.add('${_formatNumber(duration)} min');
      } else if (workout.durationMinutes > 0) {
        parts.add('${workout.durationMinutes} min');
      }

      if (steps != null) {
        parts.add('${_formatNumber(steps)} steps');
      }

      if (calories != null) {
        parts.add('${_formatNumber(calories)} kcal');
      }
    } else if (workout.durationMinutes > 0) {
      parts.add('${workout.durationMinutes} min');
    }

    return parts.join(' • ');
  }

  String _workoutDetails(WorkoutEntry workout) {
    if (workout.workoutType == 'Cardio') {
      return _cardioWorkoutDetails(workout);
    }

    final count = workout.exercises.length;
    final parts = <String>[
      workout.workoutType,
      '$count ${count == 1 ? 'exercise' : 'exercises'}',
    ];

    if (workout.workoutType != 'Gym' && workout.durationMinutes > 0) {
      parts.add('${workout.durationMinutes} min');
    }

    return parts.join(' • ');
  }

  void _openWorkoutDetail(WorkoutEntry workout) {
    if (workout.workoutType == 'Cardio') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(
            exerciseName: workout.workoutName,
            workoutType: workout.workoutType,
            latestDetails: _cardioWorkoutDetails(workout),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSessionDetailScreen(
          workout: workout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitzaColors = _colors(context);

    return Scaffold(
      backgroundColor: fitzaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
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
                      'Workout History',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _searchInputDecoration(context),
                    ),

                    const SizedBox(height: 16),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _categoryChip('Gym'),
                          const SizedBox(width: 8),
                          _categoryChip('Yoga'),
                          const SizedBox(width: 8),
                          _categoryChip('Calisthenics'),
                          const SizedBox(width: 8),
                          _categoryChip('Cardio'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Recent Workouts',
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    StreamBuilder<List<WorkoutEntry>>(
                      stream:
                          WorkoutFirestoreService.instance.getWorkoutEntriesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _statusCard(
                            icon: Icons.error_outline_rounded,
                            message: 'Could not load your workout history.',
                            iconColor: Colors.red,
                          );
                        }

                        if (!snapshot.hasData) {
                          return _statusCard(
                            icon: Icons.hourglass_top_rounded,
                            message: 'Loading your saved workouts...',
                            iconColor: fitzaColors.primaryBlue,
                            isLoading: true,
                          );
                        }

                        final allWorkouts = snapshot.data!;
                        final workouts = _filteredWorkouts(allWorkouts);

                        if (allWorkouts.isEmpty) {
                          return _statusCard(
                            icon: Icons.fitness_center_outlined,
                            message:
                                'Save a workout to see your workout history.',
                            iconColor: fitzaColors.secondaryText,
                          );
                        }

                        if (workouts.isEmpty) {
                          return _statusCard(
                            icon: Icons.search_off_outlined,
                            message: 'No $_selectedCategory workouts found.',
                            iconColor: fitzaColors.secondaryText,
                          );
                        }

                        return Column(
                          children: List.generate(
                            workouts.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: index == workouts.length - 1 ? 0 : 10,
                              ),
                              child: _workoutCard(workouts[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    final fitzaColors = _colors(context);
    final isSelected = _selectedCategory == label;
    final color = _categoryColor(label);

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : fitzaColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : fitzaColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _categoryIcon(label),
              color: isSelected ? fitzaColors.textOnBlue : color,
              size: 19,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? fitzaColors.textOnBlue
                    : fitzaColors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workoutCard(WorkoutEntry workout) {
    final fitzaColors = _colors(context);
    final color = _categoryColor(workout.workoutType);

    return Material(
      color: fitzaColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openWorkoutDetail(workout),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _softBackground(context, color),
                child: Icon(
                  _categoryIcon(workout.workoutType),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _workoutDetails(workout),
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _lastLoggedText(workout.recordedAt),
                    style: TextStyle(
                      color: fitzaColors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: fitzaColors.secondaryText,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String message,
    required Color iconColor,
    bool isLoading = false,
  }) {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          if (isLoading)
            SizedBox(
              height: 34,
              width: 34,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: fitzaColors.primaryBlue,
              ),
            )
          else
            Icon(
              icon,
              color: iconColor,
              size: 34,
            ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _searchInputDecoration(BuildContext context) {
    final fitzaColors = _colors(context);

    return InputDecoration(
      hintText: 'Search workouts or exercises',
      hintStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        Icons.search_rounded,
        color: fitzaColors.secondaryText,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      filled: true,
      fillColor: fitzaColors.inputSurface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: fitzaColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: fitzaColors.primaryBlue,
          width: 1.7,
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