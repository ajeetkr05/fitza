import 'package:flutter/material.dart';

import '../../../models/progress/workout_entry.dart';
import '../../../services/progress/workout_firestore_service.dart';
import 'exercise_detail_screen.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Gym';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ExerciseSummary> _buildExerciseSummaries(
    List<WorkoutEntry> workouts,
  ) {
    final latestExerciseByKey = <String, _ExerciseSummary>{};

    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        final rawName = exercise['name'];
        final exerciseName = rawName?.toString().trim() ?? '';

        if (exerciseName.isEmpty) {
          continue;
        }

        final key =
            '${workout.workoutType.toLowerCase()}|${exerciseName.toLowerCase()}';

        latestExerciseByKey[key] = _ExerciseSummary(
          name: exerciseName,
          category: workout.workoutType,
          details: _exerciseDetails(workout, exercise),
          recordedAt: workout.recordedAt,
        );
      }
    }

    final summaries = latestExerciseByKey.values.toList();

    summaries.sort(
      (first, second) => second.recordedAt.compareTo(first.recordedAt),
    );

    return summaries;
  }

  List<_ExerciseSummary> _filteredExercises(
    List<_ExerciseSummary> exercises,
  ) {
    final searchText = _searchController.text.trim().toLowerCase();

    return exercises.where((exercise) {
      final matchesCategory = exercise.category == _selectedCategory;
      final matchesSearch = exercise.name.toLowerCase().contains(searchText);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  String _exerciseDetails(
    WorkoutEntry workout,
    Map<String, dynamic> exercise,
  ) {
    if (workout.workoutType == 'Gym') {
      final parts = <String>[];

      final weight = _numberValue(exercise['weightKg']);
      final reps = _numberValue(exercise['reps']);
      final sets = _numberValue(exercise['sets']);

      if (weight != null) {
        parts.add('${_formatNumber(weight)} kg');
      }

      if (reps != null) {
        parts.add('${_formatNumber(reps)} reps');
      }

      if (sets != null) {
        parts.add('${_formatNumber(sets)} sets');
      }

      return parts.isEmpty
          ? '${workout.durationMinutes} min workout'
          : parts.join(' × ');
    }

    if (workout.workoutType == 'Cardio') {
      final parts = <String>[];

      final distance = _numberValue(exercise['distanceKm']);
      final duration = _numberValue(exercise['durationMinutes']);
      final steps = _numberValue(exercise['steps']);
      final calories = _numberValue(exercise['caloriesBurned']);

      if (distance != null) {
        parts.add('${_formatNumber(distance)} km');
      }

      if (duration != null) {
        parts.add('${_formatNumber(duration)} min');
      }

      if (steps != null) {
        parts.add('${_formatNumber(steps)} steps');
      }

      if (calories != null) {
        parts.add('${_formatNumber(calories)} kcal');
      }

      return parts.isEmpty
          ? '${workout.durationMinutes} min workout'
          : parts.join(' • ');
    }

    final parts = <String>[];

    final duration = _numberValue(exercise['durationMinutes']);
    final sets = _numberValue(exercise['sets']);
    final difficulty = exercise['difficulty']?.toString().trim() ?? '';

    if (duration != null) {
      parts.add('${_formatNumber(duration)} min');
    } else {
      parts.add('${workout.durationMinutes} min');
    }

    if (sets != null) {
      parts.add('${_formatNumber(sets)} sets');
    }

    if (difficulty.isNotEmpty) {
      parts.add(difficulty);
    }

    return parts.join(' • ');
  }

  num? _numberValue(dynamic value) {
    if (value is num) {
      return value;
    }

    return double.tryParse(value?.toString() ?? '');
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _lastLoggedText(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = todayOnly.difference(dateOnly).inDays;

    if (difference <= 0) {
      return 'Last logged today';
    }

    if (difference == 1) {
      return 'Last logged yesterday';
    }

    if (difference < 7) {
      return 'Last logged $difference days ago';
    }

    if (difference < 14) {
      return 'Last logged 1 week ago';
    }

    final weeks = difference ~/ 7;
    return 'Last logged $weeks weeks ago';
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

  void _openExerciseDetail(_ExerciseSummary exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          exerciseName: exercise.name,
          workoutType: exercise.category,
          latestDetails: exercise.details,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: primaryBlue,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Exercise History',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkText,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search exercises',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: greyText,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4DDEA),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _categoryChip(
                            label: 'Gym',
                            icon: Icons.fitness_center_outlined,
                          ),
                          const SizedBox(width: 10),
                          _categoryChip(
                            label: 'Yoga',
                            icon: Icons.self_improvement_outlined,
                          ),
                          const SizedBox(width: 10),
                          _categoryChip(
                            label: 'Calisthenics',
                            icon: Icons.accessibility_new_rounded,
                          ),
                          const SizedBox(width: 10),
                          _categoryChip(
                            label: 'Cardio',
                            icon: Icons.monitor_heart_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 34),
                    const Text(
                      'Recent Exercises',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    StreamBuilder<List<WorkoutEntry>>(
                      stream: WorkoutFirestoreService.instance
                          .getWorkoutEntriesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _statusCard(
                            icon: Icons.error_outline_rounded,
                            message: 'Could not load your exercise history.',
                            iconColor: Colors.red,
                          );
                        }

                        if (!snapshot.hasData) {
                          return _statusCard(
                            icon: Icons.hourglass_top_rounded,
                            message: 'Loading your saved workouts...',
                            iconColor: primaryBlue,
                            isLoading: true,
                          );
                        }

                        final allExercises =
                            _buildExerciseSummaries(snapshot.data!);

                        final exercises = _filteredExercises(allExercises);

                        if (allExercises.isEmpty) {
                          return _statusCard(
                            icon: Icons.fitness_center_outlined,
                            message:
                                'Save a workout to see your exercise history.',
                            iconColor: greyText,
                          );
                        }

                        if (exercises.isEmpty) {
                          return _statusCard(
                            icon: Icons.search_off_outlined,
                            message:
                                'No $_selectedCategory exercises found.',
                            iconColor: greyText,
                          );
                        }

                        return Column(
                          children: exercises
                              .map(_exerciseCard)
                              .toList(),
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

  Widget _statusCard({
    required IconData icon,
    required String message,
    required Color iconColor,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (isLoading)
            const SizedBox(
              height: 42,
              width: 42,
              child: CircularProgressIndicator(),
            )
          else
            Icon(
              icon,
              color: iconColor,
              size: 42,
            ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == label;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFB9C9E6),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : darkText,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard(_ExerciseSummary exercise) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openExerciseDetail(exercise),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC8D9F6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _categoryIcon(exercise.category),
                  color: primaryBlue,
                  size: 38,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: greyText,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: exercise.category,
                            style: const TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '  •  ${_lastLoggedText(exercise.recordedAt)}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.details,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: primaryBlue,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseSummary {
  final String name;
  final String category;
  final String details;
  final DateTime recordedAt;

  const _ExerciseSummary({
    required this.name,
    required this.category,
    required this.details,
    required this.recordedAt,
  });
}