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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE1E7F0),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: darkText,
                        size: 30,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Select Workout Type',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkText,
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 72),
              const Text(
                'Choose the type of workout you want to log',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkText,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: 48),
              _workoutOption(
                title: 'Gym',
                subtitle: 'Weights, sets and reps',
                icon: Icons.fitness_center_outlined,
              ),
              const SizedBox(height: 20),
              _workoutOption(
                title: 'Yoga',
                subtitle: 'Sessions, duration and flexibility',
                icon: Icons.self_improvement_outlined,
              ),
              const SizedBox(height: 20),
              _workoutOption(
                title: 'Calisthenics',
                subtitle: 'Bodyweight exercises',
                icon: Icons.accessibility_new_rounded,
              ),
              const SizedBox(height: 20),
              _workoutOption(
                title: 'Cardio',
                subtitle: 'Running, walking, cycling and more',
                icon: Icons.monitor_heart_outlined,
              ),
              const SizedBox(height: 38),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 22,
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

  Widget _workoutOption({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedWorkoutType == title;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        setState(() {
          _selectedWorkoutType = title;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F8FF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFE5EAF2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: const Color(0xFFEAF3FF),
              child: Icon(
                icon,
                size: 45,
                color: primaryBlue,
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: greyText,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const CircleAvatar(
                radius: 18,
                backgroundColor: primaryBlue,
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}