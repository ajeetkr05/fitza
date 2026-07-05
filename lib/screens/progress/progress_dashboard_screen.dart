import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation.dart';
import 'add_weight/add_weight_screen.dart';
import 'log_workout/select_workout_type_screen.dart';
import 'exercise_history/exercise_history_screen.dart';
import 'trends/trends_screen.dart';
import '../../models/progress/weight_entry.dart';
import '../../services/progress/weight_firestore_service.dart';

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

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: successGreen,
                      title: 'Workout Streak',
                      value: '12',
                      unit: 'days',
                      subtitle: '',
                      subtitleColor: successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      icon: Icons.fitness_center_outlined,
                      iconColor: primaryBlue,
                      title: 'Workouts\nThis Week',
                      value: '4',
                      unit: 'workouts',
                      subtitle: '',
                      subtitleColor: primaryBlue,
                    ),
                  ),
                ],
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
                onPressed: () => _showComingSoon(context, 'Exercise History'),
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
          _workoutRow(
            icon: Icons.fitness_center_outlined,
            iconColor: primaryBlue,
            title: 'Bench Press',
            details: '30 kg × 10 reps × 3 sets',
            time: '2 days ago',
          ),
          const SizedBox(height: 10),
          _workoutRow(
            icon: Icons.accessibility_new_rounded,
            iconColor: successGreen,
            title: 'Squats',
            details: '40 kg × 8 reps × 3 sets',
            time: '3 days ago',
          ),
          const SizedBox(height: 10),
          _workoutRow(
            icon: Icons.self_improvement_outlined,
            iconColor: Colors.deepPurple,
            title: 'Yoga Flow',
            details: '30 min',
            time: '5 days ago',
          ),
        ],
      ),
    );
  }

  Widget _workoutRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String details,
    required String time,
  }) {
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
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  style: const TextStyle(
                    color: Color(0xFF5B6475),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 7),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B7280),
              ),
            ],
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