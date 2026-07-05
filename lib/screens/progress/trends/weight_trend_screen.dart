import 'package:flutter/material.dart';

import '../add_weight/add_weight_screen.dart';
import '../log_workout/select_workout_type_screen.dart';

class WeightTrendScreen extends StatefulWidget {
  final String initialTrendType;
  final String initialTimeRange;

  const WeightTrendScreen({
    super.key,
    required this.initialTrendType,
    required this.initialTimeRange,
  });

  @override
  State<WeightTrendScreen> createState() => _WeightTrendScreenState();
}

class _WeightTrendScreenState extends State<WeightTrendScreen> {
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

  String get _screenTitle {
    switch (_selectedTrend) {
      case 'BMI':
        return 'BMI Trend';
      case 'Workouts':
        return 'Workout Trend';
      case 'Steps / Activity':
        return 'Activity Trend';
      default:
        return 'Weight Trend';
    }
  }

  String get _chartHeading {
    switch (_selectedTrend) {
      case 'BMI':
        return 'BMI';
      case 'Workouts':
        return 'Workouts';
      case 'Steps / Activity':
        return 'Steps';
      default:
        return 'Weight (kg)';
    }
  }

  String get _averageValue {
    switch (_selectedTrend) {
      case 'BMI':
        return '22.8';
      case 'Workouts':
        return _selectedRange == 'Weekly'
            ? '3 workouts'
            : _selectedRange == 'Monthly'
                ? '14 workouts'
                : '146 workouts';
      case 'Steps / Activity':
        return _selectedRange == 'Weekly'
            ? '7,220'
            : _selectedRange == 'Monthly'
                ? '7,540'
                : '7,360';
      default:
        return '72.8 kg';
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
                ? '8,600'
                : '9,240';
      default:
        return '71.6 kg';
    }
  }

  String get _changeValue {
    switch (_selectedTrend) {
      case 'BMI':
        return '↓ 0.4';
      case 'Workouts':
        return '↑ 2';
      case 'Steps / Activity':
        return '↑ 12.5%';
      default:
        return '↓ 1.2 kg';
    }
  }

  String get _insightOne {
    switch (_selectedTrend) {
      case 'BMI':
        return 'Your BMI decreased by 0.4 this month.';
      case 'Workouts':
        return 'You completed 16 workouts this month.';
      case 'Steps / Activity':
        return 'Your daily steps have increased this month.';
      default:
        return 'Weight decreased by 1.2 kg this month.';
    }
  }

  String get _insightTwo {
    switch (_selectedTrend) {
      case 'BMI':
        return 'You completed 4 workouts this week.';
      case 'Workouts':
        return 'You are building a consistent workout routine.';
      case 'Steps / Activity':
        return 'You reached your step goal on 5 days.';
      default:
        return 'You completed 4 workouts this week.';
    }
  }

  List<double> get _chartValues {
    if (_selectedTrend == 'BMI') {
      return [23.4, 23.2, 23.0, 22.9, 22.7, 22.6, 22.4];
    }

    if (_selectedTrend == 'Workouts') {
      return _selectedRange == 'Weekly'
          ? [0, 1, 1, 2, 2, 3, 4]
          : _selectedRange == 'Monthly'
              ? [2, 4, 7, 9, 11, 13, 16]
              : [12, 30, 45, 66, 82, 110, 146];
    }

    if (_selectedTrend == 'Steps / Activity') {
      return [5600, 6200, 6800, 7150, 7700, 8100, 8245];
    }

    if (_selectedRange == 'Weekly') {
      return [74.5, 73.9, 73.5, 73.1, 72.8, 72.5, 72.4];
    }

    if (_selectedRange == 'Yearly') {
      return [79.2, 77.8, 76.5, 75.2, 74.1, 72.8, 71.6];
    }

    return [75.1, 74.6, 74.1, 73.7, 73.4, 72.9, 72.4, 72.0, 71.6];
  }

  List<String> get _chartLabels {
    if (_selectedRange == 'Weekly') {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }

    if (_selectedRange == 'Yearly') {
      return ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov', 'Dec'];
    }

    return [
      'May 1',
      'May 4',
      'May 8',
      'May 11',
      'May 15',
      'May 18',
      'May 22',
      'May 25',
      'May 29',
    ];
  }

