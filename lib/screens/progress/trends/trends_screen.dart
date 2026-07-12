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
  DateTime _focusedDate = DateTime.now();

  final List<String> _trendTypes = [
    'Weight',
    'BMI',
    'Steps / Activity',
    'Workouts',
  ];

  final List<String> _timeRanges = [
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();

    _selectedTrend = _trendTypes.contains(widget.initialTrendType)
        ? widget.initialTrendType
        : 'Weight';

    _selectedRange = _timeRanges.contains(widget.initialTimeRange)
        ? widget.initialTimeRange
        : 'Weekly';

    _focusedDate = DateTime.now();
  }

  bool get _usesWeightEntries {
    return _selectedTrend == 'Weight' || _selectedTrend == 'BMI';
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _startOfWeek(DateTime date) {
    final onlyDate = _dateOnly(date);
    return onlyDate.subtract(Duration(days: onlyDate.weekday - 1));
  }

  DateTime _periodStart() {
    final date = _dateOnly(_focusedDate);

    if (_selectedRange == 'Weekly') {
      return _startOfWeek(date);
    }

    if (_selectedRange == 'Monthly') {
      return DateTime(date.year, date.month, 1);
    }

    return DateTime(date.year, 1, 1);
  }

  DateTime _periodEnd() {
    final start = _periodStart();

    if (_selectedRange == 'Weekly') {
      return start.add(const Duration(days: 6));
    }

    if (_selectedRange == 'Monthly') {
      return DateTime(start.year, start.month + 1, 0);
    }

    return DateTime(start.year, 12, 31);
  }

  DateTime _periodStartFor(DateTime date) {
    final onlyDate = _dateOnly(date);

    if (_selectedRange == 'Weekly') {
      return _startOfWeek(onlyDate);
    }

    if (_selectedRange == 'Monthly') {
      return DateTime(onlyDate.year, onlyDate.month, 1);
    }

    return DateTime(onlyDate.year, 1, 1);
  }

  bool get _canGoNext {
    final currentStart = _periodStartFor(DateTime.now());
    return _periodStart().isBefore(currentStart);
  }

  void _movePeriodBack() {
    setState(() {
      if (_selectedRange == 'Weekly') {
        _focusedDate = _focusedDate.subtract(const Duration(days: 7));
      } else if (_selectedRange == 'Monthly') {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
      } else {
        _focusedDate = DateTime(_focusedDate.year - 1, 1, 1);
      }
    });
  }

  void _movePeriodForward() {
    if (!_canGoNext) {
      return;
    }

    setState(() {
      if (_selectedRange == 'Weekly') {
        _focusedDate = _focusedDate.add(const Duration(days: 7));
      } else if (_selectedRange == 'Monthly') {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
      } else {
        _focusedDate = DateTime(_focusedDate.year + 1, 1, 1);
      }

      final currentPeriodStart = _periodStartFor(DateTime.now());

      if (_periodStart().isAfter(currentPeriodStart)) {
        _focusedDate = DateTime.now();
      }
    });
  }

  List<_TrendSlot> _periodSlots() {
    final start = _periodStart();
    final end = _periodEnd();

    if (_selectedRange == 'Weekly') {
      return List.generate(7, (index) {
        final date = start.add(Duration(days: index));

        return _TrendSlot(
          start: date,
          end: date,
          label: _shortWeekday(date),
        );
      });
    }

    if (_selectedRange == 'Monthly') {
      final dayCount = end.difference(start).inDays + 1;

      return List.generate(dayCount, (index) {
        final date = start.add(Duration(days: index));

        return _TrendSlot(
          start: date,
          end: date,
          label: date.day.toString(),
        );
      });
    }

    return List.generate(12, (index) {
      final monthStart = DateTime(start.year, index + 1, 1);
      final monthEnd = DateTime(start.year, index + 2, 0);

      return _TrendSlot(
        start: monthStart,
        end: monthEnd,
        label: _shortMonth(monthStart),
      );
    });
  }

  List<WeightEntry> _weightEntriesForPeriod(List<WeightEntry> entries) {
    final start = _periodStart();
    final end = _periodEnd();

    return entries.where((entry) {
      final entryDate = _dateOnly(entry.recordedAt);

      return !entryDate.isBefore(start) && !entryDate.isAfter(end);
    }).toList()
      ..sort((first, second) => first.recordedAt.compareTo(second.recordedAt));
  }

  List<WorkoutEntry> _workoutsForPeriod(List<WorkoutEntry> workouts) {
    final start = _periodStart();
    final end = _periodEnd();

    return workouts.where((workout) {
      final workoutDate = _dateOnly(workout.recordedAt);

      return !workoutDate.isBefore(start) && !workoutDate.isAfter(end);
    }).toList()
      ..sort((first, second) => first.recordedAt.compareTo(second.recordedAt));
  }

  List<WorkoutEntry> _workoutsForCustomPeriod({
    required List<WorkoutEntry> workouts,
    required DateTime start,
    required DateTime end,
  }) {
    return workouts.where((workout) {
      final workoutDate = _dateOnly(workout.recordedAt);

      return !workoutDate.isBefore(start) && !workoutDate.isAfter(end);
    }).toList();
  }

  DateTime _previousPeriodStart() {
    final start = _periodStart();

    if (_selectedRange == 'Weekly') {
      return start.subtract(const Duration(days: 7));
    }

    if (_selectedRange == 'Monthly') {
      return DateTime(start.year, start.month - 1, 1);
    }

    return DateTime(start.year - 1, 1, 1);
  }

  DateTime _previousPeriodEnd() {
    final previousStart = _previousPeriodStart();

    if (_selectedRange == 'Weekly') {
      return previousStart.add(const Duration(days: 6));
    }

    if (_selectedRange == 'Monthly') {
      return DateTime(previousStart.year, previousStart.month + 1, 0);
    }

    return DateTime(previousStart.year, 12, 31);
  }

  num? _numberValue(dynamic value) {
    if (value is num) {
      return value;
    }

    return double.tryParse(value?.toString() ?? '');
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

  String _shortWeekday(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  String _shortMonth(DateTime date) {
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

    return months[date.month - 1];
  }

  String _fullMonth(DateTime date) {
    const months = [
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

    return months[date.month - 1];
  }

  String _formatPeriodDate(DateTime date) {
    return '${date.day} ${_shortMonth(date)}';
  }

  String get _periodDisplayTitle {
    final start = _periodStart();
    final end = _periodEnd();

    if (_selectedRange == 'Weekly') {
      if (start.year == end.year) {
        return '${_formatPeriodDate(start)} – ${_formatPeriodDate(end)} ${end.year}';
      }

      return '${_formatPeriodDate(start)} ${start.year} – ${_formatPeriodDate(end)} ${end.year}';
    }

    if (_selectedRange == 'Monthly') {
      return '${_fullMonth(start)} ${start.year}';
    }

    return start.year.toString();
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
      case 'Steps / Activity':
        return Icons.directions_walk_outlined;
      case 'Workouts':
        return Icons.fitness_center_outlined;
      default:
        return Icons.scale_outlined;
    }
  }

  String get _chartTitle {
    switch (_selectedTrend) {
      case 'BMI':
        return 'BMI Trend';
      case 'Steps / Activity':
        return 'Steps Trend';
      case 'Workouts':
        return 'Workout Trend';
      default:
        return 'Weight Trend';
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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: darkText,
                      size: 29,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'View Trends',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkText,
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
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
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
                              padding: const EdgeInsets.only(right: 7),
                              child: _trendChip(
                                label: trend,
                                icon: _trendIcon(trend),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _sectionCard(
                      title: 'Time Range',
                      child: Row(
                        children: _timeRanges.map((range) {
                          final isSelected = _selectedRange == range;

                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: range == _timeRanges.last ? 0 : 7,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13),
                                onTap: () {
                                  setState(() {
                                    _selectedRange = range;
                                    _focusedDate = DateTime.now();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryBlue
                                        : const Color(0xFFF9FBFE),
                                    borderRadius: BorderRadius.circular(13),
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
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

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
    if (_usesWeightEntries) {
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

          return _weightOrBmiTrendContent(snapshot.data!);
        },
      );
    }

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

  Widget _weightOrBmiTrendContent(List<WeightEntry> allEntries) {
    final periodEntries = _weightEntriesForPeriod(allEntries);
    final isBmiTrend = _selectedTrend == 'BMI';
    final slots = _periodSlots();
    final values = List<double?>.filled(slots.length, null);

    for (int index = 0; index < slots.length; index++) {
      final slot = slots[index];

      final slotEntries = periodEntries.where((entry) {
        final entryDate = _dateOnly(entry.recordedAt);

        return !entryDate.isBefore(slot.start) && !entryDate.isAfter(slot.end);
      }).toList();

      if (slotEntries.isEmpty) {
        continue;
      }

      slotEntries.sort(
        (first, second) => first.recordedAt.compareTo(second.recordedAt),
      );

      final latestEntry = slotEntries.last;
      values[index] = isBmiTrend ? latestEntry.bmi : latestEntry.weightKg;
    }

    if (periodEntries.isEmpty) {
      return _trendCard(
        values: values,
        labels: slots.map((slot) => slot.label).toList(),
        averageValue: '—',
        latestValue: '—',
        changeValue: '—',
        changeColor: primaryBlue,
        changeIcon: Icons.remove_rounded,
        badgeText: 'No data',
        badgeTextColor: primaryBlue,
        badgeBackgroundColor: const Color(0xFFEAF3FF),
        insight: 'No ${_selectedTrend.toLowerCase()} entries saved this $_periodLabel.',
      );
    }

    final metricValues = periodEntries
        .map((entry) => isBmiTrend ? entry.bmi : entry.weightKg)
        .toList();

    final average = metricValues.reduce((total, value) => total + value) /
        metricValues.length;

    final latest = metricValues.last;
    final change = metricValues.length >= 2 ? latest - metricValues.first : null;

    final averageValue = isBmiTrend
        ? average.toStringAsFixed(1)
        : '${average.toStringAsFixed(1)} kg';

    final latestValue = isBmiTrend
        ? latest.toStringAsFixed(1)
        : '${latest.toStringAsFixed(1)} kg';

    final changeInfo = _changeInfo(
      change: change,
      suffix: isBmiTrend ? '' : ' kg',
      downIsGood: true,
      firstText: 'Latest entry',
    );

    return _trendCard(
      values: values,
      labels: slots.map((slot) => slot.label).toList(),
      averageValue: averageValue,
      latestValue: latestValue,
      changeValue: changeInfo.text,
      changeColor: changeInfo.color,
      changeIcon: changeInfo.icon,
      badgeText: changeInfo.badge,
      badgeTextColor: changeInfo.color,
      badgeBackgroundColor: changeInfo.backgroundColor,
      insight: _weightInsight(
        change: change,
        isBmiTrend: isBmiTrend,
      ),
    );
  }

  Widget _workoutTrendContent(List<WorkoutEntry> allWorkouts) {
    final periodWorkouts = _workoutsForPeriod(allWorkouts);

    final previousWorkouts = _workoutsForCustomPeriod(
      workouts: allWorkouts,
      start: _previousPeriodStart(),
      end: _previousPeriodEnd(),
    );

    final today = _dateOnly(DateTime.now());
    final slots = _periodSlots();

    final values = slots.map<double?>((slot) {
      if (slot.start.isAfter(today)) {
        return null;
      }

      final count = periodWorkouts.where((workout) {
        final workoutDate = _dateOnly(workout.recordedAt);

        return !workoutDate.isBefore(slot.start) &&
            !workoutDate.isAfter(slot.end);
      }).length;

      return count.toDouble();
    }).toList();

    final totalWorkouts = periodWorkouts.length;
    final previousTotal = previousWorkouts.length;
    final completedSlots = values.whereType<double>().toList();

    final average = completedSlots.isEmpty
        ? 0.0
        : completedSlots.reduce((total, value) => total + value) /
            completedSlots.length;

    final change = totalWorkouts - previousTotal;

    final changeInfo = _countChangeInfo(
      change: change,
      unit: change.abs() == 1 ? 'workout' : 'workouts',
    );

    final insight = totalWorkouts == 0
        ? 'No workouts saved this $_periodLabel yet.'
        : 'You completed ${_workoutCountLabel(totalWorkouts)} this $_periodLabel. Keep it up!';

    return _trendCard(
      values: values,
      labels: slots.map((slot) => slot.label).toList(),
      averageValue: '${average.toStringAsFixed(1)} workouts',
      latestValue: _workoutCountLabel(totalWorkouts),
      changeValue: changeInfo.text,
      changeColor: changeInfo.color,
      changeIcon: changeInfo.icon,
      badgeText: _workoutCountLabel(totalWorkouts),
      badgeTextColor: primaryBlue,
      badgeBackgroundColor: const Color(0xFFEAF3FF),
      insight: insight,
    );
  }

  Widget _activityTrendContent(List<WorkoutEntry> allWorkouts) {
    final periodWorkouts = _workoutsForPeriod(allWorkouts);

    final previousWorkouts = _workoutsForCustomPeriod(
      workouts: allWorkouts,
      start: _previousPeriodStart(),
      end: _previousPeriodEnd(),
    );

    final today = _dateOnly(DateTime.now());
    final slots = _periodSlots();

    double stepsForWorkouts(List<WorkoutEntry> workouts) {
      var total = 0.0;

      for (final workout in workouts) {
        if (workout.workoutType != 'Cardio') {
          continue;
        }

        for (final exercise in workout.exercises) {
          final steps = _numberValue(exercise['steps']);

          if (steps != null && steps > 0) {
            total += steps.toDouble();
          }
        }
      }

      return total;
    }

    final values = slots.map<double?>((slot) {
      if (slot.start.isAfter(today)) {
        return null;
      }

      final slotWorkouts = periodWorkouts.where((workout) {
        final workoutDate = _dateOnly(workout.recordedAt);

        return !workoutDate.isBefore(slot.start) &&
            !workoutDate.isAfter(slot.end);
      }).toList();

      return stepsForWorkouts(slotWorkouts);
    }).toList();

    final totalSteps = stepsForWorkouts(periodWorkouts);
    final previousSteps = stepsForWorkouts(previousWorkouts);
    final completedSlots = values.whereType<double>().toList();

    final averageSteps = completedSlots.isEmpty
        ? 0.0
        : completedSlots.reduce((total, value) => total + value) /
            completedSlots.length;

    final latestSteps = completedSlots.isEmpty ? 0.0 : completedSlots.last;
    final change = totalSteps - previousSteps;

    final changeInfo = _countChangeInfo(
      change: change.round(),
      unit: 'steps',
      formatter: (value) => _formatStepCount(value.toDouble()),
    );

    final insight = totalSteps <= 0
        ? 'No step activity saved this $_periodLabel yet.'
        : 'You logged ${_formatStepCount(totalSteps)} steps this $_periodLabel.';

    return _trendCard(
      values: values,
      labels: slots.map((slot) => slot.label).toList(),
      averageValue: '${_formatStepCount(averageSteps)} steps',
      latestValue: '${_formatStepCount(latestSteps)} steps',
      changeValue: changeInfo.text,
      changeColor: changeInfo.color,
      changeIcon: changeInfo.icon,
      badgeText: '${_formatStepCount(totalSteps)} steps',
      badgeTextColor: primaryBlue,
      badgeBackgroundColor: const Color(0xFFEAF3FF),
      insight: insight,
    );
  }

  String _workoutCountLabel(int count) {
    return '$count ${count == 1 ? 'workout' : 'workouts'}';
  }

  _ChangeInfo _changeInfo({
    required double? change,
    required String suffix,
    required bool downIsGood,
    required String firstText,
  }) {
    if (change == null) {
      return _ChangeInfo(
        text: '—',
        badge: firstText,
        color: primaryBlue,
        backgroundColor: const Color(0xFFEAF3FF),
        icon: Icons.remove_rounded,
      );
    }

    if (change == 0) {
      return const _ChangeInfo(
        text: 'No change',
        badge: 'No change',
        color: primaryBlue,
        backgroundColor: Color(0xFFEAF3FF),
        icon: Icons.remove_rounded,
      );
    }

    final isDown = change < 0;
    final isGood = downIsGood ? isDown : !isDown;
    final arrow = isDown ? '↓' : '↑';
    final amount = change.abs().toStringAsFixed(1);
    final color = isGood ? successGreen : Colors.orange;
    final background = isGood
        ? const Color(0xFFE8F7EC)
        : const Color(0xFFFFF4E5);

    return _ChangeInfo(
      text: '$arrow $amount$suffix',
      badge: '$arrow $amount$suffix',
      color: color,
      backgroundColor: background,
      icon: isDown ? Icons.trending_down_rounded : Icons.trending_up_rounded,
    );
  }

  _ChangeInfo _countChangeInfo({
    required int change,
    required String unit,
    String Function(int value)? formatter,
  }) {
    if (change == 0) {
      return const _ChangeInfo(
        text: 'No change',
        badge: 'No change',
        color: primaryBlue,
        backgroundColor: Color(0xFFEAF3FF),
        icon: Icons.remove_rounded,
      );
    }

    final isUp = change > 0;
    final amount = formatter == null
        ? change.abs().toString()
        : formatter(change.abs());

    return _ChangeInfo(
      text: '${isUp ? '↑' : '↓'} $amount $unit',
      badge: '${isUp ? '↑' : '↓'} $amount $unit',
      color: isUp ? successGreen : Colors.orange,
      backgroundColor:
          isUp ? const Color(0xFFE8F7EC) : const Color(0xFFFFF4E5),
      icon: isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
    );
  }

  String _weightInsight({
    required double? change,
    required bool isBmiTrend,
  }) {
    if (change == null) {
      return 'You have one saved entry this $_periodLabel. Add another entry to compare your progress.';
    }

    if (change == 0) {
      return isBmiTrend
          ? 'Your BMI has not changed this $_periodLabel.'
          : 'Your weight has not changed this $_periodLabel.';
    }

    if (isBmiTrend) {
      return change < 0
          ? 'Your BMI is lower by ${change.abs().toStringAsFixed(1)} this $_periodLabel.'
          : 'Your BMI is higher by ${change.toStringAsFixed(1)} this $_periodLabel.';
    }

    return change < 0
        ? 'Your weight is down ${change.abs().toStringAsFixed(1)} kg this $_periodLabel.'
        : 'Your weight is up ${change.toStringAsFixed(1)} kg this $_periodLabel.';
  }

  Widget _statusTrendContent({
    required String message,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _trendCardHeader(
            badgeText: 'No data',
            badgeTextColor: primaryBlue,
            badgeBackgroundColor: const Color(0xFFEAF3FF),
          ),
          const SizedBox(height: 12),
          _periodNavigator(),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: greyText,
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCard({
    required List<double?> values,
    required List<String> labels,
    required String averageValue,
    required String latestValue,
    required String changeValue,
    required Color changeColor,
    required IconData changeIcon,
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBackgroundColor,
    required String insight,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _trendCardHeader(
                badgeText: badgeText,
                badgeTextColor: badgeTextColor,
                badgeBackgroundColor: badgeBackgroundColor,
              ),
              const SizedBox(height: 12),
              _periodNavigator(),
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
                child: TrendChart(
                  values: values,
                  labels: labels,
                  trendType: _selectedTrend,
                ),
              ),
              const SizedBox(height: 13),
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
                    height: 56,
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
                    height: 56,
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
        ),
        const SizedBox(height: 12),
        _insightCard(insight),
      ],
    );
  }

  Widget _trendCardHeader({
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBackgroundColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _chartTitle,
            style: const TextStyle(
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: badgeBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              color: badgeTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _periodNavigator() {
    return Row(
      children: [
        _periodArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: _movePeriodBack,
          isEnabled: true,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                _periodDisplayTitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _selectedRange,
                style: const TextStyle(
                  color: greyText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _periodArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: _movePeriodForward,
          isEnabled: _canGoNext,
        ),
      ],
    );
  }

  Widget _periodArrowButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isEnabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          color: isEnabled ? greyText : const Color(0xFFD0D5DD),
          size: 32,
        ),
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
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: greyText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(String insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: primaryBlue,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nice progress!',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  insight,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 13.5,
                    height: 1.35,
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

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
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

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () {
        setState(() {
          _selectedTrend = label;
          _focusedDate = DateTime.now();
        });
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : const Color(0xFFF9FBFE),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFD4DDEA),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : darkText,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : darkText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
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
}

class _TrendSlot {
  final DateTime start;
  final DateTime end;
  final String label;

  const _TrendSlot({
    required this.start,
    required this.end,
    required this.label,
  });
}

class _ChangeInfo {
  final String text;
  final String badge;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  const _ChangeInfo({
    required this.text,
    required this.badge,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });
}

class TrendChart extends StatelessWidget {
  final List<double?> values;
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
  final List<double?> values;
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
    if (values.isEmpty) {
      return;
    }

    final chartLeft = 2.0;
    final chartRight = size.width - 38;
    const chartTop = 8.0;
    final chartBottom = size.height - 30;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final axisPaint = Paint()
      ..color = const Color(0xFFE1E7F0)
      ..strokeWidth = 1.2;

    final tickPaint = Paint()
      ..color = const Color(0xFFE1E7F0)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final axisValues = _axisValues();

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
          style: const TextStyle(
            color: Color(0xFF667085),
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

    final points = <Offset?>[];

    for (int i = 0; i < values.length; i++) {
      final horizontalPosition =
          values.length == 1 ? 0.5 : i / (values.length - 1);
      final x = chartLeft + (chartWidth * horizontalPosition);
      final value = values[i];

      if (value == null) {
        points.add(null);
        continue;
      }

      final y = _yPosition(
        value: value,
        upper: axisValues.first,
        lower: axisValues.last,
        chartTop: chartTop,
        chartHeight: chartHeight,
      );

      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = primaryBlue
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pointFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = primaryBlue
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final realPoints = points.whereType<Offset>().toList();

    if (realPoints.length > 1) {
      final linePath = Path()..moveTo(realPoints.first.dx, realPoints.first.dy);

      for (int i = 1; i < realPoints.length; i++) {
        linePath.lineTo(realPoints[i].dx, realPoints[i].dy);
      }

      canvas.drawPath(linePath, linePaint);
    }

    for (final point in realPoints) {
      canvas.drawCircle(point, 3.1, pointFillPaint);
      canvas.drawCircle(point, 3.1, pointBorderPaint);
    }

    final labelIndexes = _visibleLabelIndexes();

    for (final index in labelIndexes) {
      if (index < 0 || index >= labels.length) {
        continue;
      }

      final horizontalPosition =
          labels.length == 1 ? 0.5 : index / (labels.length - 1);
      final x = chartLeft + (chartWidth * horizontalPosition);

      canvas.drawLine(
        Offset(x, chartBottom),
        Offset(x, chartBottom + 5),
        tickPaint,
      );

      _drawBottomLabel(
        canvas,
        labels[index],
        x,
        chartBottom + 10,
        isFirst: index == 0,
        isLast: index == labels.length - 1,
      );
    }
  }

  List<int> _visibleLabelIndexes() {
    if (labels.length <= 3) {
      return List.generate(labels.length, (index) => index);
    }

    return [
      0,
      labels.length ~/ 2,
      labels.length - 1,
    ];
  }

  List<double> _axisValues() {
    final realValues = values.whereType<double>().toList();

    if (realValues.isEmpty) {
      if (trendType == 'Weight') {
        return const [77, 75, 73];
      }

      if (trendType == 'BMI') {
        return const [30, 25, 20];
      }

      return const [10, 5, 0];
    }

    var minimum = realValues.reduce((a, b) => a < b ? a : b);
    var maximum = realValues.reduce((a, b) => a > b ? a : b);

    if (trendType == 'Workouts' || trendType == 'Steps / Activity') {
      minimum = 0;
    }

    double lower;
    double upper;

    if (trendType == 'Weight') {
      final range = maximum - minimum;

      if (range <= 2) {
        lower = (minimum - 1.5).floorToDouble();
        upper = (maximum + 1.5).ceilToDouble();
      } else {
        lower = (minimum - 1).floorToDouble();
        upper = (maximum + 1).ceilToDouble();
      }
    } else if (trendType == 'BMI') {
      lower = minimum - 0.8;
      upper = maximum + 0.8;
    } else {
      lower = 0;
      upper = maximum <= 0 ? 5 : maximum * 1.20;
    }

    if (upper <= lower) {
      upper = lower + 1;
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
    if (trendType == 'Weight') {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }

      return value.toStringAsFixed(1);
    }

    if (trendType == 'BMI') {
      return value.toStringAsFixed(1);
    }

    if (trendType == 'Steps / Activity') {
      if (value < 1000) {
        return value.toStringAsFixed(0);
      }

      final thousands = value / 1000;

      return thousands % 1 == 0
          ? '${thousands.toInt()}k'
          : '${thousands.toStringAsFixed(1)}k';
    }

    return value.toStringAsFixed(0);
  }

  void _drawBottomLabel(
    Canvas canvas,
    String text,
    double x,
    double y, {
    required bool isFirst,
    required bool isLast,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isFirst ? const Color(0xFF0B1B4D) : const Color(0xFF667085),
          fontSize: 11.5,
          fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double labelX = x - painter.width / 2;

    if (isFirst) {
      labelX = x;
    } else if (isLast) {
      labelX = x - painter.width;
    }

    painter.paint(
      canvas,
      Offset(labelX, y),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.trendType != trendType;
  }
}