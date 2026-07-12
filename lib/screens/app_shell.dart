import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home/home_screen.dart';
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
      _placeholderScreen('Nutrition'),
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

    return Scaffold(
      backgroundColor: fitzaColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: fitzaColors.background,
        foregroundColor: fitzaColors.primaryText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _changeTab,
      ),
      body: Center(
        child: Text(
          '$title screen will be added soon',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: fitzaColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}