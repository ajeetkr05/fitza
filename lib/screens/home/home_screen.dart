import 'package:flutter/material.dart';

import '../../main.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/fitza_header.dart';

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
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color calorieOrange = Color(0xFFFF7A00);

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _softBackground(BuildContext context, Color color) {
    return color.withValues(alpha: _isDark(context) ? 0.20 : 0.12);
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be connected later.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitzaColors = _colors(context);

    return Scaffold(
      backgroundColor: fitzaColors.background,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: widget.selectedIndex,
        onTap: widget.onTabChanged,
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

              const SizedBox(height: 22),

              Text(
                'Good morning, Alex',
                style: TextStyle(
                  color: fitzaColors.primaryText,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Earn it, Every day',
                style: TextStyle(
                  color: fitzaColors.primaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      title: 'Today’s Summary',
                      actionText: 'View All',
                      onTap: () => _showComingSoon('Today summary'),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryItem(
                            icon: Icons.directions_walk_rounded,
                            iconColor: primaryBlue,
                            title: 'Steps',
                            value: '8,245',
                            subtitle: '/ 10,000',
                          ),
                        ),
                        Expanded(
                          child: _summaryItem(
                            icon: Icons.local_fire_department_outlined,
                            iconColor: calorieOrange,
                            title: 'Calories',
                            value: '540',
                            subtitle: 'kcal',
                          ),
                        ),
                        Expanded(
                          child: _summaryItem(
                            icon: Icons.timer_outlined,
                            iconColor: successGreen,
                            title: 'Active',
                            value: '62',
                            subtitle: '/ 60 min',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today’s Workout',
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Full Body Strength',
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
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
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _showComingSoon('Start workout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: fitzaColors.primaryBlue,
                          foregroundColor: fitzaColors.textOnBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: _isDark(context) ? 0 : 2,
                        ),
                        child: Text(
                          'Start Workout',
                          style: TextStyle(
                            color: fitzaColors.textOnBlue,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      title: 'Your Progress',
                      actionText: 'View Progress',
                      onTap: () => _showComingSoon('Progress'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _progressMiniCard(
                            icon: Icons.trending_up_rounded,
                            title: 'Weight',
                            value: '72.4 kg',
                            subtitle: '-1.2 kg this week',
                            iconColor: primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _progressMiniCard(
                            icon: Icons.local_fire_department_outlined,
                            title: 'Streak',
                            value: '12 days',
                            subtitle: 'Keep it up!',
                            iconColor: successGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Quick Actions',
                style: TextStyle(
                  color: fitzaColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      icon: Icons.restaurant_outlined,
                      label: 'Log Meal',
                      onTap: () => _showComingSoon('Log meal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickAction(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Add Weight',
                      onTap: () => _showComingSoon('Add weight'),
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

  Widget _sectionCard({required Widget child}) {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fitzaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: fitzaColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDark(context)
                ? const Color(0x33000000)
                : const Color(0x0F000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    final fitzaColors = _colors(context);

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: fitzaColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            child: Row(
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    color: fitzaColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: fitzaColors.primaryBlue,
                  size: 22,
                ),
              ],
            ),
          ),
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
    final fitzaColors = _colors(context);

    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _softBackground(context, iconColor),
          child: Icon(
            icon,
            color: iconColor,
            size: 25,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fitzaColors.secondaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: fitzaColors.primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: fitzaColors.secondaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _workoutTag({
    required IconData icon,
    required String label,
  }) {
    final fitzaColors = _colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: fitzaColors.inputSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: fitzaColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: fitzaColors.secondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
    final fitzaColors = _colors(context);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: fitzaColors.inputSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fitzaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 25,
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: TextStyle(
              color: fitzaColors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: iconColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final fitzaColors = _colors(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: fitzaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: fitzaColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: fitzaColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fitzaColors.primaryText,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}