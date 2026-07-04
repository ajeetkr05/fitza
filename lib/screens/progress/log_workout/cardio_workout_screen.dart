import 'package:flutter/material.dart';

import 'review_workout_screen.dart';

class CardioWorkoutScreen extends StatefulWidget {
  const CardioWorkoutScreen({super.key});

  @override
  State<CardioWorkoutScreen> createState() => _CardioWorkoutScreenState();
}

class _CardioWorkoutScreenState extends State<CardioWorkoutScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);

  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedActivity = 'Running';

  final List<String> _activities = [
    'Running',
    'Walking',
    'Cycling',
    'Swimming',
    'Other',
  ];

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _reviewWorkout() {
    final duration = _durationController.text.trim();

    if (duration.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the workout duration.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewWorkoutScreen(
          exercises: [
            {
              'name': _selectedActivity,
              'sets': '',
              'reps': duration,
              'weight': '',
              'distance': _distanceController.text.trim(),
              'steps': _stepsController.text.trim(),
              'calories': _caloriesController.text.trim(),
            },
          ],
          notes: _notesController.text.trim(),
          workoutType: 'Cardio',
          duration: '$duration min',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: darkText,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Cardio Workout',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkText,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 26),

              _card(
                child: Column(
                  children: [
                    _selectionRow(
                      icon: Icons.directions_run_rounded,
                      title: 'Activity Type',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedActivity,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: primaryBlue,
                          ),
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          items: _activities
                              .map(
                                (activity) => DropdownMenuItem(
                                  value: activity,
                                  child: Text(activity),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedActivity = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const Divider(height: 34),

                    _selectionRow(
                      icon: Icons.calendar_month_outlined,
                      title: 'Date',
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          color: darkText,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Divider(height: 34),

                    _inputRow(
                      icon: Icons.schedule_outlined,
                      title: 'Duration',
                      controller: _durationController,
                      hintText: 'e.g. 30',
                      suffixText: 'min',
                      requiredField: true,
                    ),

                    const Divider(height: 34),

                    _inputRow(
                      icon: Icons.location_on_outlined,
                      title: 'Distance (optional)',
                      controller: _distanceController,
                      hintText: 'e.g. 4.5',
                      suffixText: 'km',
                    ),

                    const Divider(height: 34),

                    _inputRow(
                      icon: Icons.directions_walk_outlined,
                      title: 'Steps (optional)',
                      controller: _stepsController,
                      hintText: 'e.g. 6500',
                    ),

                    const Divider(height: 34),

                    _inputRow(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Calories burned (optional)',
                      controller: _caloriesController,
                      hintText: 'e.g. 320',
                      suffixText: 'kcal',
                    ),

                    const Divider(height: 34),

                    _notesRow(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFB7D7FF),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: primaryBlue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: darkText,
                            fontSize: 16,
                            height: 1.35,
                          ),
                          children: [
                            TextSpan(text: 'Your last run:\n'),
                            TextSpan(
                              text: '4.1 km in 32 min',
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _reviewWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Review Workout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _selectionRow({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: primaryBlue,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: greyText,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 7),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputRow({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required String hintText,
    String? suffixText,
    bool requiredField = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: primaryBlue,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requiredField ? '$title *' : title,
                style: const TextStyle(
                  color: greyText,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: hintText,
                  suffixText: suffixText,
                  suffixStyle: const TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.bold,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFB7C1D3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _notesRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.edit_note_outlined,
            color: primaryBlue,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notes (optional)',
                style: TextStyle(
                  color: greyText,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Add any notes about your workout...',
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFB7C1D3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}