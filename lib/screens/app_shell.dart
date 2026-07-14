import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/fitza_header.dart';
import 'home/home_screen.dart';
import 'Nutrition/nutrition_home_screen.dart';
import 'profile/profile_screen.dart';
import 'progress/progress_dashboard_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        selectedIndex: _selectedIndex,
        onTabChanged: _changeTab,
      ),
      _placeholderScreen('Workout'),
      NutritionHomeScreen(
        selectedIndex: _selectedIndex,
        onTabChanged: _changeTab,
      ),
      ProgressDashboardScreen(
        selectedIndex: _selectedIndex,
        onTabChanged: _changeTab,
      ),
      ProfileScreen(
        selectedIndex: _selectedIndex,
        onTabChanged: _changeTab,
      ),
    ];

    return pages[_selectedIndex];
  }

  Widget _placeholderScreen(String title) {
    final fitzaColors = Theme.of(context).extension<FitzaThemeColors>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: fitzaColors.background,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _changeTab,
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
                title,
                style: TextStyle(
                  color: fitzaColors.primaryText,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$title section is under development.',
                style: TextStyle(
                  color: fitzaColors.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: fitzaColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: fitzaColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? const Color(0x33000000)
                          : const Color(0x0F000000),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor:
                          fitzaColors.primaryBlue.withValues(alpha: 0.12),
                      child: Icon(
                        title == 'Workout'
                            ? Icons.fitness_center_outlined
                            : Icons.restaurant_outlined,
                        color: fitzaColors.primaryBlue,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$title Screen Coming Soon',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title == 'Workout'
                          ? 'Your workout plans and exercise recommendations will appear here.'
                          : 'Your meals, calories, and nutrition tracking will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fitzaColors.secondaryText,
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}