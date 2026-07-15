import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'Nutrition/nutrition_home_screen.dart';
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

  
}