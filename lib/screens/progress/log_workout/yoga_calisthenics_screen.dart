import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../services/progress/workout_firestore_service.dart';

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
  static const Color successGreen = Color(0xFF2E7D32);

  static const Color easyColor = Color(0xFF009688);
  static const Color moderateColor = Color(0xFFFFB300);
  static const Color hardColor = Color(0xFFD32F2F);

  final TextEditingController _sessionNameController =
      TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, String>> _activities = [];

  DateTime _selectedDate = DateTime.now();
  String _selectedDifficulty = 'Easy';
  bool _isSaving = false;

  bool get _isYoga => widget.workoutType == 'Yoga';

  Color get _accentColor {
    if (_isYoga) {
      return Colors.deepPurple;
    }

    return successGreen;
  }

  IconData get _workoutIcon {
    if (_isYoga) {
      return Icons.self_improvement_outlined;
    }

    return Icons.accessibility_new_rounded;
  }

  String get _screenTitle {
    return _isYoga ? 'Yoga Workout' : 'Calisthenics';
  }

  String get _umbrellaLabel {
    return _isYoga ? 'Session Name' : 'Routine Name';
  }

  String get _umbrellaHint {
    return _isYoga ? 'Morning Yoga' : 'Push Day';
  }

  String get _activityLabel {
    return _isYoga ? 'Asana Name' : 'Exercise Name';
  }

  String get _activityHint {
    return _isYoga ? 'Sun Salutation' : 'Push-ups';
  }

  String get _addButtonLabel {
    return _isYoga ? 'Add Asana' : 'Add Exercise';
  }

  String get _listTitle {
    return _isYoga ? 'Added Asanas' : 'Added Exercises';
  }

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _activityController.dispose();
    _durationController.dispose();
    _setsController.dispose();
    _notesController.dispose();
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

  bool _addActivity({bool showMessage = true}) {
    final activityName = _activityController.text.trim();
    final duration = _durationController.text.trim();
    final sets = _setsController.text.trim();

    if (activityName.isEmpty) {
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isYoga
                  ? 'Please enter an asana name.'
                  : 'Please enter an exercise name.',
            ),
          ),
        );
      }

      return false;
    }

    if (_isYoga && duration.isEmpty) {
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter duration for this asana.'),
          ),
        );
      }

      return false;
    }

    if (!_isYoga && sets.isEmpty) {
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter sets for this exercise.'),
          ),
        );
      }

      return false;
    }

    setState(() {
      _activities.add({
        'name': activityName,
        'sets': sets,
        'reps': duration,
        'weight': '',
        'difficulty': _selectedDifficulty,
      });

      _activityController.clear();
      _durationController.clear();
      _setsController.clear();
      _selectedDifficulty = 'Easy';
    });

    FocusScope.of(context).unfocus();
    return true;
  }

  void _deleteActivity(int index) {
    setState(() {
      _activities.removeAt(index);
    });
  }

  Future<void> _saveWorkout() async {
    if (_isSaving) {
      return;
    }

    final sessionName = _sessionNameController.text.trim();

    if (sessionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isYoga
                ? 'Please enter a session name.'
                : 'Please enter a routine name.',
          ),
        ),
      );
      return;
    }

    if (_activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isYoga
                ? 'Please add at least one asana.'
                : 'Please add at least one exercise.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await WorkoutFirestoreService.instance.saveWorkout(
        workoutType: widget.workoutType,
        workoutName: sessionName,
        duration: '${_totalDurationMinutes()} min',
        notes: _notesController.text.trim(),
        exercises: List<Map<String, String>>.from(_activities),
        recordedAt: _selectedDate,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.workoutType} workout saved.'),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error, stackTrace) {
      debugPrint('Could not save ${widget.workoutType} workout: $error');
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

  int _totalDurationMinutes() {
    var total = 0;

    for (final activity in _activities) {
      total += int.tryParse(activity['reps'] ?? '') ?? 0;
    }

    return total;
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

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Moderate':
        return moderateColor;
      case 'Hard':
        return hardColor;
      default:
        return easyColor;
    }
  }

  IconData _difficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'Moderate':
        return Icons.sentiment_neutral_outlined;
      case 'Hard':
        return Icons.sentiment_dissatisfied_outlined;
      default:
        return Icons.sentiment_satisfied_alt_outlined;
    }
  }

  String _activityDetails(Map<String, String> activity) {
    final parts = <String>[];

    final duration = activity['reps']?.trim() ?? '';
    final sets = activity['sets']?.trim() ?? '';
    final difficulty = activity['difficulty']?.trim() ?? '';

    if (_isYoga) {
      if (duration.isNotEmpty) {
        parts.add('$duration min');
      }

      if (sets.isNotEmpty) {
        parts.add('$sets sets');
      }
    } else {
      if (sets.isNotEmpty) {
        parts.add('$sets sets');
      }

      if (duration.isNotEmpty) {
        parts.add('$duration min');
      }
    }

    if (difficulty.isNotEmpty) {
      parts.add(difficulty);
    }

    return parts.join(' • ');
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
                            _screenTitle,
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

                    _activityInputCard(),

                    if (_activities.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _activityListCard(),
                    ],

                    const SizedBox(height: 14),

                    _notesCard(),

                    const SizedBox(height: 14),

                    _infoCard(),
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
                          color: _accentColor,
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
                    controller: _sessionNameController,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _compactInputDecoration(
                      hintText: _umbrellaHint,
                      prefixIcon: _workoutIcon,
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

  Widget _activityInputCard() {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Details',
                style: TextStyle(
                  color: fitzaColors.secondaryText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _activityController,
                textInputAction: TextInputAction.next,
                style: TextStyle(
                  color: fitzaColors.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _inputDecoration(
                  hintText: _activityHint,
                  prefixIcon: _workoutIcon,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _smallInput(
                      label: 'Duration',
                      controller: _durationController,
                      hintText: _isYoga ? '20' : '10',
                      suffix: 'min',
                      icon: Icons.schedule_outlined,
                      requiredLabel: _isYoga,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallInput(
                      label: 'Sets',
                      controller: _setsController,
                      hintText: '3',
                      icon: Icons.layers_outlined,
                      requiredLabel: !_isYoga,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Difficulty',
                style: TextStyle(
                  color: fitzaColors.secondaryText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _difficultyButton(
                      label: 'Easy',
                      icon: Icons.sentiment_satisfied_alt_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _difficultyButton(
                      label: 'Moderate',
                      icon: Icons.sentiment_neutral_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _difficultyButton(
                      label: 'Hard',
                      icon: Icons.sentiment_dissatisfied_outlined,
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
                    onPressed: _addActivity,
                    icon: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: fitzaColors.textOnBlue,
                    ),
                    label: Text(
                      _addButtonLabel,
                      style: TextStyle(
                        color: fitzaColors.textOnBlue,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: fitzaColors.textOnBlue,
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
        );
      },
    );
  }

  Widget _activityListCard() {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _listTitle,
                style: TextStyle(
                  color: fitzaColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                _activities.length,
                (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _activities.length - 1 ? 0 : 10,
                    ),
                    child: _activityCard(
                      index: index,
                      activity: _activities[index],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _activityCard({
    required int index,
    required Map<String, String> activity,
  }) {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);
        final difficulty = activity['difficulty'] ?? 'Easy';
        final difficultyColor = _difficultyColor(difficulty);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fitzaColors.inputSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: fitzaColors.border,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: difficultyColor.withValues(
                  alpha: _isDark(context) ? 0.20 : 0.10,
                ),
                child: Icon(
                  _difficultyIcon(difficulty),
                  color: difficultyColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['name'] ?? '',
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
                      _activityDetails(activity),
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
                onPressed: () => _deleteActivity(index),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 23,
                ),
              ),
            ],
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
                      decoration: _notesInputDecoration(),
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

  Widget _infoCard() {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _accentColor.withValues(
              alpha: _isDark(context) ? 0.16 : 0.08,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: _accentColor.withValues(
                  alpha: _isDark(context) ? 0.22 : 0.14,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: _accentColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isYoga
                      ? 'Track your sessions and see how your consistency improves over time.'
                      : 'Track your bodyweight routines and compare your progress later.',
                  style: TextStyle(
                    color: fitzaColors.primaryText,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _smallInput({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool requiredLabel,
    String? suffix,
  }) {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: _accentColor,
                  size: 19,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    requiredLabel ? label : '$label (optional)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fitzaColors.secondaryText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
                hintText: hintText,
                suffixText: suffix,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _difficultyButton({
    required String label,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);
        final isSelected = _selectedDifficulty == label;
        final difficultyColor = _difficultyColor(label);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _selectedDifficulty = label;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? difficultyColor.withValues(
                      alpha: _isDark(context) ? 0.18 : 0.10,
                    )
                  : fitzaColors.inputSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? difficultyColor : fitzaColors.border,
                width: isSelected ? 1.7 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? difficultyColor : fitzaColors.primaryText,
                  size: 19,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          isSelected ? difficultyColor : fitzaColors.primaryText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        return Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: _accentColor.withValues(
              alpha: _isDark(context) ? 0.20 : 0.10,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: _accentColor,
            size: 24,
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
              color: _accentColor,
              size: 20,
            ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 38,
        minHeight: 38,
      ),
      hintStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.w700,
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
          color: _accentColor,
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
              color: _accentColor,
              size: 22,
            ),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: fitzaColors.primaryText,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      hintStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
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
          color: _accentColor,
          width: 1.7,
        ),
      ),
    );
  }

  InputDecoration _notesInputDecoration() {
    final fitzaColors = _colors(context);

    return InputDecoration(
      hintText: _isYoga
          ? 'How did this session feel?'
          : 'How did this routine go?',
      filled: true,
      fillColor: fitzaColors.inputSurface,
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
          color: _accentColor,
          width: 1.7,
        ),
      ),
    );
  }
}