import 'package:flutter/material.dart';
import '../../widgets/app_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const HomeScreen({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1555C0);
    const darkText = Color(0xFF0B1B4D);
    const screenBackground = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: screenBackground,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: widget.selectedIndex,
        onTap: widget.onTabChanged,
        ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: darkText,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.bolt_rounded,
                          color: primaryBlue,
                          size: 42,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Fitza',
                          style: TextStyle(
                            color: darkText,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Spacer(),
                        _headerIcon(Icons.dark_mode_outlined),
                        const SizedBox(width: 10),
                        _headerIcon(Icons.notifications_none_rounded),
                      ],
                    ),

                    const SizedBox(height: 34),

                    const Text(
                      'Good morning, Alex',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Earn it, Every day',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 28),

                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            title: 'Today’s Summary',
                            actionText: 'View All',
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _summaryItem(
                                  icon: Icons.directions_walk_rounded,
                                  iconColor: Color(0xFF1976D2),
                                  title: 'Steps',
                                  value: '8,245',
                                  subtitle: '/ 10,000',
                                ),
                              ),
                              Expanded(
                                child: _summaryItem(
                                  icon: Icons.local_fire_department_outlined,
                                  iconColor: Color(0xFFFF7A00),
                                  title: 'Calories Burned',
                                  value: '540',
                                  subtitle: 'kcal',
                                ),
                              ),
                              Expanded(
                                child: _summaryItem(
                                  icon: Icons.timer_outlined,
                                  iconColor: Color(0xFF2E7D32),
                                  title: 'Active Minutes',
                                  value: '62',
                                  subtitle: '/ 60 min',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today’s Workout',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Full Body Strength',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _workoutTag(
                                icon: Icons.schedule_outlined,
                                label: '45 min',
                              ),
                              _workoutTag(
                                icon: Icons.bar_chart_rounded,
                                label: 'Moderate',
                              ),
                              _workoutTag(
                                icon: Icons.fitness_center_outlined,
                                label: 'Equipment',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Start Workout',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            title: 'Your Progress',
                            actionText: 'View Progress',
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _progressMiniCard(
                                  icon: Icons.trending_up_rounded,
                                  title: 'Weight',
                                  value: '72.4 kg',
                                  subtitle: '-1.2 kg this week',
                                  iconColor: Color(0xFF1555C0),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _progressMiniCard(
                                  icon: Icons.trending_up_rounded,
                                  title: 'Streak',
                                  value: '12 days',
                                  subtitle: 'Keep it up!',
                                  iconColor: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            icon: Icons.restaurant_outlined,
                            label: 'Log Meal',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.monitor_weight_outlined,
                            label: 'Add Weight',
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

  Widget _headerIcon(IconData icon) {
    return Container(
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
      child: Icon(icon, color: const Color(0xFF0B1B4D)),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required String title,
    required String actionText,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0B1B4D),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          actionText,
          style: const TextStyle(
            color: Color(0xFF1555C0),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF1555C0),
        ),
      ],
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5B6475),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0B1B4D),
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF5B6475),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _workoutTag({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF5B6475),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF45536A),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressMiniCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5B6475),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0B1B4D),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: iconColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF1555C0),
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0B1B4D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}