import 'package:flutter/material.dart';

import '../../../data/gym_exercise_suggestions.dart';
import '../../../main.dart';
import '../../../services/progress/workout_firestore_service.dart';

class GymWorkoutScreen extends StatefulWidget {
  const GymWorkoutScreen({super.key});

  @override
  State<GymWorkoutScreen> createState() => _GymWorkoutScreenState();
}

class _GymWorkoutScreenState extends State<GymWorkoutScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);

  final _workoutNameController = TextEditingController();
  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '30');
  final _notesController = TextEditingController();
  final _exerciseFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  bool _showExerciseSuggestions = false;
  bool _isSaving = false;

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
    _workoutNameController.dispose();
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _exerciseFocusNode.dispose();
    super.dispose();
  }

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
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

  Future<void> _saveWorkout() async {
    if (_isSaving) {
      return;
    }

    final workoutName = _workoutNameController.text.trim();

    if (workoutName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a workout name, like Chest + Triceps.'),
        ),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one exercise before saving.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await WorkoutFirestoreService.instance.saveWorkout(
        workoutType: 'Gym',
        duration: '0 min',
        notes: _notesController.text.trim(),
        exercises: List<Map<String, String>>.from(_exercises),
        recordedAt: _selectedDate,
        workoutName: workoutName,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout saved.'),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error, stackTrace) {
      debugPrint('Could not save gym workout: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save workout. Please check your connection and try again.',
          ),
        ),
      );
    }
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
    final fitzaColors = _colors(context);

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
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: fitzaColors.primaryText,
                            size: 29,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Gym Workout',
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

                    _workoutInfoCard(),

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
                  onPressed: _isSaving ? null : _saveWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fitzaColors.primaryBlue,
                    foregroundColor: fitzaColors.textOnBlue,
                    disabledBackgroundColor: _isDark(context)
                        ? const Color(0xFF375C9F)
                        : const Color(0xFF9BB7EA),
                    disabledForegroundColor: fitzaColors.textOnBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _isDark(context) ? 0 : 2,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: fitzaColors.textOnBlue,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          'Save Workout',
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

  Widget _workoutInfoCard() {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return _card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 9,
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: fitzaColors.inputSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: fitzaColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: fitzaColors.primaryBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  color: fitzaColors.secondaryText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _formattedDate(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: fitzaColors.primaryText,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 13,
                child: SizedBox(
                  height: 54,
                  child: TextField(
                    controller: _workoutNameController,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _compactInputDecoration(
                      hintText: 'Workout name',
                      prefixIcon: Icons.edit_outlined,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
              Builder(
                builder: (context) {
                  final fitzaColors = _colors(context);

                  return Text(
                    'Exercise',
                    style: TextStyle(
                      color: fitzaColors.secondaryText,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              Builder(
                builder: (context) {
                  final fitzaColors = _colors(context);

                  return TextField(
                    controller: _exerciseController,
                    focusNode: _exerciseFocusNode,
                    onChanged: (value) {
                      setState(() {
                        _showExerciseSuggestions =
                            value.trim().isNotEmpty &&
                            _exerciseFocusNode.hasFocus;
                      });
                    },
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Search or enter exercise',
                      prefixIcon: Icons.search_rounded,
                    ),
                  );
                },
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
                    icon: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: _colors(context).textOnBlue,
                    ),
                    label: Text(
                      'Add Exercise',
                      style: TextStyle(
                        color: _colors(context).textOnBlue,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colors(context).primaryBlue,
                      foregroundColor: _colors(context).textOnBlue,
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

    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

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
              color: fitzaColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: fitzaColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isDark(context)
                      ? const Color(0x66000000)
                      : const Color(0x18000000),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) {
                return Divider(
                  height: 1,
                  color: fitzaColors.border,
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
                        Icon(
                          Icons.fitness_center_outlined,
                          color: fitzaColors.primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              color: fitzaColors.primaryText,
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
      },
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
            child: Builder(
              builder: (context) {
                final fitzaColors = _colors(context);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes (optional)',
                      style: TextStyle(
                        color: fitzaColors.secondaryText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 200,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'How did the workout feel?',
                        hintStyle: TextStyle(
                          color: fitzaColors.secondaryText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        counterStyle: TextStyle(
                          color: fitzaColors.secondaryText,
                          fontSize: 11,
                        ),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: fitzaColors.inputSurface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: fitzaColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: fitzaColors.primaryBlue,
                            width: 1.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: fitzaColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _isDark(context)
                    ? const Color(0x33000000)
                    : const Color(0x0F000000),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  Widget _iconBox(IconData icon) {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: fitzaColors.primaryBlue.withValues(
              alpha: _isDark(context) ? 0.20 : 0.10,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: fitzaColors.primaryBlue,
            size: 24,
          ),
        );
      },
    );
  }

  Widget _smallInput({
    required String label,
    required TextEditingController controller,
    String? suffix,
  }) {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fitzaColors.secondaryText,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: fitzaColors.primaryText,
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
      },
    );
  }

  Widget _exerciseCard({
    required int index,
    required Map<String, String> exercise,
  }) {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return _card(
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: fitzaColors.primaryBlue.withValues(
                  alpha: _isDark(context) ? 0.20 : 0.10,
                ),
                child: Icon(
                  Icons.fitness_center_outlined,
                  color: fitzaColors.primaryBlue,
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
                      style: TextStyle(
                        color: fitzaColors.primaryText,
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
                      style: TextStyle(
                        color: fitzaColors.secondaryText,
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
      },
    );
  }

  InputDecoration _compactInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    final fitzaColors = _colors(context);

    return InputDecoration(
      isDense: true,
      hintText: hintText,
      filled: true,
      fillColor: fitzaColors.inputSurface,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              color: fitzaColors.primaryBlue,
              size: 20,
            ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 38,
        minHeight: 38,
      ),
      hintStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: fitzaColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: fitzaColors.primaryBlue,
          width: 1.7,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    String? suffixText,
  }) {
    final fitzaColors = _colors(context);

    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: fitzaColors.inputSurface,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              color: fitzaColors.secondaryText,
              size: 22,
            ),
      hintStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: fitzaColors.primaryText,
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
        borderSide: BorderSide(
          color: fitzaColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: fitzaColors.primaryBlue,
          width: 1.7,
        ),
      ),
    );
  }
}