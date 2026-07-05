import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation.dart';
import 'add_weight/add_weight_screen.dart';
import 'log_workout/select_workout_type_screen.dart';
import 'exercise_history/exercise_history_screen.dart';
import 'trends/trends_screen.dart';
import '../../models/progress/weight_entry.dart';
import '../../models/progress/workout_entry.dart';
import '../../services/progress/weight_firestore_service.dart';
import '../../services/progress/workout_firestore_service.dart';

class ProgressDashboardScreen extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const ProgressDashboardScreen({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color background = Color(0xFFF5F5F5);
  static const Color successGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: selectedIndex,
        onTap: onTabChanged,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topHeader(),

              const SizedBox(height: 28),

              const Text(
                'Your Progress',
                style: TextStyle(
                  color: darkText,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 22),

              StreamBuilder<List<WeightEntry>>(
                stream: WeightFirestoreService.instance.getWeightEntriesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _weightAndBmiCards(
                      weightValue: '—',
                      weightSubtitle: 'Could not load\nweight data',
                      weightSubtitleColor: Colors.red,
                      bmiValue: '—',
                      bmiSubtitle: 'Try again',
                      bmiSubtitleColor: Colors.red,
                    );
                  }

                  if (!snapshot.hasData) {
                    return _weightAndBmiCards(
                      weightValue: '—',
                      weightSubtitle: 'Loading...',
                      weightSubtitleColor: primaryBlue,
                      bmiValue: '—',
                      bmiSubtitle: 'Loading...',
                      bmiSubtitleColor: primaryBlue,
                    );
                  }

                  final entries = snapshot.data!;

                  if (entries.isEmpty) {
                    return _weightAndBmiCards(
                      weightValue: '—',
                      weightSubtitle: 'No weight\nlogged yet',
                      weightSubtitleColor: darkText,
                      bmiValue: '—',
                      bmiSubtitle: 'Add weight',
                      bmiSubtitleColor: darkText,
                    );
                  }

                  final latestEntry = entries.last;
                  final previousEntry =
                      entries.length >= 2 ? entries[entries.length - 2] : null;

                  final changeKg = previousEntry == null
                      ? null
                      : latestEntry.weightKg - previousEntry.weightKg;

                  final weightSubtitle = changeKg == null
                      ? 'Latest entry'
                      : changeKg == 0
                          ? 'No change\nvs previous entry'
                          : changeKg < 0
                              ? '↓ ${changeKg.abs().toStringAsFixed(1)} kg\nvs previous entry'
                              : '↑ ${changeKg.toStringAsFixed(1)} kg\nvs previous entry';

                  final isWithinStandardRange =
                      latestEntry.bmi >= 18.5 && latestEntry.bmi < 25;

                  return _weightAndBmiCards(
                    weightValue: latestEntry.weightKg.toStringAsFixed(1),
                    weightSubtitle: weightSubtitle,
                    weightSubtitleColor:
                        changeKg == null || changeKg == 0
                            ? primaryBlue
                            : changeKg < 0
                                ? successGreen
                                : Colors.orange,
                    bmiValue: latestEntry.bmi.toStringAsFixed(1),
                    bmiSubtitle: isWithinStandardRange
                        ? 'Within range'
                        : 'Check trend',
                    bmiSubtitleColor:
                        isWithinStandardRange ? successGreen : Colors.orange,
                  );
                },
              ),

              const SizedBox(height: 12),

              StreamBuilder<List<WorkoutEntry>>(
                stream: WorkoutFirestoreService.instance.getWorkoutEntriesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _workoutSummaryCards(
                      streakValue: '—',
                      streakUnit: 'days',
                      streakSubtitle: 'Could not load',
                      streakSubtitleColor: Colors.red,
                      workoutsValue: '—',
                      workoutsUnit: 'workouts',
                      workoutsSubtitle: 'Could not load',
                      workoutsSubtitleColor: Colors.red,
                    );
                  }

                  if (!snapshot.hasData) {
                    return _workoutSummaryCards(
                      streakValue: '—',
                      streakUnit: 'days',
                      streakSubtitle: 'Loading...',
                      streakSubtitleColor: primaryBlue,
                      workoutsValue: '—',
                      workoutsUnit: 'workouts',
                      workoutsSubtitle: 'Loading...',
                      workoutsSubtitleColor: primaryBlue,
                    );
                  }

                  final workouts = snapshot.data!;
                  final streakDays = _currentWorkoutStreak(workouts);
                  final workoutsThisWeek = _workoutsThisWeek(workouts);
                  final hasWorkoutToday = _hasWorkoutToday(workouts);

                  return _workoutSummaryCards(
                    streakValue: streakDays.toString(),
                    streakUnit: streakDays == 1 ? 'day' : 'days',
                    streakSubtitle: workouts.isEmpty
                        ? 'Log a workout'
                        : hasWorkoutToday
                            ? streakDays == 1
                                ? 'Started today'
                                : 'Keep it going'
                            : 'Start one today',
                    streakSubtitleColor:
                        hasWorkoutToday ? successGreen : primaryBlue,
                    workoutsValue: workoutsThisWeek.toString(),
                    workoutsUnit:
                        workoutsThisWeek == 1 ? 'workout' : 'workouts',
                    workoutsSubtitle: workoutsThisWeek == 0
                        ? 'No workouts yet'
                        : 'Keep moving',
                    workoutsSubtitleColor: workoutsThisWeek == 0
                        ? primaryBlue
                        : successGreen,
                  );
                },
              ),

              const SizedBox(height: 18),

              _weightTrendCard(context),

              const SizedBox(height: 18),

              _recentWorkoutsCard(context),

              const SizedBox(height: 18),

              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      context,
                      icon: Icons.fitness_center_outlined,
                      label: 'Log Workout',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SelectWorkoutTypeScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(
                      context,
                      icon: Icons.monitor_weight_outlined,
                      label: 'Add Weight',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddWeightScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      context,
                      icon: Icons.history_rounded,
                      label: 'Exercise History',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExerciseHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(
                      context,
                      icon: Icons.show_chart_rounded,
                      label: 'View Trends',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TrendsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.menu_rounded,
            color: darkText,
            size: 30,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.bolt_rounded,
          color: primaryBlue,
          size: 42,
        ),
        const SizedBox(width: 8),
        const Text(
          'Your Progress',
          style: TextStyle(
            color: darkText,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: darkText,
          ),
        ),
      ],
    );
  }

  Widget _weightAndBmiCards({
    required String weightValue,
    required String weightSubtitle,
    required Color weightSubtitleColor,
    required String bmiValue,
    required String bmiSubtitle,
    required Color bmiSubtitleColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.monitor_weight_outlined,
            iconColor: primaryBlue,
            title: 'Current Weight',
            value: weightValue,
            unit: 'kg',
            subtitle: weightSubtitle,
            subtitleColor: weightSubtitleColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.favorite_border_rounded,
            iconColor: successGreen,
            title: 'BMI',
            value: bmiValue,
            unit: '',
            subtitle: bmiSubtitle,
            subtitleColor: bmiSubtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _workoutSummaryCards({
    required String streakValue,
    required String streakUnit,
    required String streakSubtitle,
    required Color streakSubtitleColor,
    required String workoutsValue,
    required String workoutsUnit,
    required String workoutsSubtitle,
    required Color workoutsSubtitleColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.trending_up_rounded,
            iconColor: successGreen,
            title: 'Workout Streak',
            value: streakValue,
            unit: streakUnit,
            subtitle: streakSubtitle,
            subtitleColor: streakSubtitleColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.fitness_center_outlined,
            iconColor: primaryBlue,
            title: 'Workouts\nThis Week',
            value: workoutsValue,
            unit: workoutsUnit,
            subtitle: workoutsSubtitle,
            subtitleColor: workoutsSubtitleColor,
          ),
        ),
      ],
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _hasWorkoutToday(List<WorkoutEntry> workouts) {
    final today = _dateOnly(DateTime.now());

    return workouts.any(
      (workout) => _dateOnly(workout.recordedAt) == today,
    );
  }

  int _currentWorkoutStreak(List<WorkoutEntry> workouts) {
    final workoutDays = workouts
        .map((workout) => _dateOnly(workout.recordedAt))
        .toSet();

    var checkingDate = _dateOnly(DateTime.now());
    var streak = 0;

    while (workoutDays.contains(checkingDate)) {
      streak++;
      checkingDate = checkingDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _workoutsThisWeek(List<WorkoutEntry> workouts) {
    final today = _dateOnly(DateTime.now());

    final weekStart = today.subtract(
      Duration(days: today.weekday - 1),
    );

    return workouts.where((workout) {
      final workoutDay = _dateOnly(workout.recordedAt);

      return !workoutDay.isBefore(weekStart) &&
          !workoutDay.isAfter(today);
    }).length;
  }

  IconData _workoutIcon(String workoutType) {
    switch (workoutType) {
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

  Color _workoutIconColor(String workoutType) {
    switch (workoutType) {
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

  String _recentWorkoutTitle(WorkoutEntry workout) {
    if (workout.exercises.isNotEmpty) {
      final name = workout.exercises.first['name']?.toString().trim() ?? '';

      if (name.isNotEmpty) {
        return name;
      }
    }

    return '${workout.workoutType} Workout';
  }

  String _recentWorkoutDetails(WorkoutEntry workout) {
    final parts = <String>[workout.workoutType];

    if (workout.durationMinutes > 0) {
      parts.add('${workout.durationMinutes} min');
    }

    if (workout.workoutType == 'Cardio' &&
        workout.exercises.isNotEmpty) {
      final distanceValue = workout.exercises.first['distanceKm'];
      final distance = distanceValue is num
          ? distanceValue
          : double.tryParse(distanceValue?.toString() ?? '');

      if (distance != null) {
        final formattedDistance = distance % 1 == 0
            ? distance.toInt().toString()
            : distance.toStringAsFixed(1);

        parts.add('$formattedDistance km');
      }
    } else if (workout.exercises.length > 1) {
      parts.add('${workout.exercises.length} exercises');
    }

    return parts.join(' • ');
  }

  String _recentWorkoutTime(DateTime date) {
    final today = _dateOnly(DateTime.now());
    final workoutDay = _dateOnly(date);
    final difference = today.difference(workoutDay).inDays;

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

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Container(
      height: 185,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5B6475),
              fontSize: 13,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: Color(0xFF45536A),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weightTrendCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Weight Trend',
                style: TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrendsScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'View Trends',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: primaryBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
          StreamBuilder<List<WeightEntry>>(
            stream: WeightFirestoreService.instance.getWeightEntriesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SizedBox(
                  height: 155,
                  child: Center(
                    child: Text(
                      'Could not load weight trend.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 155,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final entries = snapshot.data!;

              if (entries.isEmpty) {
                return const SizedBox(
                  height: 155,
                  child: Center(
                    child: Text(
                      'Add a weight entry to see your trend.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }

              final chartEntries =
                  entries.length > 7 ? entries.sublist(entries.length - 7) : entries;

              final values =
                  chartEntries.map((entry) => entry.weightKg).toList();

              final labels = chartEntries
                  .map((entry) => _weightChartLabel(entry.recordedAt))
                  .toList();

              final latestEntry = entries.last;
              final previousEntry =
                  entries.length >= 2 ? entries[entries.length - 2] : null;

              String changeText;
              Color changeTextColor;
              Color changeBackgroundColor;

              if (previousEntry == null) {
                changeText = 'Latest saved entry';
                changeTextColor = primaryBlue;
                changeBackgroundColor = const Color(0xFFEAF3FF);
              } else {
                final changeKg = latestEntry.weightKg - previousEntry.weightKg;

                if (changeKg < 0) {
                  changeText =
                      '↓ ${changeKg.abs().toStringAsFixed(1)} kg vs previous entry';
                  changeTextColor = successGreen;
                  changeBackgroundColor = const Color(0xFFE8F7EC);
                } else if (changeKg > 0) {
                  changeText =
                      '↑ ${changeKg.toStringAsFixed(1)} kg vs previous entry';
                  changeTextColor = Colors.orange;
                  changeBackgroundColor = const Color(0xFFFFF4E5);
                } else {
                  changeText = 'No change vs previous entry';
                  changeTextColor = primaryBlue;
                  changeBackgroundColor = const Color(0xFFEAF3FF);
                }
              }

              return Column(
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 155,
                    child: _SimpleWeightChart(
                      values: values,
                      labels: labels,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: changeBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      changeText,
                      style: TextStyle(
                        color: changeTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _weightChartLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _recentWorkoutsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Recent Workouts',
                style: TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExerciseHistoryScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<WorkoutEntry>>(
            stream: WorkoutFirestoreService.instance.getWorkoutEntriesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Could not load recent workouts.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                );
              }

              final recentWorkouts = snapshot.data!
                  .reversed
                  .take(3)
                  .toList();

              if (recentWorkouts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Save a workout to see it here.',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 15,
                    ),
                  ),
                );
              }

              return Column(
                children: List.generate(
                  recentWorkouts.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == recentWorkouts.length - 1 ? 0 : 10,
                    ),
                    child: _workoutRow(
                      workout: recentWorkouts[index],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _workoutRow({
    required WorkoutEntry workout,
  }) {
    final iconColor = _workoutIconColor(workout.workoutType);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: iconColor.withValues(alpha: 0.10),
            child: Icon(
              _workoutIcon(workout.workoutType),
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recentWorkoutTitle(workout),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _recentWorkoutDetails(workout),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5B6475),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _recentWorkoutTime(workout.recordedAt),
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap ?? () => _showComingSoon(context, label),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E7F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryBlue, size: 27),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$pageName screen will be connected next.'),
      ),
    );
  }
}

class _SimpleWeightChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _SimpleWeightChart({
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WeightChartPainter(
        values: values,
        labels: labels,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _WeightChartPainter({
    required this.values,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE1E7F0)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF1555C0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = const Color(0xFF1555C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const topPadding = 10.0;
    const bottomPadding = 28.0;
    const sidePadding = 8.0;

    final chartWidth = size.width - (sidePadding * 2);
    final chartHeight = size.height - topPadding - bottomPadding;

    for (int i = 0; i < 4; i++) {
      final y = topPadding + i * chartHeight / 3;

      canvas.drawLine(
        Offset(sidePadding, y),
        Offset(size.width - sidePadding, y),
        gridPaint,
      );
    }

    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);

    final originalRange = maximum - minimum;
    final chartRange = originalRange == 0 ? 1.0 : originalRange;

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final horizontalPosition =
          values.length == 1 ? 0.5 : i / (values.length - 1);

      final x = sidePadding + (chartWidth * horizontalPosition);

      final normalizedValue = (values[i] - minimum) / chartRange;
      final y = topPadding +
          chartHeight -
          (normalizedValue * chartHeight * 0.72) -
          (chartHeight * 0.14);

      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, linePaint);
    }

    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(point, 5, pointBorderPaint);
    }

    for (final index in _labelIndexes(labels.length)) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: const TextStyle(
            color: Color(0xFF5B6475),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final x = points[index].dx - (textPainter.width / 2);

      textPainter.paint(
        canvas,
        Offset(x, size.height - 18),
      );
    }
  }

  List<int> _labelIndexes(int length) {
    if (length <= 3) {
      return List.generate(length, (index) => index);
    }

    return [
      0,
      ((length - 1) / 2).round(),
      length - 1,
    ];
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}