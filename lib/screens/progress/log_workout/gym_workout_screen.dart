import 'package:flutter/material.dart';

import 'review_workout_screen.dart';

class GymWorkoutScreen extends StatefulWidget {
  const GymWorkoutScreen({super.key});

  @override
  State<GymWorkoutScreen> createState() => _GymWorkoutScreenState();
}

class _GymWorkoutScreenState extends State<GymWorkoutScreen> {
  static const primaryBlue = Color(0xFF1555C0);
  static const darkText = Color(0xFF0B1B4D);
  static const greyText = Color(0xFF667085);

  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '30');
  final _notesController = TextEditingController();

  final List<Map<String, String>> _exercises = [
    {
      'name': 'Dumbbell Row',
      'sets': '3',
      'reps': '12',
      'weight': '20',
    },
  ];

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final name = _exerciseController.text.trim();
    final sets = _setsController.text.trim();
    final reps = _repsController.text.trim();
    final weight = _weightController.text.trim();

    if (name.isEmpty || sets.isEmpty || reps.isEmpty || weight.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete exercise name, sets, reps and weight.'),
        ),
      );
      return;
    }

    setState(() {
      _exercises.add({
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
      });

      _exerciseController.clear();
      _setsController.text = '3';
      _repsController.text = '10';
      _weightController.text = '30';
    });
  }

  void _deleteExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _reviewWorkout() {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one exercise before reviewing.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewWorkoutScreen(
          exercises: List<Map<String, String>>.from(_exercises),
          notes: _notesController.text.trim(),
          workoutType: 'Gym',
          duration: '45 min',
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
                      'Gym Workout',
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
              const SizedBox(height: 22),

              _card(
                child: Row(
                  children: const [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              color: greyText,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Today',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.calendar_month_outlined,
                      color: primaryBlue,
                      size: 34,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exercise Name',
                      style: TextStyle(
                        color: greyText,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _exerciseController,
                      decoration: _inputDecoration(
                        hintText: 'Search or enter exercise',
                        prefixIcon: Icons.search_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Exercise'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlue,
                        side: const BorderSide(
                          color: primaryBlue,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _smallInput(
                            label: 'Sets',
                            controller: _setsController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _smallInput(
                            label: 'Reps',
                            controller: _repsController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _smallInput(
                            label: 'Weight',
                            controller: _weightController,
                            suffix: 'kg',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              ...List.generate(
                _exercises.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _exerciseCard(
                    index: index,
                    exercise: _exercises[index],
                  ),
                ),
              ),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes (optional)',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        hintText: 'How did the workout feel?',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    _exerciseController.clear();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Add Another Exercise',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: const BorderSide(
                      color: primaryBlue,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

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
                  child: const Text(
                    'Review Workout',
                    style: TextStyle(
                      fontSize: 20,
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _smallInput({
    required String label,
    required TextEditingController controller,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: greyText,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            hintText: '',
            suffixText: suffix,
          ),
        ),
      ],
    );
  }

  Widget _exerciseCard({
    required int index,
    required Map<String, String> exercise,
  }) {
    return _card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFEAF3FF),
            child: const Icon(
              Icons.fitness_center_outlined,
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
                  exercise['name']!,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${exercise['sets']} sets  ×  ${exercise['reps']} reps  ×  ${exercise['weight']} kg',
                  style: const TextStyle(
                    color: greyText,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteExercise(index),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        color: darkText,
        fontWeight: FontWeight.bold,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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