import 'package:flutter/material.dart';

import 'weight_trend_screen.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color successGreen = Color(0xFF2E7D32);

  String _selectedTrend = 'Weight';
  String _selectedRange = 'Weekly';

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

  String get _latestLabel {
    switch (_selectedTrend) {
      case 'BMI':
        return 'Latest BMI';
      case 'Workouts':
        return 'Workouts Completed';
      case 'Steps / Activity':
        return 'Latest Steps';
      default:
        return 'Latest Weight';
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

  void _openDetailedTrend() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeightTrendScreen(
          initialTrendType: _selectedTrend,
          initialTimeRange: _selectedRange,
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

                    const SizedBox(height: 14),

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
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7F6EB),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _changeValue,
                                  style: const TextStyle(
                                    color: successGreen,
                                    fontSize: 17,
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
                              values: _chartValues,
                              labels: _chartLabels,
                              trendType: _selectedTrend,
                            ),
                          ),

                          const SizedBox(height: 18),

                          GestureDetector(
                            onTap: _openDetailedTrend,
                            child: Row(
                              children: const [
                                Spacer(),
                                Text(
                                  'View detailed trend',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: primaryBlue,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            icon: _trendIcon(_selectedTrend),
                            title: _latestLabel,
                            value: _latestValue,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _summaryCard(
                            icon: Icons.trending_down_rounded,
                            title: 'Change vs last period',
                            value: _changeValue,
                            valueColor: successGreen,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Container(
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
                                  _insight,
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

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: primaryBlue,
              size: 27,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: greyText,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? darkText,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
      final x = left + (chartWidth * i / (values.length - 1));
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
        label = '${(value / 1000).toStringAsFixed(0)}k';
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