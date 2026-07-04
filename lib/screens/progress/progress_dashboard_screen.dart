import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation.dart';
import 'add_weight/add_weight_screen.dart';
import 'log_workout/select_workout_type_screen.dart';

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

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.monitor_weight_outlined,
                      iconColor: primaryBlue,
                      title: 'Current Weight',
                      value: '72.4',
                      unit: 'kg',
                      subtitle: '↓ 1.2 kg\nvs last week',
                      subtitleColor: successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      icon: Icons.favorite_border_rounded,
                      iconColor: successGreen,
                      title: 'BMI',
                      value: '22.4',
                      unit: '',
                      subtitle: 'Healthy',
                      subtitleColor: successGreen,
                    ),
                  ),
                ],
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(
                      context,
                      icon: Icons.show_chart_rounded,
                      label: 'View Trends',
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
                onPressed: () => _showComingSoon(context, 'View Trends'),
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
          const SizedBox(height: 8),
          const SizedBox(
            height: 155,
            child: _SimpleWeightChart(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '↓ 1.2 kg this week',
              style: TextStyle(
                color: successGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
  const _SimpleWeightChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WeightChartPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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

    for (int i = 0; i < 4; i++) {
      final y = 10 + i * (size.height - 30) / 3;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final points = [
      Offset(size.width * 0.05, size.height * 0.36),
      Offset(size.width * 0.20, size.height * 0.66),
      Offset(size.width * 0.36, size.height * 0.48),
      Offset(size.width * 0.51, size.height * 0.57),
      Offset(size.width * 0.67, size.height * 0.40),
      Offset(size.width * 0.82, size.height * 0.15),
      Offset(size.width * 0.95, size.height * 0.47),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(point, 5, pointBorderPaint);
    }

    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < labels.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Color(0xFF5B6475),
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final x = points[i].dx - (textPainter.width / 2);

      textPainter.paint(
        canvas,
        Offset(x, size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}