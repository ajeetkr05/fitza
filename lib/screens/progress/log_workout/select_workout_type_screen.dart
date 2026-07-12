import 'package:flutter/material.dart';

import '../../../main.dart';
import 'cardio_workout_screen.dart';
import 'gym_workout_screen.dart';
import 'yoga_calisthenics_screen.dart';

class SelectWorkoutTypeScreen extends StatefulWidget {
  const SelectWorkoutTypeScreen({super.key});

  @override
  State<SelectWorkoutTypeScreen> createState() =>
      _SelectWorkoutTypeScreenState();
}

class _SelectWorkoutTypeScreenState extends State<SelectWorkoutTypeScreen> {
  String _selectedWorkoutType = 'Gym';

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color successGreen = Color(0xFF2E7D32);

  void _continue() {
    Widget nextScreen;

    switch (_selectedWorkoutType) {
      case 'Gym':
        nextScreen = const GymWorkoutScreen();
        break;
      case 'Yoga':
        nextScreen = const YogaCalisthenicsScreen(
          workoutType: 'Yoga',
        );
        break;
      case 'Calisthenics':
        nextScreen = const YogaCalisthenicsScreen(
          workoutType: 'Calisthenics',
        );
        break;
      default:
        nextScreen = const CardioWorkoutScreen();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  Color _workoutIconColor(String workoutType) {
    switch (workoutType) {
      case 'Yoga':
        return Colors.deepPurple;
      case 'Calisthenics':
        return successGreen;
      case 'Cardio':
        return Colors.orange;
      default:
        return primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fitzaColors = Theme.of(context).extension<FitzaThemeColors>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: fitzaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: fitzaColors.primaryText,
                            size: 29,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Select Workout',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: fitzaColors.primaryText,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose how you want to log today’s workout.',
                        style: TextStyle(
                          color: fitzaColors.secondaryText,
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _workoutOption(
                      context,
                      title: 'Gym',
                      subtitle: 'Weights, sets and reps',
                      icon: Icons.fitness_center_outlined,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 12),

                    _workoutOption(
                      context,
                      title: 'Yoga',
                      subtitle: 'Sessions, duration and flexibility',
                      icon: Icons.self_improvement_outlined,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 12),

                    _workoutOption(
                      context,
                      title: 'Calisthenics',
                      subtitle: 'Bodyweight exercises',
                      icon: Icons.accessibility_new_rounded,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 12),

                    _workoutOption(
                      context,
                      title: 'Cardio',
                      subtitle: 'Running, walking, cycling and more',
                      icon: Icons.monitor_heart_outlined,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fitzaColors.primaryBlue,
                    foregroundColor: fitzaColors.textOnBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: isDarkMode ? 0 : 2,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: fitzaColors.textOnBlue,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workoutOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDarkMode,
  }) {
    final fitzaColors = Theme.of(context).extension<FitzaThemeColors>()!;
    final isSelected = _selectedWorkoutType == title;
    final iconColor = _workoutIconColor(title);

    final Color cardColor = isSelected
        ? iconColor.withValues(alpha: isDarkMode ? 0.16 : 0.07)
        : fitzaColors.surface;

    final Color borderColor = isSelected ? iconColor : fitzaColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            _selectedWorkoutType = title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.8 : 1,
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: iconColor.withValues(
                  alpha: isDarkMode ? 0.18 : 0.10,
                ),
                child: Icon(
                  icon,
                  size: 31,
                  color: iconColor,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fitzaColors.secondaryText,
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? iconColor : fitzaColors.surface,
                  border: Border.all(
                    color: isSelected ? iconColor : fitzaColors.border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: fitzaColors.textOnBlue,
                        size: 20,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}