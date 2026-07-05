import 'package:flutter/material.dart';

import '../log_workout/gym_workout_screen.dart';

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
    if (_isGym) return 'Progress Comparison';

    if (workoutType == 'Cardio') {
      return 'Activity Progress';
    }

    return 'Session Progress';
  }

  String get _progressSubtitle {
    if (_isGym) return 'Weight lifted over time';

    if (workoutType == 'Cardio') {
      return 'Duration and consistency over time';
    }

    return 'Session consistency over time';
  }

  List<Map<String, String>> get _historyItems {
    switch (workoutType) {
      case 'Yoga':
        return [
          {
            'date': 'May 16',
            'details': '30 min session • Easy',
          },
          {
            'date': 'May 9',
            'details': '35 min session • Moderate',
          },
          {
            'date': 'May 2',
            'details': '25 min session • Easy',
          },
        ];

      case 'Calisthenics':
        return [
          {
            'date': 'May 16',
            'details': '3 sets × 15 push-ups',
          },
          {
            'date': 'May 9',
            'details': '3 sets × 12 push-ups',
          },
          {
            'date': 'May 2',
            'details': '2 sets × 10 push-ups',
          },
        ];

      case 'Cardio':
        return [
          {
            'date': 'May 16',
            'details': '4.5 km • 30 min • 6,500 steps',
          },
          {
            'date': 'May 9',
            'details': '4.1 km • 32 min • 6,100 steps',
          },
          {
            'date': 'May 2',
            'details': '3.8 km • 29 min • 5,700 steps',
          },
        ];

      default:
        return [
          {
            'date': 'May 16',
            'details': '4 sets × 8 reps × 75 kg',
          },
          {
            'date': 'May 9',
            'details': '4 sets × 8 reps × 70 kg',
          },
          {
            'date': 'May 2',
            'details': '4 sets × 6 reps × 65 kg',
          },
        ];
    }
  }

  List<Map<String, String>> get _statItems {
    switch (workoutType) {
      case 'Yoga':
        return [
          {
            'label': 'Latest',
            'value': '30 min',
            'icon': 'latest',
          },
          {
            'label': 'Last Session',
            'value': '35 min',
            'icon': 'calendar',
          },
          {
            'label': 'One Week Ago',
            'value': '25 min',
            'icon': 'history',
          },
          {
            'label': 'Longest Session',
            'value': '45 min',
            'icon': 'trophy',
          },
        ];

      case 'Calisthenics':
        return [
          {
            'label': 'Latest',
            'value': '15 reps',
            'icon': 'latest',
          },
          {
            'label': 'Last Workout',
            'value': '12 reps',
            'icon': 'calendar',
          },
          {
            'label': 'One Week Ago',
            'value': '10 reps',
            'icon': 'history',
          },
          {
            'label': 'Personal Best',
            'value': '20 reps',
            'icon': 'trophy',
          },
        ];

      case 'Cardio':
        return [
          {
            'label': 'Latest',
            'value': '4.5 km',
            'icon': 'latest',
          },
          {
            'label': 'Last Activity',
            'value': '4.1 km',
            'icon': 'calendar',
          },
          {
            'label': 'One Week Ago',
            'value': '3.8 km',
            'icon': 'history',
          },
          {
            'label': 'Best Distance',
            'value': '6.2 km',
            'icon': 'trophy',
          },
        ];

      default:
        return [
          {
            'label': 'Latest',
            'value': '80 kg × 8',
            'icon': 'latest',
          },
          {
            'label': 'Last Workout',
            'value': '75 kg × 8',
            'icon': 'calendar',
          },
          {
            'label': 'One Week Ago',
            'value': '70 kg × 8',
            'icon': 'history',
          },
          {
            'label': 'Personal Best',
            'value': '90 kg × 6',
            'icon': 'trophy',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  const Icon(
                    Icons.more_vert_rounded,
                    color: primaryBlue,
                    size: 30,
                  ),
                ],
              ),

              const SizedBox(height: 26),

              _statsRow(),

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
                                  Icons.trending_up_rounded,
                                  color: successGreen,
                                  size: 22,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '+14.3%',
                                  style: TextStyle(
                                    color: successGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'vs 4 weeks ago',
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

                    if (_isGym) ...[
                      const Text(
                        'Weight (kg)',
                        style: TextStyle(
                          color: darkText,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(
                        height: 250,
                        child: ExerciseProgressChart(),
                      ),
                    ] else
                      Container(
                        height: 190,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          'Session consistency and progress\nwill appear here.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: greyText,
                            fontSize: 17,
                            height: 1.4,
                          ),
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

              ..._historyItems.map(
                (item) => _historyCard(
                  date: item['date']!,
                  details: item['details']!,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GymWorkoutScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isGym
                        ? 'Log This Exercise Again'
                        : 'Log This Workout Again',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsRow() {
    final items = _statItems;

    final icons = [
      Icons.fitness_center_outlined,
      Icons.calendar_month_outlined,
      Icons.history_outlined,
      Icons.emoji_events_outlined,
    ];

    return Row(
      children: List.generate(items.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == items.length - 1 ? 0 : 10,
            ),
            child: _statCard(
              icon: icons[index],
              label: items[index]['label']!,
              value: items[index]['value']!,
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
            const Icon(
              Icons.chevron_right_rounded,
              color: primaryBlue,
              size: 30,
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

class ExerciseProgressChart extends StatelessWidget {
  const ExerciseProgressChart({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ExerciseChartPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ExerciseChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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

    final left = 38.0;
    final right = size.width - 12;
    final top = 18.0;
    final bottom = size.height - 35;

    for (int i = 0; i < 4; i++) {
      final y = top + ((bottom - top) / 3) * i;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    canvas.drawLine(Offset(left, top), Offset(left, bottom), gridPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), gridPaint);

    final chartWidth = right - left;

    final points = [
      Offset(left + (chartWidth * 0.08), bottom - 62),
      Offset(left + (chartWidth * 0.34), bottom - 48),
      Offset(left + (chartWidth * 0.60), bottom - 48),
      Offset(left + (chartWidth * 0.88), bottom - 82),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 8, pointPaint);
      canvas.drawCircle(points[i], 8, borderPaint);
    }

    _drawLabel(canvas, '65', Offset(points[0].dx - 10, points[0].dy - 28));
    _drawLabel(canvas, '70', Offset(points[1].dx - 10, points[1].dy - 28));
    _drawLabel(canvas, '70', Offset(points[2].dx - 10, points[2].dy - 28));
    _drawLabel(canvas, '80', Offset(points[3].dx - 10, points[3].dy - 28));

    _drawCenteredLabel(canvas, 'Apr 18', points[0].dx, bottom + 12);
    _drawCenteredLabel(canvas, 'Apr 25', points[1].dx, bottom + 12);
    _drawCenteredLabel(canvas, 'May 2', points[2].dx, bottom + 12);
    _drawCenteredLabel(canvas, 'May 9', points[3].dx, bottom + 12);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF1555C0),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, offset);
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
          color: Color(0xFF1555C0),
          fontSize: 10,
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}