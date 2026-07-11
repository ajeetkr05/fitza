import 'package:flutter/material.dart';

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
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color background = Color(0xFFF5F5F5);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
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
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: darkText,
                            size: 29,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Select Workout',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: darkText,
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

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose how you want to log today’s workout.',
                        style: TextStyle(
                          color: greyText,
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _workoutOption(
                      title: 'Gym',
                      subtitle: 'Weights, sets and reps',
                      icon: Icons.fitness_center_outlined,
                    ),

                    const SizedBox(height: 12),

                    _workoutOption(
                      title: 'Yoga',
                      subtitle: 'Sessions, duration and flexibility',
                      icon: Icons.self_improvement_outlined,
                    ),

                    const SizedBox(height: 12),

                    _workoutOption(
                      title: 'Calisthenics',
                      subtitle: 'Bodyweight exercises',
                      icon: Icons.accessibility_new_rounded,
                    ),

                    const SizedBox(height: 12),

                    _workoutOption(
                      title: 'Cardio',
                      subtitle: 'Running, walking, cycling and more',
                      icon: Icons.monitor_heart_outlined,
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
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
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

  Widget _workoutOption({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedWorkoutType == title;
    final iconColor = _workoutIconColor(title);

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
            color: isSelected
                ? iconColor.withValues(alpha: 0.07)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? iconColor : const Color(0xFFE1E7F0),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: iconColor.withValues(alpha: 0.10),
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
                      style: const TextStyle(
                        color: darkText,
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
                      style: const TextStyle(
                        color: greyText,
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
                  color: isSelected ? iconColor : Colors.white,
                  border: Border.all(
                    color: isSelected ? iconColor : const Color(0xFFD0D5DD),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
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