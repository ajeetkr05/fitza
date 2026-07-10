import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/fitza_header.dart';
import 'add_weight/add_weight_screen.dart';
import 'log_workout/select_workout_type_screen.dart';
import 'exercise_history/exercise_history_screen.dart';
import 'exercise_history/workout_session_detail_screen.dart';
import 'trends/trends_screen.dart';
import '../../models/progress/weight_entry.dart';
import '../../models/progress/workout_entry.dart';
import '../../services/progress/weight_firestore_service.dart';
import '../../services/progress/workout_firestore_service.dart';
import '../../services/auth/auth_service.dart';

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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FitzaHeader(
                trailing: FitzaHeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Progress Dashboard',
                style: TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 3),

              const Text(
                'Track your weight, workouts, and weekly progress.',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12.5,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

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

                  final bmiCategory = _bmiCategory(latestEntry.bmi);
                  final bmiCategoryColor = _bmiCategoryColor(latestEntry.bmi);

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
                    bmiSubtitle: bmiCategory,
                    bmiSubtitleColor: bmiCategoryColor,
                  );
                },
              ),

              const SizedBox(height: 10),

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

              const SizedBox(height: 16),

              _quickActionsSection(context),

              const SizedBox(height: 16),

              _weightTrendCard(context),

              const SizedBox(height: 16),

              _recentWorkoutsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/icon/icon.png',
          height: 34,
          width: 34,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.bolt_rounded,
              color: primaryBlue,
              size: 34,
            );
          },
        ),
        const SizedBox(width: 10),
        const Text(
          'Fitza',
          style: TextStyle(
            color: darkText,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: darkText,
            size: 23,
          ),
        ),
      ],
    );
  }

  Future<void> _showAccountMenu(BuildContext context) async {
    final shouldSignOut = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Account',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext, true);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldSignOut != true) {
      return;
    }

    try {
      await AuthService.instance.signOut();
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not sign out. Please try again.'),
        ),
      );
    }
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

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    }

    if (bmi < 25.0) {
      return 'Healthy';
    }

    if (bmi < 30.0) {
      return 'Overweight';
    }

    return 'Obese';
  }

  Color _bmiCategoryColor(double bmi) {
    if (bmi >= 18.5 && bmi < 25.0) {
      return successGreen;
    }

    if (bmi >= 30.0) {
      return Colors.red;
    }

    return Colors.orange;
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
    final name = workout.workoutName.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return '${workout.workoutType} Workout';
  }

  String _recentWorkoutDetails(WorkoutEntry workout) {
    final parts = <String>[workout.workoutType];

    if (workout.workoutType != 'Gym' && workout.durationMinutes > 0) {
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
      height: 132,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5B6475),
              fontSize: 11.5,
              height: 1.12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: Color(0xFF45536A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 10.8,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: darkText,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
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
            const SizedBox(width: 10),
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quickAction(
                context,
                icon: Icons.history_rounded,
                label: 'History',
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
            const SizedBox(width: 10),
            Expanded(
              child: _quickAction(
                context,
                icon: Icons.show_chart_rounded,
                label: 'Trends',
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
    );
  }

  Widget _weightTrendCard(BuildContext context) {
    var selectedWindowStart = _threeMonthWindowStart(DateTime.now());

    return StatefulBuilder(
      builder: (context, setChartState) {
        final currentWindowStart = _threeMonthWindowStart(DateTime.now());
        final canGoNext = selectedWindowStart.isBefore(currentWindowStart);

        void goPreviousPeriod() {
          setChartState(() {
            selectedWindowStart = _addMonths(selectedWindowStart, -3);
          });
        }

        void goNextPeriod() {
          if (!canGoNext) {
            return;
          }

          setChartState(() {
            selectedWindowStart = _addMonths(selectedWindowStart, 3);
          });
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Weight Trend',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
                          'View',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: primaryBlue,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;

                  if (velocity > 250) {
                    goPreviousPeriod();
                  } else if (velocity < -250) {
                    goNextPeriod();
                  }
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        _trendArrowButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: goPreviousPeriod,
                        ),
                        Expanded(
                          child: Text(
                            _threeMonthTitle(selectedWindowStart),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: darkText,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        _trendArrowButton(
                          icon: Icons.chevron_right_rounded,
                          enabled: canGoNext,
                          onTap: canGoNext ? goNextPeriod : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    StreamBuilder<List<WeightEntry>>(
                      stream:
                          WeightFirestoreService.instance.getWeightEntriesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const SizedBox(
                            height: 176,
                            child: Center(
                              child: Text(
                                'Could not load weight trend.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const SizedBox(
                            height: 176,
                            child: Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              ),
                            ),
                          );
                        }

                        final periodEntries = _entriesForThreeMonthWindow(
                          snapshot.data!,
                          selectedWindowStart,
                        );

                        final rangeText = _weightRangeLabel(periodEntries);
                        final changeText = _periodWeightChangeText(periodEntries);
                        final changeColor =
                            _periodWeightChangeColor(periodEntries);
                        final changeBackground =
                            _periodWeightChangeBackground(periodEntries);

                        return Column(
                          children: [
                            Text(
                              rangeText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              height: 150,
                              child: _ThreeMonthWeightChart(
                                entries: periodEntries,
                                windowStart: selectedWindowStart,
                                lineColor: primaryBlue,
                                gridColor: const Color(0xFFE1E7F0),
                                textColor: const Color(0xFF667085),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: changeBackground,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                changeText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: changeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _trendArrowButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: Container(
        height: 34,
        width: 34,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 30,
          color: enabled ? const Color(0xFF667085) : const Color(0xFFD0D5DD),
        ),
      ),
    );
  }

  DateTime _threeMonthWindowStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, 1);
  }

  String _threeMonthTitle(DateTime start) {
    final end = _addMonths(start, 2);

    if (start.year == end.year) {
      return '${_monthName(start.month)} – ${_monthName(end.month)} ${end.year}';
    }

    return '${_monthName(start.month)} ${start.year} – ${_monthName(end.month)} ${end.year}';
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return names[month - 1];
  }

  String _shortMonthName(int month) {
    const names = [
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

    return names[month - 1];
  }

  List<WeightEntry> _entriesForThreeMonthWindow(
    List<WeightEntry> entries,
    DateTime start,
  ) {
    final end = _addMonths(start, 3);

    final periodEntries = entries.where((entry) {
      return !entry.recordedAt.isBefore(start) &&
          entry.recordedAt.isBefore(end);
    }).toList();

    periodEntries.sort(
      (a, b) => a.recordedAt.compareTo(b.recordedAt),
    );

    return periodEntries;
  }

  String _weightRangeLabel(List<WeightEntry> entries) {
    if (entries.isEmpty) {
      return 'No weight data';
    }

    final weights = entries.map((entry) => entry.weightKg).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    if ((maxWeight - minWeight).abs() < 0.05) {
      return '${maxWeight.toStringAsFixed(1)} kg';
    }

    return '${minWeight.toStringAsFixed(1)}–${maxWeight.toStringAsFixed(1)} kg';
  }

  String _periodWeightChangeText(List<WeightEntry> entries) {
    if (entries.isEmpty) {
      return 'No saved weight this period';
    }

    if (entries.length == 1) {
      return 'Latest saved entry';
    }

    final changeKg = entries.last.weightKg - entries.first.weightKg;

    if (changeKg < 0) {
      return '↓ ${changeKg.abs().toStringAsFixed(1)} kg this period';
    }

    if (changeKg > 0) {
      return '↑ ${changeKg.toStringAsFixed(1)} kg this period';
    }

    return 'No change this period';
  }

  Color _periodWeightChangeColor(List<WeightEntry> entries) {
    if (entries.length < 2) {
      return primaryBlue;
    }

    final changeKg = entries.last.weightKg - entries.first.weightKg;

    if (changeKg < 0) {
      return successGreen;
    }

    if (changeKg > 0) {
      return Colors.orange;
    }

    return primaryBlue;
  }

  Color _periodWeightChangeBackground(List<WeightEntry> entries) {
    if (entries.length < 2) {
      return const Color(0xFFEAF3FF);
    }

    final changeKg = entries.last.weightKg - entries.first.weightKg;

    if (changeKg < 0) {
      return const Color(0xFFE8F7EC);
    }

    if (changeKg > 0) {
      return const Color(0xFFFFF4E5);
    }

    return const Color(0xFFEAF3FF);
  }

  Widget _recentWorkoutsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Recent Workouts',
                style: TextStyle(
                  color: darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<List<WorkoutEntry>>(
            stream: WorkoutFirestoreService.instance.getWorkoutEntriesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Could not load recent workouts.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                );
              }

              final recentWorkouts = snapshot.data!
                  .reversed
                  .take(3)
                  .toList();

              if (recentWorkouts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.fitness_center_outlined,
                        color: Color(0xFF98A2B3),
                        size: 28,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Save a workout to see it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
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
                      context,
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

  Widget _workoutRow(
    BuildContext context, {
    required WorkoutEntry workout,
  }) {
    final iconColor = _workoutIconColor(workout.workoutType);
    final exerciseTitle = _recentWorkoutTitle(workout);
    final workoutDetails = _recentWorkoutDetails(workout);

    return Material(
      color: const Color(0xFFF9FBFE),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutSessionDetailScreen(
                workout: workout,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E7F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: iconColor.withValues(alpha: 0.10),
                child: Icon(
                  _workoutIcon(workout.workoutType),
                  color: iconColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      workoutDetails,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5B6475),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _recentWorkoutTime(workout.recordedAt),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF98A2B3),
                    size: 21,
                  ),
                ],
              ),
            ],
          ),
        ),
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
      borderRadius: BorderRadius.circular(15),
      onTap: onTap ?? () => _showComingSoon(context, label),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE1E7F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFEAF3FF),
              child: Icon(icon, color: primaryBlue, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w800,
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
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 10,
          offset: Offset(0, 4),
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

class _ThreeMonthWeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final DateTime windowStart;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  const _ThreeMonthWeightChart({
    required this.entries,
    required this.windowStart,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ThreeMonthWeightChartPainter(
        entries: entries,
        windowStart: windowStart,
        lineColor: lineColor,
        gridColor: gridColor,
        textColor: textColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ThreeMonthWeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final DateTime windowStart;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _ThreeMonthWeightChartPainter({
    required this.entries,
    required this.windowStart,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = 2.0;
    final chartRight = size.width - 34;
    const chartTop = 8.0;
    final chartBottom = size.height - 30;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final axisPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.2;

    final tickPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final sortedEntries = [...entries]..sort(
        (a, b) => a.recordedAt.compareTo(b.recordedAt),
      );

    final axisValues = _axisValues(sortedEntries);

    for (final value in axisValues) {
      final y = _yPosition(
        value: value,
        upper: axisValues.first,
        lower: axisValues.last,
        chartTop: chartTop,
        chartHeight: chartHeight,
      );

      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        axisPaint,
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: _formatAxisLabel(value),
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(chartRight + 8, y - labelPainter.height / 2),
      );
    }

    final windowEnd = DateTime(
      windowStart.year,
      windowStart.month + 3,
      1,
    );

    final totalWindowMilliseconds =
        windowEnd.difference(windowStart).inMilliseconds;

    for (int i = 0; i < 3; i++) {
      final monthDate = DateTime(
        windowStart.year,
        windowStart.month + i,
        1,
      );

      final monthFraction =
          monthDate.difference(windowStart).inMilliseconds /
              totalWindowMilliseconds;

      final x = chartLeft + (chartWidth * monthFraction);

      canvas.drawLine(
        Offset(x, chartBottom),
        Offset(x, chartBottom + 5),
        tickPaint,
      );

      final monthText = _shortMonthNameForPainter(monthDate.month);
      final monthPainter = TextPainter(
        text: TextSpan(
          text: monthText,
          style: TextStyle(
            color: i == 0 ? const Color(0xFF0B1B4D) : textColor,
            fontSize: 12,
            fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      double labelX = x - monthPainter.width / 2;

      if (i == 0) {
        labelX = chartLeft;
      }

      monthPainter.paint(
        canvas,
        Offset(labelX, chartBottom + 10),
      );
    }

    if (sortedEntries.isEmpty) {
      return;
    }

    final points = <Offset>[];

    for (final entry in sortedEntries) {
      final entryMilliseconds =
          entry.recordedAt.difference(windowStart).inMilliseconds;

      final fraction =
          (entryMilliseconds / totalWindowMilliseconds).clamp(0.0, 1.0);

      final x = chartLeft + (chartWidth * fraction);

      final y = _yPosition(
        value: entry.weightKg,
        upper: axisValues.first,
        lower: axisValues.last,
        chartTop: chartTop,
        chartHeight: chartHeight,
      );

      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pointFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, linePaint);
    }

    for (final point in points) {
      canvas.drawCircle(point, 3, pointFillPaint);
      canvas.drawCircle(point, 3, pointBorderPaint);
    }
  }

  List<double> _axisValues(List<WeightEntry> sortedEntries) {
    if (sortedEntries.isEmpty) {
      return const [77, 75, 73];
    }

    final weights = sortedEntries.map((entry) => entry.weightKg).toList();

    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;

    double lower;
    double upper;

    if (range <= 2) {
      lower = (minWeight - 1.5).floorToDouble();
      upper = (maxWeight + 1.5).ceilToDouble();
    } else {
      lower = (minWeight - 1).floorToDouble();
      upper = (maxWeight + 1).ceilToDouble();
    }

    if (upper <= lower) {
      upper = lower + 2;
    }

    final middle = (upper + lower) / 2;

    return [upper, middle, lower];
  }

  double _yPosition({
    required double value,
    required double upper,
    required double lower,
    required double chartTop,
    required double chartHeight,
  }) {
    final range = upper - lower;

    if (range == 0) {
      return chartTop + chartHeight / 2;
    }

    final normalized = (upper - value) / range;

    return chartTop + (chartHeight * normalized);
  }

  String _formatAxisLabel(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _shortMonthNameForPainter(int month) {
    const names = [
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

    return names[month - 1];
  }

  @override
  bool shouldRepaint(covariant _ThreeMonthWeightChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.windowStart != windowStart;
  }
}