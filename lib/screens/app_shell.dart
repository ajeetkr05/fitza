import 'package:flutter/material.dart';

import '../widgets/app_bottom_navigation.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'progress/progress_dashboard_screen.dart';
import 'workout/workout_home_screen.dart';
import '../models/workout/plan_customization.dart';


class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  PlanCustomization? _workoutCustomization;

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
      

    });
  }

  void _updateWorkoutCustomization(PlanCustomization? customization) {
  setState(() => _workoutCustomization = customization);
  }


  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        selectedIndex: _selectedIndex,
        onTabChanged: _changeTab,
      ),
      WorkoutHomeScreen(
        selectedIndex: _selectedIndex,
        onTabChanged: _changeTab,
        customization: _workoutCustomization,
        onCustomizationChanged: _updateWorkoutCustomization,
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0B1B4D),
        elevation: 0,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _changeTab,
      ),
      body: Center(
        child: Text(
          '$title screen will be added soon',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1555C0),
          ),
        ),
      ),
    );
  }
}