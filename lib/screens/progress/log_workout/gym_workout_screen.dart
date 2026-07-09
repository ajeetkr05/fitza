import 'package:flutter/material.dart';

import 'review_workout_screen.dart';
import '../../../data/gym_exercise_suggestions.dart';

class GymWorkoutScreen extends StatefulWidget {
  const GymWorkoutScreen({super.key});

  @override
  State<GymWorkoutScreen> createState() => _GymWorkoutScreenState();
}

class _GymWorkoutScreenState extends State<GymWorkoutScreen> {
  static const primaryBlue = Color(0xFF1555C0);
  static const darkText = Color(0xFF0B1B4D);
  static const greyText = Color(0xFF667085);
  static const background = Color(0xFFF5F5F5);

  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '30');
  final _notesController = TextEditingController();
  final _exerciseFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  bool _showExerciseSuggestions = false;

  final List<Map<String, String>> _exercises = [];


  @override
  void initState() {
    super.initState();

    _exerciseFocusNode.addListener(() {
      if (!_exerciseFocusNode.hasFocus && _showExerciseSuggestions) {
        setState(() {
          _showExerciseSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _exerciseFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  List<String> _filteredExerciseSuggestions() {
    final query = _exerciseController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    final startsWithMatches = exerciseSuggestions.where((exercise) {
      return exercise.toLowerCase().startsWith(query);
    }).toList();

    final wordStartsWithMatches = exerciseSuggestions.where((exercise) {
      final lowerExercise = exercise.toLowerCase();

      return !startsWithMatches.contains(exercise) &&
          lowerExercise.split(' ').any((word) => word.startsWith(query));
    }).toList();

    final containsMatches = exerciseSuggestions.where((exercise) {
      final lowerExercise = exercise.toLowerCase();

      return !startsWithMatches.contains(exercise) &&
          !wordStartsWithMatches.contains(exercise) &&
          lowerExercise.contains(query);
    }).toList();

    return [
      ...startsWithMatches,
      ...wordStartsWithMatches,
      ...containsMatches,
    ].take(8).toList();
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
      _showExerciseSuggestions = false;
    });

    FocusScope.of(context).unfocus();
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
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  String _formattedDate() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];

    final today = DateTime.now();

    final isToday =
        _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    if (isToday) {
      return 'Today';
    }

    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
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
                            'Gym Workout',
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

                    _card(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Row(
                          children: [
                            _iconBox(Icons.calendar_month_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date',
                                    style: TextStyle(
                                      color: greyText,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formattedDate(),
                                    style: const TextStyle(
                                      color: darkText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_calendar_outlined,
                              color: primaryBlue,
                              size: 23,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _exerciseInputCard(),

                    if (_exercises.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ...List.generate(
                        _exercises.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _exercises.length - 1 ? 0 : 10,
                          ),
                          child: _exerciseCard(
                            index: index,
                            exercise: _exercises[index],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    _notesCard(),
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
                  onPressed: _reviewWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Review Workout',
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

  Widget _exerciseInputCard() {
    final shouldShowSuggestions =
        _showExerciseSuggestions && _filteredExerciseSuggestions().isNotEmpty;

    return _card(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Exercise',
                style: TextStyle(
                  color: greyText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _exerciseController,
                focusNode: _exerciseFocusNode,
                onChanged: (value) {
                  setState(() {
                    _showExerciseSuggestions =
                        value.trim().isNotEmpty && _exerciseFocusNode.hasFocus;
                  });
                },
                style: const TextStyle(
                  color: darkText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _inputDecoration(
                  hintText: 'Search or enter exercise',
                  prefixIcon: Icons.search_rounded,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _smallInput(
                      label: 'Sets',
                      controller: _setsController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallInput(
                      label: 'Reps',
                      controller: _repsController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallInput(
                      label: 'Weight',
                      controller: _weightController,
                      suffix: 'kg',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      'Add Exercise',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (shouldShowSuggestions)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: _suggestionsBox(),
            ),
        ],
      ),
    );
  }

  Widget _suggestionsBox() {
    final suggestions = _filteredExerciseSuggestions();

    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxHeight: 172,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE1E7F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) {
            return const Divider(
              height: 1,
              color: Color(0xFFE5EAF2),
            );
          },
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];

            return InkWell(
              onTap: () {
                setState(() {
                  _exerciseController.text = suggestion;
                  _exerciseController.selection =
                      TextSelection.collapsed(offset: suggestion.length);
                  _showExerciseSuggestions = false;
                });

                FocusScope.of(context).unfocus();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fitness_center_outlined,
                      color: primaryBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _notesCard() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(Icons.edit_note_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notes (optional)',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 7,
                  maxLength: 200,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'How did the workout feel?',
                    hintStyle: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    counterStyle: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11,
                    ),
                    alignLabelWithHint: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
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
                        width: 1.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: primaryBlue,
        size: 24,
      ),
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
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: darkText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
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
            radius: 22,
            backgroundColor: const Color(0xFFEAF3FF),
            child: const Icon(
              Icons.fitness_center_outlined,
              color: primaryBlue,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise['name']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${exercise['sets']} sets  ×  ${exercise['reps']} reps  ×  ${exercise['weight']} kg',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: greyText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
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
              size: 24,
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
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              color: const Color(0xFF4B5563),
              size: 22,
            ),
      hintStyle: const TextStyle(
        color: Color(0xFF667085),
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        color: darkText,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
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
          width: 1.7,
        ),
      ),
    );
  }
}