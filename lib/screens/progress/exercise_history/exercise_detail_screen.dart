import 'package:flutter/material.dart';

import '../../../models/progress/workout_entry.dart';
import '../../../services/progress/workout_firestore_service.dart';
import '../log_workout/cardio_workout_screen.dart';
import '../log_workout/gym_workout_screen.dart';
import '../log_workout/yoga_calisthenics_screen.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final String exerciseName;
  final String workoutType;
  final String latestDetails;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseName,
    required this.workoutType,
    required this.latestDetails,
  });

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color successGreen = Color(0xFF2E7D32);

  bool get _isGym => workoutType == 'Gym';

  String get _progressTitle {
    if (_isGym) {
      return 'Progress Comparison';
    }

    if (workoutType == 'Cardio') {
      return 'Activity Progress';
    }

    return 'Session Progress';
  }

  String get _progressSubtitle {
    if (_isGym) {
      return 'Weight lifted over time';
    }

    if (workoutType == 'Cardio') {
      return 'Distance or duration over time';
    }

    return 'Session duration over time';
  }

  List<_ExerciseOccurrence> _exerciseOccurrences(
    List<WorkoutEntry> workouts,
  ) {
    final occurrences = <_ExerciseOccurrence>[];

    for (final workout in workouts) {
      if (workout.workoutType != workoutType) {
        continue;
      }

      for (final exercise in workout.exercises) {
        final savedName = exercise['name']?.toString().trim() ?? '';

        if (savedName.toLowerCase() == exerciseName.toLowerCase()) {
          occurrences.add(
            _ExerciseOccurrence(
              workout: workout,
              exercise: exercise,
            ),
          );
        }
      }
    }

    occurrences.sort(
      (first, second) =>
          second.workout.recordedAt.compareTo(first.workout.recordedAt),
    );

    return occurrences;
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

  double _metricValue(_ExerciseOccurrence occurrence) {
    if (_isGym) {
      return _numberValue(occurrence.exercise['weightKg'])?.toDouble() ??
          _numberValue(occurrence.exercise['reps'])?.toDouble() ??
          0;
    }

    if (workoutType == 'Cardio') {
      return _numberValue(occurrence.exercise['distanceKm'])?.toDouble() ??
          _numberValue(occurrence.exercise['durationMinutes'])?.toDouble() ??
          occurrence.workout.durationMinutes.toDouble();
    }

    return _numberValue(occurrence.exercise['durationMinutes'])?.toDouble() ??
        occurrence.workout.durationMinutes.toDouble();
  }

  String _metricUnit(List<_ExerciseOccurrence> occurrences) {
    if (_isGym) {
      return 'kg';
    }

    if (workoutType == 'Cardio') {
      final hasDistance = occurrences.any(
        (occurrence) =>
            _numberValue(occurrence.exercise['distanceKm']) != null,
      );

      return hasDistance ? 'km' : 'min';
    }

    return 'min';
  }

  String _metricLabel(List<_ExerciseOccurrence> occurrences) {
    if (_isGym) {
      return 'Weight (kg)';
    }

    if (workoutType == 'Cardio') {
      return _metricUnit(occurrences) == 'km'
          ? 'Distance (km)'
          : 'Duration (min)';
    }

    return 'Duration (min)';
  }

  String _metricDisplay(_ExerciseOccurrence occurrence) {
    if (_isGym) {
      final weight = _numberValue(occurrence.exercise['weightKg']);
      final reps = _numberValue(occurrence.exercise['reps']);

      if (weight != null && reps != null) {
        return '${_formatNumber(weight)} kg × ${_formatNumber(reps)}';
      }

      if (weight != null) {
        return '${_formatNumber(weight)} kg';
      }

      if (reps != null) {
        return '${_formatNumber(reps)} reps';
      }
    }

    if (workoutType == 'Cardio') {
      final distance = _numberValue(occurrence.exercise['distanceKm']);

      if (distance != null) {
        return '${_formatNumber(distance)} km';
      }

      final duration = _numberValue(occurrence.exercise['durationMinutes']);

      if (duration != null) {
        return '${_formatNumber(duration)} min';
      }
    }

    final duration = _numberValue(occurrence.exercise['durationMinutes']);

    if (duration != null) {
      return '${_formatNumber(duration)} min';
    }

    return '${occurrence.workout.durationMinutes} min';
  }

  String _historyDetails(_ExerciseOccurrence occurrence) {
    if (_isGym) {
      final parts = <String>[];

      final weight = _numberValue(occurrence.exercise['weightKg']);
      final reps = _numberValue(occurrence.exercise['reps']);
      final sets = _numberValue(occurrence.exercise['sets']);

      if (weight != null) {
        parts.add('${_formatNumber(weight)} kg');
      }

      if (reps != null) {
        parts.add('${_formatNumber(reps)} reps');
      }

      if (sets != null) {
        parts.add('${_formatNumber(sets)} sets');
      }

      return parts.isEmpty ? 'No details saved' : parts.join(' × ');
    }

    if (workoutType == 'Cardio') {
      final parts = <String>[];

      final distance = _numberValue(occurrence.exercise['distanceKm']);
      final duration = _numberValue(occurrence.exercise['durationMinutes']);
      final steps = _numberValue(occurrence.exercise['steps']);
      final calories = _numberValue(occurrence.exercise['caloriesBurned']);

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
          ? '${occurrence.workout.durationMinutes} min workout'
          : parts.join(' • ');
    }

    final parts = <String>[];

    final duration = _numberValue(occurrence.exercise['durationMinutes']);
    final sets = _numberValue(occurrence.exercise['sets']);
    final difficulty = occurrence.exercise['difficulty']?.toString() ?? '';

    parts.add(
      duration == null
          ? '${occurrence.workout.durationMinutes} min'
          : '${_formatNumber(duration)} min',
    );

    if (sets != null) {
      parts.add('${_formatNumber(sets)} sets');
    }

    if (difficulty.trim().isNotEmpty) {
      parts.add(difficulty.trim());
    }

    return parts.join(' • ');
  }

  List<_DetailStat> _statItems(
    List<_ExerciseOccurrence> occurrences,
  ) {
    final latest = occurrences.first;
    final previous = occurrences.length >= 2 ? occurrences[1] : null;

    final best = occurrences.reduce(
      (bestOccurrence, occurrence) =>
          _metricValue(occurrence) > _metricValue(bestOccurrence)
              ? occurrence
              : bestOccurrence,
    );

    return [
      _DetailStat(
        label: 'Latest',
        value: _metricDisplay(latest),
        icon: Icons.show_chart_rounded,
      ),
      _DetailStat(
        label: workoutType == 'Cardio' ? 'Last Activity' : 'Last Session',
        value: previous == null ? 'No earlier entry' : _metricDisplay(previous),
        icon: Icons.calendar_month_outlined,
      ),
      _DetailStat(
        label: _isGym
            ? 'Best Weight'
            : workoutType == 'Cardio'
                ? 'Best Result'
                : 'Longest Session',
        value: _metricDisplay(best),
        icon: Icons.emoji_events_outlined,
      ),
      _DetailStat(
        label: 'Sessions',
        value: occurrences.length.toString(),
        icon: Icons.history_outlined,
      ),
    ];
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
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  void _logWorkoutAgain(BuildContext context) {
    if (workoutType == 'Cardio') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CardioWorkoutScreen(),
        ),
      );
      return;
    }

    if (workoutType == 'Yoga' || workoutType == 'Calisthenics') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YogaCalisthenicsScreen(
            workoutType: workoutType,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GymWorkoutScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: StreamBuilder<List<WorkoutEntry>>(
          stream: WorkoutFirestoreService.instance.getWorkoutEntriesStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _screenLayout(
                context,
                _statusCard(
                  icon: Icons.error_outline_rounded,
                  message: 'Could not load this exercise history.',
                  iconColor: Colors.red,
                ),
              );
            }

            if (!snapshot.hasData) {
              return _screenLayout(
                context,
                _statusCard(
                  icon: Icons.hourglass_top_rounded,
                  message: 'Loading exercise details...',
                  iconColor: primaryBlue,
                  isLoading: true,
                ),
              );
            }

            final occurrences = _exerciseOccurrences(snapshot.data!);

            if (occurrences.isEmpty) {
              return _screenLayout(
                context,
                _emptyExerciseContent(context),
              );
            }

            return _screenLayout(
              context,
              _exerciseContent(context, occurrences),
            );
          },
        ),
      ),
    );
  }

  Widget _screenLayout(BuildContext context, Widget content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: primaryBlue,
                  size: 31,
                ),
              ),
              Expanded(
                child: Text(
                  exerciseName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 26),
          content,
        ],
      ),
    );
  }

  Widget _exerciseContent(
    BuildContext context,
    List<_ExerciseOccurrence> occurrences,
  ) {
    final stats = _statItems(occurrences);

    final oldestFirst = occurrences.reversed.toList();

    final chartValues = oldestFirst
        .map(_metricValue)
        .toList();

    final chartLabels = oldestFirst
        .map((occurrence) => _formatDate(occurrence.workout.recordedAt))
        .toList();

    final latestValue = chartValues.last;
    final firstValue = chartValues.first;
    final change = latestValue - firstValue;
    final unit = _metricUnit(occurrences);

    String changeText;
    Color changeColor;
    IconData changeIcon;

    if (chartValues.length < 2) {
      changeText = 'First saved entry';
      changeColor = primaryBlue;
      changeIcon = Icons.remove_rounded;
    } else if (change > 0) {
      changeText = '↑ ${_formatNumber(change)} $unit';
      changeColor = successGreen;
      changeIcon = Icons.trending_up_rounded;
    } else if (change < 0) {
      changeText = '↓ ${_formatNumber(change.abs())} $unit';
      changeColor = Colors.orange;
      changeIcon = Icons.trending_down_rounded;
    } else {
      changeText = 'No change';
      changeColor = primaryBlue;
      changeIcon = Icons.remove_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statsRow(stats),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _progressTitle,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _progressSubtitle,
                          style: const TextStyle(
                            color: greyText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            changeIcon,
                            color: changeColor,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            changeText,
                            style: TextStyle(
                              color: changeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'vs first entry',
                        style: TextStyle(
                          color: greyText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                _metricLabel(occurrences),
                style: const TextStyle(
                  color: darkText,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: ExerciseProgressChart(
                  values: chartValues,
                  labels: chartLabels,
                  suffix: unit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Workout History',
          style: TextStyle(
            color: darkText,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...occurrences.map(
          (occurrence) => _historyCard(
            date: _formatDate(occurrence.workout.recordedAt),
            details: _historyDetails(occurrence),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () => _logWorkoutAgain(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _isGym ? 'Log This Exercise Again' : 'Log This Workout Again',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyExerciseContent(BuildContext context) {
    return Column(
      children: [
        _statusCard(
          icon: Icons.history_toggle_off_rounded,
          message: latestDetails.isEmpty
              ? 'No saved history exists for this exercise yet.'
              : latestDetails,
          iconColor: greyText,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () => _logWorkoutAgain(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Log Workout',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
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
      decoration: _cardDecoration(),
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

  Widget _statsRow(List<_DetailStat> items) {
    return Row(
      children: List.generate(items.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == items.length - 1 ? 0 : 10,
            ),
            child: _statCard(
              icon: items[index].icon,
              label: items[index].label,
              value: items[index].value,
            ),
          ),
        );
      }),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 164,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryBlue, size: 29),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: greyText,
                  fontSize: 13,
                  height: 1.15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard({
    required String date,
    required String details,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: primaryBlue,
                size: 27,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    details,
                    style: const TextStyle(
                      color: greyText,
                      fontSize: 15,
                    ),
                  ),
                ],
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

class _ExerciseOccurrence {
  final WorkoutEntry workout;
  final Map<String, dynamic> exercise;

  const _ExerciseOccurrence({
    required this.workout,
    required this.exercise,
  });
}

class _DetailStat {
  final String label;
  final String value;
  final IconData icon;

  const _DetailStat({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class ExerciseProgressChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String suffix;

  const ExerciseProgressChart({
    super.key,
    required this.values,
    required this.labels,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ExerciseChartPainter(
        values: values,
        labels: labels,
        suffix: suffix,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ExerciseChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final String suffix;

  _ExerciseChartPainter({
    required this.values,
    required this.labels,
    required this.suffix,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFD8E2F1)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF1555C0)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF1555C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const left = 38.0;
    final right = size.width - 12;
    const top = 18.0;
    final bottom = size.height - 35;

    for (int i = 0; i < 4; i++) {
      final y = top + ((bottom - top) / 3) * i;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    canvas.drawLine(Offset(left, top), Offset(left, bottom), gridPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), gridPaint);

    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);
    final range = maximum == minimum ? 1.0 : maximum - minimum;

    final chartWidth = right - left;
    final chartHeight = bottom - top;

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final horizontalPosition =
          values.length == 1 ? 0.5 : i / (values.length - 1);

      final x = left + (chartWidth * horizontalPosition);
      final normalisedValue = (values[i] - minimum) / range;
      final y = bottom - (normalisedValue * chartHeight * 0.76) - 18;

      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 7, pointPaint);
      canvas.drawCircle(points[i], 7, borderPaint);

      _drawCenteredLabel(
        canvas,
        '${_formatValue(values[i])} $suffix',
        points[i].dx,
        points[i].dy - 28,
        fontSize: 11,
      );
    }

    for (int i = 0; i < labels.length; i++) {
      _drawCenteredLabel(
        canvas,
        labels[i],
        points[i].dx,
        bottom + 12,
        fontSize: 10,
      );
    }
  }

  String _formatValue(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  void _drawCenteredLabel(
    Canvas canvas,
    String text,
    double centerX,
    double y, {
    required double fontSize,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF1555C0),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
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
  bool shouldRepaint(covariant _ExerciseChartPainter oldDelegate) {
    return true;
  }
}