  void _openAddWeight() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddWeightScreen(),
      ),
    );
  }

  void _openLogWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SelectWorkoutTypeScreen(),
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
                      color: darkText,
                      size: 30,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _screenTitle,
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
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
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

                    const SizedBox(height: 18),

                    Row(
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
                                borderRadius: BorderRadius.circular(15),
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

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _chartHeading,
                                  style: const TextStyle(
                                    color: darkText,
                                    fontSize: 27,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                height: 45,
                                width: 45,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3FF),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: const Color(0xFFB8D5FF),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.open_in_full_rounded,
                                  color: primaryBlue,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: 320,
                            child: DetailedTrendChart(
                              values: _chartValues,
                              labels: _chartLabels,
                              trendType: _selectedTrend,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _bottomMetric(
                                  icon: Icons.show_chart_rounded,
                                  label: 'Average',
                                  value: _averageValue,
                                ),
                              ),
                              _verticalDivider(),
                              Expanded(
                                child: _bottomMetric(
                                  icon: Icons.scale_outlined,
                                  label: 'Latest',
                                  value: _latestValue,
                                ),
                              ),
                              _verticalDivider(),
                              Expanded(
                                child: _bottomMetric(
                                  icon: Icons.south_rounded,
                                  label: 'Change',
                                  value: _changeValue,
                                  valueColor: successGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3FF),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: primaryBlue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Insights',
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _insightRow(
                            icon: Icons.trending_down_rounded,
                            text: _insightOne,
                            highlight: _selectedTrend == 'Weight'
                                ? '1.2 kg'
                                : null,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(),
                          ),
                          _insightRow(
                            icon: Icons.fitness_center_outlined,
                            text: _insightTwo,
                            highlight: _selectedTrend == 'Workouts'
                                ? '16 workouts'
                                : _selectedTrend == 'Weight'
                                    ? '4 workouts'
                                    : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: ElevatedButton.icon(
                              onPressed: _openAddWeight,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text(
                                'Add Weight',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: OutlinedButton.icon(
                              onPressed: _openLogWorkout,
                              icon: const Icon(Icons.fitness_center_outlined),
                              label: const Text(
                                'Log Workout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryBlue,
                                side: const BorderSide(
                                  color: primaryBlue,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFD4DDEA),
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x331555C0),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
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

  Widget _bottomMetric({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: primaryBlue,
              size: 25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: greyText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? darkText,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 95,
      width: 1,
      color: const Color(0xFFE3E8F1),
    );
  }

  Widget _insightRow({
    required IconData icon,
    required String text,
    String? highlight,
  }) {
    if (highlight == null || !text.contains(highlight)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: successGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: darkText,
                fontSize: 17,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
    }

    final splitText = text.split(highlight);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F6EB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: successGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: darkText,
                fontSize: 17,
                height: 1.35,
              ),
              children: [
                TextSpan(text: splitText.first),
                TextSpan(
                  text: highlight,
                  style: const TextStyle(
                    color: successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (splitText.length > 1) TextSpan(text: splitText.last),
              ],
            ),
          ),
        ),
      ],
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

class DetailedTrendChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String trendType;

  const DetailedTrendChart({
    super.key,
    required this.values,
    required this.labels,
    required this.trendType,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetailedTrendChartPainter(
        values: values,
        labels: labels,
        trendType: trendType,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DetailedTrendChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final String trendType;

  _DetailedTrendChartPainter({
    required this.values,
    required this.labels,
    required this.trendType,
  });

  static const Color primaryBlue = Color(0xFF1555C0);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFC9DCF8)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = primaryBlue
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0x251555C0)
      ..style = PaintingStyle.fill;

    final pointFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = primaryBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const left = 42.0;
    const top = 18.0;
    const bottomPadding = 44.0;

    final right = size.width - 10;
    final bottom = size.height - bottomPadding;
    final chartWidth = right - left;
    final chartHeight = bottom - top;

    for (int i = 0; i < 5; i++) {
      final y = top + (chartHeight / 4) * i;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    for (int i = 0; i < 5; i++) {
      final x = left + (chartWidth / 4) * i;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
    }

    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);
    final safeRange = maximum == minimum ? 1.0 : maximum - minimum;

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = left + (chartWidth * i / (values.length - 1));
      final normalizedValue = (values[i] - minimum) / safeRange;
      final y = bottom - (normalizedValue * chartHeight * 0.78) - 18;

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

    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      final lastPointPaint = Paint()..color = const Color(0xFF2E7D32);

      canvas.drawCircle(
        points[i],
        isLast ? 7 : 5,
        isLast ? lastPointPaint : pointFillPaint,
      );

      if (!isLast) {
        canvas.drawCircle(points[i], 5, pointBorderPaint);
      }
    }

    final labelIndexes = _labelIndexes(labels.length);

    for (final index in labelIndexes) {
      _drawCenteredLabel(
        canvas,
        labels[index],
        points[index].dx,
        bottom + 13,
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

  List<int> _labelIndexes(int length) {
    if (length <= 5) {
      return List.generate(length, (index) => index);
    }

    return [
      0,
      (length * 0.25).round(),
      (length * 0.5).round(),
      (length * 0.75).round(),
      length - 1,
    ];
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

      final label = value.toStringAsFixed(0);

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
          fontSize: 10,
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
  bool shouldRepaint(covariant _DetailedTrendChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.trendType != trendType;
  }
}