import 'package:flutter/material.dart';

import '../../../models/progress/weight_entry.dart';
import '../../../models/progress/workout_entry.dart';
import '../../../services/progress/weight_firestore_service.dart';
import '../../../services/progress/workout_firestore_service.dart';

class TrendsScreen extends StatefulWidget {
  final String initialTrendType;
  final String initialTimeRange;

  const TrendsScreen({
    super.key,
    this.initialTrendType = 'Weight',
    this.initialTimeRange = 'Weekly',
  });

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color successGreen = Color(0xFF2E7D32);

  late String _selectedTrend;
  late String _selectedRange;

  final List<String> _trendTypes = [
    'Weight',
    'BMI',
    'Workouts',
    'Steps / Activity',
  ];

  final List<String> _timeRanges = [
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTrend = widget.initialTrendType;
    _selectedRange = widget.initialTimeRange;
  }

  bool get _usesFirestoreTrend {
    return _selectedTrend == 'Weight' || _selectedTrend == 'BMI';
  }

  List<WeightEntry> _entriesForSelectedRange(
    List<WeightEntry> entries,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime startDate;

    if (_selectedRange == 'Weekly') {
      startDate = today.subtract(const Duration(days: 6));
    } else if (_selectedRange == 'Monthly') {
      startDate = today.subtract(const Duration(days: 29));
    } else {
      startDate = today.subtract(const Duration(days: 364));
    }

    return entries
        .where((entry) => !entry.recordedAt.isBefore(startDate))
        .toList();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _workoutRangeStartDate(DateTime today) {
    if (_selectedRange == 'Weekly') {
      return today.subtract(const Duration(days: 6));
    }

    if (_selectedRange == 'Monthly') {
      return today.subtract(const Duration(days: 29));
    }

    return today.subtract(const Duration(days: 364));
  }

  List<WorkoutEntry> _workoutsForSelectedRange(
    List<WorkoutEntry> workouts,
  ) {
    final today = _dateOnly(DateTime.now());
    final startDate = _workoutRangeStartDate(today);

    return workouts.where((workout) {
      final workoutDay = _dateOnly(workout.recordedAt);

      return !workoutDay.isBefore(startDate) &&
          !workoutDay.isAfter(today);
    }).toList();
  }

  List<_WorkoutTrendPoint> _buildWorkoutTrendPoints(
    List<WorkoutEntry> workouts,
  ) {
    final today = _dateOnly(DateTime.now());
    final startDate = _workoutRangeStartDate(today);

    final totalDays = today.difference(startDate).inDays + 1;
    final pointCount = totalDays < 7 ? totalDays : 7;

    return List.generate(pointCount, (index) {
      final startOffset = index * totalDays ~/ pointCount;
      final endOffset = ((index + 1) * totalDays ~/ pointCount) - 1;

      final bucketStart = startDate.add(Duration(days: startOffset));
      final bucketEnd = startDate.add(Duration(days: endOffset));

      final workoutCount = workouts.where((workout) {
        final workoutDay = _dateOnly(workout.recordedAt);

        return !workoutDay.isBefore(bucketStart) &&
            !workoutDay.isAfter(bucketEnd);
      }).length;

      return _WorkoutTrendPoint(
        label: _formatTrendDate(bucketEnd),
        value: workoutCount.toDouble(),
      );
    });
  }

  String _workoutCountLabel(int count) {
    return '$count ${count == 1 ? 'workout' : 'workouts'}';
  }

  num? _numberValue(dynamic value) {
    if (value is num) {
      return value;
    }

    return double.tryParse(value?.toString() ?? '');
  }

  List<_StepEntry> _stepEntriesForSelectedRange(
    List<WorkoutEntry> allWorkouts,
  ) {
    final rangeWorkouts = _workoutsForSelectedRange(allWorkouts);
    final stepEntries = <_StepEntry>[];

    for (final workout in rangeWorkouts) {
      if (workout.workoutType != 'Cardio') {
        continue;
      }

      for (final exercise in workout.exercises) {
        final stepsValue = _numberValue(exercise['steps']);

        if (stepsValue == null || stepsValue <= 0) {
          continue;
        }

        stepEntries.add(
          _StepEntry(
            recordedAt: workout.recordedAt,
            steps: stepsValue.toDouble(),
          ),
        );
      }
    }

    stepEntries.sort(
      (first, second) => first.recordedAt.compareTo(second.recordedAt),
    );

    return stepEntries;
  }

  List<_ActivityTrendPoint> _buildActivityTrendPoints(
    List<_StepEntry> stepEntries,
  ) {
    final today = _dateOnly(DateTime.now());
    final startDate = _workoutRangeStartDate(today);

    final totalDays = today.difference(startDate).inDays + 1;
    final pointCount = totalDays < 7 ? totalDays : 7;

    return List.generate(pointCount, (index) {
      final startOffset = index * totalDays ~/ pointCount;
      final endOffset = ((index + 1) * totalDays ~/ pointCount) - 1;

      final bucketStart = startDate.add(Duration(days: startOffset));
      final bucketEnd = startDate.add(Duration(days: endOffset));

      final stepsInBucket = stepEntries
          .where((entry) {
            final entryDate = _dateOnly(entry.recordedAt);

            return !entryDate.isBefore(bucketStart) &&
                !entryDate.isAfter(bucketEnd);
          })
          .fold<double>(
            0,
            (total, entry) => total + entry.steps,
          );

      return _ActivityTrendPoint(
        label: _formatTrendDate(bucketEnd),
        value: stepsInBucket,
      );
    });
  }

  String _formatStepCount(double steps) {
    if (steps < 1000) {
      return steps.toStringAsFixed(0);
    }

    final thousands = steps / 1000;

    if (thousands % 1 == 0) {
      return '${thousands.toInt()}k';
    }

    return '${thousands.toStringAsFixed(1)}k';
  }

  String _formatTrendDate(DateTime date) {
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

  String get _periodLabel {
    if (_selectedRange == 'Weekly') {
      return 'week';
    }

    if (_selectedRange == 'Monthly') {
      return 'month';
    }

    return 'year';
  }

  IconData _trendIcon(String trend) {
    switch (trend) {
      case 'BMI':
        return Icons.monitor_weight_outlined;
      case 'Workouts':
        return Icons.fitness_center_outlined;
      case 'Steps / Activity':
        return Icons.directions_walk_outlined;
      default:
        return Icons.scale_outlined;
    }
  }

  String get _chartTitle {
    switch (_selectedTrend) {
      case 'BMI':
        return 'BMI Trend';
      case 'Workouts':
        return 'Workout Trend';
      case 'Steps / Activity':
        return 'Steps / Activity Trend';
      default:
        return 'Weight Trend';
    }
  }

  String get _latestValue {
    switch (_selectedTrend) {
      case 'BMI':
        return '22.4';
      case 'Workouts':
        return _selectedRange == 'Weekly'
            ? '4 workouts'
            : _selectedRange == 'Monthly'
                ? '16 workouts'
                : '146 workouts';
      case 'Steps / Activity':
        return _selectedRange == 'Weekly'
            ? '8,245'
            : _selectedRange == 'Monthly'
                ? '241,300'
                : '2.7M';
      default:
        return '72.4 kg';
    }
  }

  String get _changeValue {
    switch (_selectedTrend) {
      case 'BMI':
        return '↓ 0.4';
      case 'Workouts':
        return '↑ 1 workout';
      case 'Steps / Activity':
        return '↑ 12.5%';
      default:
        return '↓ 1.2 kg';
    }
  }

  String get _insight {
    switch (_selectedTrend) {
      case 'BMI':
        return 'Your BMI has improved steadily this week.';
      case 'Workouts':
        return 'You completed 4 workouts this week. Keep it up!';
      case 'Steps / Activity':
        return 'You are getting closer to your activity goal.';
      default:
        return 'Your weight has decreased steadily this week.';
    }
  }

  List<double> get _chartValues {
    if (_selectedTrend == 'BMI') {
      return [23.2, 23.0, 22.9, 22.8, 22.6, 22.5, 22.4];
    }

    if (_selectedTrend == 'Workouts') {
      return _selectedRange == 'Weekly'
          ? [0, 1, 1, 2, 2, 3, 4]
          : _selectedRange == 'Monthly'
              ? [2, 4, 7, 9, 11, 13, 16]
              : [10, 24, 40, 56, 71, 95, 146];
    }

    if (_selectedTrend == 'Steps / Activity') {
      return [5200, 6300, 7100, 6800, 7800, 8200, 8245];
    }

    return [74.5, 73.9, 73.5, 73.1, 72.8, 72.5, 72.4];
  }

  List<String> get _chartLabels {
    switch (_selectedRange) {
      case 'Monthly':
        return ['May 1', 'May 5', 'May 10', 'May 15', 'May 20', 'May 25', 'May 29'];
      case 'Yearly':
        return ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov', 'Dec'];
      default:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
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
                      color: darkText,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'View Trends',
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
                    _sectionCard(
                      title: 'Trend Type',
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _trendTypes.map((trend) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _trendChip(
                                label: trend,
                                icon: _trendIcon(trend),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _sectionCard(
                      title: 'Time Range',
                      child: Row(
                        children: _timeRanges.map((range) {
                          final isSelected = _selectedRange == range;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRange = range;
                                });
                              },
                              child: Container(
                                height: 54,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryBlue
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryBlue
                                        : const Color(0xFFD4DDEA),
                                  ),
                                ),
                                child: Text(
                                  range,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : darkText,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    _trendContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendContent() {
    if (_usesFirestoreTrend) {
      return StreamBuilder<List<WeightEntry>>(
        stream: WeightFirestoreService.instance.getWeightEntriesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _statusTrendContent(
              message: 'Could not load trend data.',
            );
          }

          if (!snapshot.hasData) {
            return _statusTrendContent(
              message: 'Loading trend data...',
              isLoading: true,
            );
          }

          return _firestoreTrendContent(snapshot.data!);
        },
      );
    }

    if (_selectedTrend == 'Workouts' ||
        _selectedTrend == 'Steps / Activity') {
      return StreamBuilder<List<WorkoutEntry>>(
        stream: WorkoutFirestoreService.instance.getWorkoutEntriesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _statusTrendContent(
              message: _selectedTrend == 'Workouts'
                  ? 'Could not load workout trend data.'
                  : 'Could not load activity trend data.',
            );
          }

          if (!snapshot.hasData) {
            return _statusTrendContent(
              message: _selectedTrend == 'Workouts'
                  ? 'Loading workout trend data...'
                  : 'Loading activity trend data...',
              isLoading: true,
            );
          }

          if (_selectedTrend == 'Workouts') {
            return _workoutTrendContent(snapshot.data!);
          }

          return _activityTrendContent(snapshot.data!);
        },
      );
    }

    return _demoTrendContent();
  }

  Widget _firestoreTrendContent(List<WeightEntry> allEntries) {
    final rangeEntries = _entriesForSelectedRange(allEntries);

    if (rangeEntries.isEmpty) {
      return _statusTrendContent(
        message: 'No ${_selectedTrend.toLowerCase()} entries in this period.',
      );
    }

    final isBmiTrend = _selectedTrend == 'BMI';

    final valuesForMetrics = rangeEntries
        .map((entry) => isBmiTrend ? entry.bmi : entry.weightKg)
        .toList();

    final chartEntries = rangeEntries.length > 7
        ? rangeEntries.sublist(rangeEntries.length - 7)
        : rangeEntries;

    final chartValues = chartEntries
        .map((entry) => isBmiTrend ? entry.bmi : entry.weightKg)
        .toList();

    final chartLabels = chartEntries
        .map((entry) => _formatTrendDate(entry.recordedAt))
        .toList();

    final average =
        valuesForMetrics.reduce((total, value) => total + value) /
            valuesForMetrics.length;

    final latest = valuesForMetrics.last;

    final change =
        valuesForMetrics.length >= 2 ? latest - valuesForMetrics.first : null;

    String changeValue;
    String badgeText;
    Color changeColor;
    Color badgeBackgroundColor;
    IconData changeIcon;

    if (change == null) {
      changeValue = '—';
      badgeText = 'Latest entry';
      changeColor = primaryBlue;
      badgeBackgroundColor = const Color(0xFFEAF3FF);
      changeIcon = Icons.remove_rounded;
    } else if (change < 0) {
      changeValue = isBmiTrend
          ? '↓ ${change.abs().toStringAsFixed(1)}'
          : '↓ ${change.abs().toStringAsFixed(1)} kg';

      badgeText = changeValue;
      changeColor = successGreen;
      badgeBackgroundColor = const Color(0xFFE8F7EC);
      changeIcon = Icons.trending_down_rounded;
    } else if (change > 0) {
      changeValue = isBmiTrend
          ? '↑ ${change.toStringAsFixed(1)}'
          : '↑ ${change.toStringAsFixed(1)} kg';

      badgeText = changeValue;
      changeColor = Colors.orange;
      badgeBackgroundColor = const Color(0xFFFFF4E5);
      changeIcon = Icons.trending_up_rounded;
    } else {
      changeValue = 'No change';
      badgeText = 'No change';
      changeColor = primaryBlue;
      badgeBackgroundColor = const Color(0xFFEAF3FF);
      changeIcon = Icons.remove_rounded;
    }

    final averageValue = isBmiTrend
        ? average.toStringAsFixed(1)
        : '${average.toStringAsFixed(1)} kg';

    final latestValue = isBmiTrend
        ? latest.toStringAsFixed(1)
        : '${latest.toStringAsFixed(1)} kg';

    String insight;

    if (change == null) {
      insight =
          'You have one saved entry this $_periodLabel. Add another entry to compare your progress.';
    } else if (isBmiTrend) {
      insight = change < 0
          ? 'Your BMI is lower by ${change.abs().toStringAsFixed(1)} this $_periodLabel.'
          : change > 0
              ? 'Your BMI is higher by ${change.toStringAsFixed(1)} this $_periodLabel.'
              : 'Your BMI has not changed this $_periodLabel.';
    } else {
      insight = change < 0
          ? 'Your weight is down ${change.abs().toStringAsFixed(1)} kg this $_periodLabel.'
          : change > 0
              ? 'Your weight is up ${change.toStringAsFixed(1)} kg this $_periodLabel.'
              : 'Your weight has not changed this $_periodLabel.';
    }

    return Column(
      children: [
        _trendCard(
          values: chartValues,
          labels: chartLabels,
          averageValue: averageValue,
          latestValue: latestValue,
          changeValue: changeValue,
          changeColor: changeColor,
          changeIcon: changeIcon,
          badgeText: badgeText,
          badgeTextColor: changeColor,
          badgeBackgroundColor: badgeBackgroundColor,
        ),
        const SizedBox(height: 14),
        _insightCard(insight),
      ],
    );
  }

  Widget _workoutTrendContent(List<WorkoutEntry> allWorkouts) {
    final rangeWorkouts = _workoutsForSelectedRange(allWorkouts);

    if (rangeWorkouts.isEmpty) {
      return _statusTrendContent(
        message: 'No workouts saved in this period.',
      );
    }

    final points = _buildWorkoutTrendPoints(rangeWorkouts);

    final bucketCounts = points.map((point) => point.value).toList();
    final labels = points.map((point) => point.label).toList();

    final chartValues = <double>[];
    var cumulativeTotal = 0.0;

    for (final count in bucketCounts) {
      cumulativeTotal += count;
      chartValues.add(cumulativeTotal);
    }

    final average =
        bucketCounts.reduce((total, value) => total + value) /
            bucketCounts.length;

    final totalWorkouts = rangeWorkouts.length;
    final firstPeriodTotal = chartValues.first.toInt();
    final change = totalWorkouts - firstPeriodTotal;

    String changeValue;
    Color changeColor;
    IconData changeIcon;

    if (totalWorkouts == 1) {
      changeValue = 'First workout';
      changeColor = primaryBlue;
      changeIcon = Icons.remove_rounded;
    } else if (change > 0) {
      changeValue = '↑ ${_workoutCountLabel(change)}';
      changeColor = successGreen;
      changeIcon = Icons.trending_up_rounded;
    } else {
      changeValue = 'No change';
      changeColor = primaryBlue;
      changeIcon = Icons.remove_rounded;
    }

    final insight = totalWorkouts == 1
        ? 'You completed your first workout this $_periodLabel. Keep building the habit.'
        : 'You completed ${_workoutCountLabel(totalWorkouts)} this $_periodLabel. Keep it up!';

    return Column(
      children: [
        _trendCard(
          values: chartValues,
          labels: labels,
          averageValue: '${average.toStringAsFixed(1)} workouts',
          latestValue: _workoutCountLabel(totalWorkouts),
          changeValue: changeValue,
          changeColor: changeColor,
          changeIcon: changeIcon,
          badgeText: _workoutCountLabel(totalWorkouts),
          badgeTextColor: primaryBlue,
          badgeBackgroundColor: const Color(0xFFEAF3FF),
        ),
        const SizedBox(height: 14),
        _insightCard(insight),
      ],
    );
  }

  Widget _activityTrendContent(List<WorkoutEntry> allWorkouts) {
    final stepEntries = _stepEntriesForSelectedRange(allWorkouts);

    if (stepEntries.isEmpty) {
      return _statusTrendContent(
        message: 'No cardio step data saved in this period.',
      );
    }

    final points = _buildActivityTrendPoints(stepEntries);

    final chartValues = points.map((point) => point.value).toList();
    final chartLabels = points.map((point) => point.label).toList();

    final totalSteps = stepEntries.fold<double>(
      0,
      (total, entry) => total + entry.steps,
    );

    final averageSteps = totalSteps / stepEntries.length;
    final latestEntry = stepEntries.last;
    final previousEntry =
        stepEntries.length >= 2 ? stepEntries[stepEntries.length - 2] : null;

    final change = previousEntry == null
        ? null
        : latestEntry.steps - previousEntry.steps;

    String changeValue;
    Color changeColor;
    IconData changeIcon;

    if (change == null) {
      changeValue = 'First activity';
      changeColor = primaryBlue;
      changeIcon = Icons.remove_rounded;
    } else if (change > 0) {
      changeValue = '↑ ${_formatStepCount(change)} steps';
      changeColor = successGreen;
      changeIcon = Icons.trending_up_rounded;
    } else if (change < 0) {
      changeValue = '↓ ${_formatStepCount(change.abs())} steps';
      changeColor = Colors.orange;
      changeIcon = Icons.trending_down_rounded;
    } else {
      changeValue = 'No change';
      changeColor = primaryBlue;
      changeIcon = Icons.remove_rounded;
    }

    final insight = stepEntries.length == 1
        ? 'You logged ${_formatStepCount(totalSteps)} steps in your latest cardio activity this $_periodLabel.'
        : 'You logged ${_formatStepCount(totalSteps)} steps across ${stepEntries.length} cardio activities this $_periodLabel.';

    return Column(
      children: [
        _trendCard(
          values: chartValues,
          labels: chartLabels,
          averageValue: '${_formatStepCount(averageSteps)} steps',
          latestValue: '${_formatStepCount(latestEntry.steps)} steps',
          changeValue: changeValue,
          changeColor: changeColor,
          changeIcon: changeIcon,
          badgeText: '${_formatStepCount(totalSteps)} steps',
          badgeTextColor: primaryBlue,
          badgeBackgroundColor: const Color(0xFFEAF3FF),
        ),
        const SizedBox(height: 14),
        _insightCard(insight),
      ],
    );
  }

  Widget _demoTrendContent() {
    final values = _chartValues;

    final average =
        values.reduce((total, value) => total + value) / values.length;

    String averageValue;

    if (_selectedTrend == 'BMI') {
      averageValue = average.toStringAsFixed(1);
    } else if (_selectedTrend == 'Weight') {
      averageValue = '${average.toStringAsFixed(1)} kg';
    } else if (_selectedTrend == 'Workouts') {
      averageValue = '${average.toStringAsFixed(0)} workouts';
    } else {
      averageValue = average.toStringAsFixed(0);
    }

    final isIncrease = _changeValue.startsWith('↑');

    return Column(
      children: [
        _trendCard(
          values: _chartValues,
          labels: _chartLabels,
          averageValue: averageValue,
          latestValue: _latestValue,
          changeValue: _changeValue,
          changeColor: successGreen,
          changeIcon: isIncrease
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          badgeText: _changeValue,
          badgeTextColor: successGreen,
          badgeBackgroundColor: const Color(0xFFE7F6EB),
        ),
        const SizedBox(height: 14),
        _insightCard(_insight),
      ],
    );
  }

  Widget _statusTrendContent({
    required String message,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _chartTitle,
            style: const TextStyle(
              color: darkText,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: greyText,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCard({
    required List<double> values,
    required List<String> labels,
    required String averageValue,
    required String latestValue,
    required String changeValue,
    required Color changeColor,
    required IconData changeIcon,
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBackgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _chartTitle,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: badgeBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: TrendChart(
              values: values,
              labels: labels,
              trendType: _selectedTrend,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _compactMetric(
                  icon: Icons.show_chart_rounded,
                  label: 'Average',
                  value: averageValue,
                ),
              ),
              Container(
                width: 1,
                height: 74,
                color: const Color(0xFFE1E7F0),
              ),
              Expanded(
                child: _compactMetric(
                  icon: _trendIcon(_selectedTrend),
                  label: 'Latest',
                  value: latestValue,
                ),
              ),
              Container(
                width: 1,
                height: 74,
                color: const Color(0xFFE1E7F0),
              ),
              Expanded(
                child: _compactMetric(
                  icon: changeIcon,
                  label: 'Change',
                  value: changeValue,
                  valueColor: changeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactMetric({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = darkText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: primaryBlue,
            size: 27,
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: greyText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(String insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: primaryBlue,
              size: 31,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nice progress!',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 17,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _trendChip({
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTrend == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTrend = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFB8CAE9),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : darkText,
              size: 23,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : darkText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
}

class _StepEntry {
  final DateTime recordedAt;
  final double steps;

  const _StepEntry({
    required this.recordedAt,
    required this.steps,
  });
}

class _ActivityTrendPoint {
  final String label;
  final double value;

  const _ActivityTrendPoint({
    required this.label,
    required this.value,
  });
}

class _WorkoutTrendPoint {
  final String label;
  final double value;

  const _WorkoutTrendPoint({
    required this.label,
    required this.value,
  });
}

class TrendChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String trendType;

  const TrendChart({
    super.key,
    required this.values,
    required this.labels,
    required this.trendType,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendChartPainter(
        values: values,
        labels: labels,
        trendType: trendType,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final String trendType;

  _TrendChartPainter({
    required this.values,
    required this.labels,
    required this.trendType,
  });

  static const Color primaryBlue = Color(0xFF1555C0);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFDCE6F4)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = primaryBlue
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0x331555C0)
      ..style = PaintingStyle.fill;

    final pointFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = primaryBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const left = 42.0;
    const top = 16.0;
    const bottomPadding = 42.0;

    final right = size.width - 12;
    final bottom = size.height - bottomPadding;
    final chartWidth = right - left;
    final chartHeight = bottom - top;

    for (int i = 0; i < 5; i++) {
      final y = top + (chartHeight / 4) * i;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    canvas.drawLine(Offset(left, top), Offset(left, bottom), gridPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), gridPaint);

    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);

    final safeRange = maximum == minimum ? 1.0 : maximum - minimum;

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final horizontalPosition =
          values.length == 1 ? 0.5 : i / (values.length - 1);

      final x = left + (chartWidth * horizontalPosition);
      final normalizedValue = (values[i] - minimum) / safeRange;
      final y = bottom - (normalizedValue * chartHeight * 0.78) - 20;

      points.add(Offset(x, y));
    }

    final fillPath = Path()
      ..moveTo(points.first.dx, bottom)
      ..lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath
      ..lineTo(points.last.dx, bottom)
      ..close();

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(linePath, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 6, pointFillPaint);
      canvas.drawCircle(point, 6, pointBorderPaint);
    }

    for (int i = 0; i < labels.length; i++) {
      _drawCenteredLabel(
        canvas,
        labels[i],
        points[i].dx,
        bottom + 12,
      );
    }

    _drawYAxisLabels(
      canvas,
      left,
      top,
      bottom,
      minimum,
      maximum,
    );
  }

  void _drawYAxisLabels(
    Canvas canvas,
    double left,
    double top,
    double bottom,
    double minimum,
    double maximum,
  ) {
    for (int i = 0; i < 5; i++) {
      final ratio = i / 4;
      final value = maximum - ((maximum - minimum) * ratio);

      String label;

      if (trendType == 'Weight') {
        label = '${value.toStringAsFixed(0)} kg';
      } else if (trendType == 'BMI') {
        label = value.toStringAsFixed(1);
      } else if (trendType == 'Steps / Activity') {
        if (value < 1000) {
          label = value.toStringAsFixed(0);
        } else {
          final thousands = value / 1000;

          label = thousands % 1 == 0
              ? '${thousands.toInt()}k'
              : '${thousands.toStringAsFixed(1)}k';
        }
      } else {
        label = value.toStringAsFixed(0);
      }

      final y = top + ((bottom - top) * ratio);

      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF526176),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(left - painter.width - 8, y - (painter.height / 2)),
      );
    }
  }

  void _drawCenteredLabel(
    Canvas canvas,
    String text,
    double centerX,
    double y,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF0B1B4D),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(centerX - (painter.width / 2), y),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.trendType != trendType;
  }
}