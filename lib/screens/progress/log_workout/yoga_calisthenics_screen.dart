import 'package:flutter/material.dart';

import 'review_workout_screen.dart';

class YogaCalisthenicsScreen extends StatefulWidget {
  final String workoutType;

  const YogaCalisthenicsScreen({
    super.key,
    required this.workoutType,
  });

  @override
  State<YogaCalisthenicsScreen> createState() =>
      _YogaCalisthenicsScreenState();
}

class _YogaCalisthenicsScreenState extends State<YogaCalisthenicsScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);

  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedDifficulty = 'Easy';

  @override
  void dispose() {
    _activityController.dispose();
    _durationController.dispose();
    _setsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _reviewWorkout() {
    final activity = _activityController.text.trim();
    final duration = _durationController.text.trim();

    if (activity.isEmpty || duration.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an activity name and duration.'),
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
              'name': activity,
              'sets': _setsController.text.trim(),
              'reps': duration,
              'weight': '',
              'difficulty': _selectedDifficulty,
            },
          ],
          notes: _notesController.text.trim(),
          workoutType: widget.workoutType,
          duration: '$duration min',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isYoga = widget.workoutType == 'Yoga';

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
                  Expanded(
                    child: Text(
                      isYoga ? 'Yoga Workout' : 'Calisthenics',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: primaryBlue,
                      size: 30,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Today',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: primaryBlue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _card(
                child: Column(
                  children: [
                    _formLabel(
                      icon: isYoga
                          ? Icons.self_improvement_outlined
                          : Icons.accessibility_new_rounded,
                      title: 'Activity / Session Name',
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _activityController,
                      decoration: _inputDecoration(
                        hintText: isYoga
                            ? 'e.g. Sun Salutation'
                            : 'e.g. Push-up routine',
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel(
                                icon: Icons.schedule_outlined,
                                title: 'Duration',
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  hintText: 'e.g. 30 min',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel(
                                icon: Icons.layers_outlined,
                                title: 'Sets (optional)',
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _setsController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  hintText: 'e.g. 3',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    _formLabel(
                      icon: Icons.bar_chart_rounded,
                      title: 'Difficulty',
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _difficultyButton(
                            label: 'Easy',
                            icon: Icons.sentiment_satisfied_alt_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _difficultyButton(
                            label: 'Moderate',
                            icon: Icons.sentiment_neutral_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _difficultyButton(
                            label: 'Hard',
                            icon: Icons.sentiment_dissatisfied_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    _formLabel(
                      icon: Icons.edit_note_outlined,
                      title: 'Notes (optional)',
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: _inputDecoration(
                        hintText: 'Add any notes about your workout...',
                      ),
                    ),
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
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 23,
                      backgroundColor: Color(0xFFD8E9FF),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isYoga
                            ? 'Track your consistency and compare your sessions with previous days.'
                            : 'Track your bodyweight progress and compare your routines over time.',
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 16,
                          height: 1.35,
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
      padding: const EdgeInsets.all(20),
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

  Widget _formLabel({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryBlue,
          size: 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _difficultyButton({
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedDifficulty == label;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _selectedDifficulty = label;
        });
      },
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F8FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFD7DEEA),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryBlue : darkText,
              size: 22,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? primaryBlue : darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA4B5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
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
    );
  }
}