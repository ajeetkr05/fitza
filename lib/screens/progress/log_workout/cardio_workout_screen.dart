import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../services/progress/workout_firestore_service.dart';

class CardioWorkoutScreen extends StatefulWidget {
  const CardioWorkoutScreen({super.key});

  @override
  State<CardioWorkoutScreen> createState() => _CardioWorkoutScreenState();
}

class _CardioWorkoutScreenState extends State<CardioWorkoutScreen> {
  static const Color cardioOrange = Colors.orange;

  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final FocusNode _activityFocusNode = FocusNode();
  final LayerLink _activityFieldLink = LayerLink();

  OverlayEntry? _activitySuggestionsOverlay;

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _activities = [
    'Running',
    'Walking',
    'Cycling',
    'Swimming',
    'Treadmill Run',
    'Stair Climber',
    'Elliptical',
    'Rowing',
    'Jump Rope',
    'Hiking',
    'HIIT',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _activityFocusNode.addListener(() {
      if (!_activityFocusNode.hasFocus) {
        _removeActivitySuggestionsOverlay();
      }
    });
  }

  @override
  void dispose() {
    _removeActivitySuggestionsOverlay();
    _activityController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    _activityFocusNode.dispose();
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

  String get _activityName {
    return _activityController.text.trim();
  }

  String get _activityForEstimate {
    final lowerActivity = _activityName.toLowerCase();

    for (final activity in _activities) {
      if (activity.toLowerCase() == lowerActivity) {
        return activity;
      }
    }

    if (lowerActivity.contains('walk')) {
      return 'Walking';
    }

    if (lowerActivity.contains('cycle') ||
        lowerActivity.contains('bike') ||
        lowerActivity.contains('cycling')) {
      return 'Cycling';
    }

    if (lowerActivity.contains('swim')) {
      return 'Swimming';
    }

    if (lowerActivity.contains('row')) {
      return 'Rowing';
    }

    if (lowerActivity.contains('elliptical')) {
      return 'Elliptical';
    }

    if (lowerActivity.contains('stair')) {
      return 'Stair Climber';
    }

    if (lowerActivity.contains('jump')) {
      return 'Jump Rope';
    }

    if (lowerActivity.contains('hike')) {
      return 'Hiking';
    }

    if (lowerActivity.contains('hiit')) {
      return 'HIIT';
    }

    if (lowerActivity.contains('run') ||
        lowerActivity.contains('jog') ||
        lowerActivity.contains('treadmill')) {
      return 'Running';
    }

    return 'Other';
  }

  List<String> _filteredActivitySuggestions() {
    final query = _activityController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    final startsWithMatches = _activities.where((activity) {
      return activity.toLowerCase().startsWith(query);
    }).toList();

    final containsMatches = _activities.where((activity) {
      final lowerActivity = activity.toLowerCase();

      return !startsWithMatches.contains(activity) &&
          lowerActivity.contains(query);
    }).toList();

    return [
      ...startsWithMatches,
      ...containsMatches,
    ].take(8).toList();
  }

  void _refreshActivitySuggestionsOverlay() {
    final suggestions = _filteredActivitySuggestions();

    if (!_activityFocusNode.hasFocus || suggestions.isEmpty) {
      _removeActivitySuggestionsOverlay();
      return;
    }

    if (_activitySuggestionsOverlay == null) {
      _activitySuggestionsOverlay = _createActivitySuggestionsOverlay();
      Overlay.of(context).insert(_activitySuggestionsOverlay!);
    } else {
      _activitySuggestionsOverlay!.markNeedsBuild();
    }
  }

  OverlayEntry _createActivitySuggestionsOverlay() {
    return OverlayEntry(
      builder: (context) {
        final suggestions = _filteredActivitySuggestions();
        final fitzaColors = _colors(context);
        final isDarkMode = _isDark(context);

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          width: MediaQuery.of(context).size.width - 70,
          child: CompositedTransformFollower(
            link: _activityFieldLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 60),
            child: Material(
              color: Colors.transparent,
              elevation: 10,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 190,
                ),
                decoration: BoxDecoration(
                  color: fitzaColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: fitzaColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? const Color(0x66000000)
                          : const Color(0x22000000),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
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
                        _activityController.text = suggestion;
                        _activityController.selection =
                            TextSelection.collapsed(offset: suggestion.length);

                        _removeActivitySuggestionsOverlay();
                        FocusScope.of(context).unfocus();

                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _activityIcon(suggestion),
                              color: cardioOrange,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  color: fitzaColors.primaryText,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
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
            ),
          ),
        );
      },
    );
  }

  void _removeActivitySuggestionsOverlay() {
    _activitySuggestionsOverlay?.remove();
    _activitySuggestionsOverlay = null;
  }

  Future<void> _saveWorkout() async {
    if (_isSaving) {
      return;
    }

    final activityName = _activityName;
    final activityForEstimate = _activityForEstimate;
    final durationText = _durationController.text.trim();
    final distanceText = _distanceController.text.trim();
    final stepsText = _stepsController.text.trim();
    final caloriesText = _caloriesController.text.trim();

    final durationMinutes = int.tryParse(durationText);
    final distanceKm = _parseDouble(distanceText);
    final manualSteps = int.tryParse(stepsText);
    final manualCalories = int.tryParse(caloriesText);

    if (activityName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a cardio activity, like Running.'),
        ),
      );
      return;
    }

    if (durationMinutes == null || durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration.'),
        ),
      );
      return;
    }

    if (distanceText.isNotEmpty && distanceKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid distance.'),
        ),
      );
      return;
    }

    if (stepsText.isNotEmpty && manualSteps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid steps.'),
        ),
      );
      return;
    }

    if (caloriesText.isNotEmpty && manualCalories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid calories.'),
        ),
      );
      return;
    }

    final savedSteps = manualSteps ??
        _estimateSteps(
          activity: activityForEstimate,
          durationMinutes: durationMinutes,
          distanceKm: distanceKm,
        );

    final savedCalories = manualCalories ??
        _estimateCalories(
          activity: activityForEstimate,
          durationMinutes: durationMinutes,
          distanceKm: distanceKm,
        );

    setState(() {
      _isSaving = true;
    });

    try {
      await WorkoutFirestoreService.instance.saveWorkout(
        workoutType: 'Cardio',
        workoutName: activityName,
        duration: '$durationMinutes min',
        notes: _notesController.text.trim(),
        exercises: [
          {
            'name': activityName,
            'sets': '',
            'reps': durationMinutes.toString(),
            'weight': '',
            'distance': distanceKm == null ? '' : _formatNumber(distanceKm),
            'steps': savedSteps?.toString() ?? '',
            'calories': savedCalories.toString(),
          },
        ],
        recordedAt: _selectedDate,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cardio workout saved.'),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error, stackTrace) {
      debugPrint('Could not save cardio workout: $error');
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

  double? _parseDouble(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  int? _estimateSteps({
    required String activity,
    required int durationMinutes,
    required double? distanceKm,
  }) {
    switch (activity) {
      case 'Running':
      case 'Treadmill Run':
        if (distanceKm != null && distanceKm > 0) {
          return (distanceKm * 1250).round();
        }

        return (durationMinutes * 145).round();

      case 'Walking':
      case 'Hiking':
        if (distanceKm != null && distanceKm > 0) {
          return (distanceKm * 1350).round();
        }

        return (durationMinutes * 105).round();

      case 'Stair Climber':
        return (durationMinutes * 90).round();

      case 'Jump Rope':
        return (durationMinutes * 120).round();

      default:
        return null;
    }
  }

  int _estimateCalories({
    required String activity,
    required int durationMinutes,
    required double? distanceKm,
  }) {
    const assumedWeightKg = 75.0;
    final hours = durationMinutes / 60;

    if (distanceKm != null && distanceKm > 0) {
      if (activity == 'Running' || activity == 'Treadmill Run') {
        return (assumedWeightKg * distanceKm).round();
      }

      if (activity == 'Walking' || activity == 'Hiking') {
        return (assumedWeightKg * distanceKm * 0.55).round();
      }

      if (activity == 'Cycling') {
        return (assumedWeightKg * distanceKm * 0.32).round();
      }
    }

    final met = switch (activity) {
      'Running' => 9.8,
      'Treadmill Run' => 9.0,
      'Walking' => 3.8,
      'Cycling' => 7.5,
      'Swimming' => 8.0,
      'Stair Climber' => 8.8,
      'Elliptical' => 5.5,
      'Rowing' => 7.0,
      'Jump Rope' => 11.0,
      'Hiking' => 6.0,
      'HIIT' => 8.5,
      _ => 5.0,
    };

    return (met * assumedWeightKg * hours).round();
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

  IconData _activityIcon(String activity) {
    switch (activity.toLowerCase()) {
      case 'walking':
        return Icons.directions_walk_outlined;
      case 'cycling':
        return Icons.directions_bike_outlined;
      case 'swimming':
        return Icons.pool_outlined;
      case 'treadmill run':
        return Icons.directions_run_rounded;
      case 'stair climber':
        return Icons.stairs_rounded;
      case 'elliptical':
        return Icons.directions_run_outlined;
      case 'rowing':
        return Icons.rowing_outlined;
      case 'jump rope':
        return Icons.sports_handball_outlined;
      case 'hiking':
        return Icons.hiking_outlined;
      case 'hiit':
        return Icons.bolt_rounded;
      case 'other':
        return Icons.favorite_border_rounded;
      default:
        return Icons.directions_run_rounded;
    }
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
                            'Cardio Workout',
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

                    _dateCard(),

                    const SizedBox(height: 14),

                    _cardioDetailsCard(),

                    const SizedBox(height: 14),

                    _notesCard(),

                    const SizedBox(height: 14),

                    _estimateInfoCard(),
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

  Widget _dateCard() {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return _card(
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
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: cardioOrange,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Date',
                    style: TextStyle(
                      color: fitzaColors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formattedDate(),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cardioDetailsCard() {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cardio Details',
                style: TextStyle(
                  color: fitzaColors.secondaryText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              _activitySearchField(),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _smallInput(
                      label: 'Duration',
                      controller: _durationController,
                      hintText: '30',
                      suffix: 'min',
                      icon: Icons.schedule_outlined,
                      requiredLabel: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallInput(
                      label: 'Distance',
                      controller: _distanceController,
                      hintText: '4.5',
                      suffix: 'km',
                      icon: Icons.location_on_outlined,
                      requiredLabel: false,
                      allowDecimal: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _smallInput(
                      label: 'Steps',
                      controller: _stepsController,
                      hintText: '6500',
                      icon: Icons.directions_walk_outlined,
                      requiredLabel: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallInput(
                      label: 'Calories',
                      controller: _caloriesController,
                      hintText: '320',
                      suffix: 'kcal',
                      icon: Icons.local_fire_department_outlined,
                      requiredLabel: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _activitySearchField() {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return CompositedTransformTarget(
          link: _activityFieldLink,
          child: TextField(
            controller: _activityController,
            focusNode: _activityFocusNode,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              setState(() {});
              _refreshActivitySuggestionsOverlay();
            },
            onTap: () {
              if (_activityController.text.trim().isNotEmpty) {
                _refreshActivitySuggestionsOverlay();
              }
            },
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            decoration: _inputDecoration(
              hintText: 'Search or enter cardio',
              prefixIcon: _activityIcon(_activityName),
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

  Widget _estimateInfoCard() {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardioOrange.withValues(
              alpha: _isDark(context) ? 0.16 : 0.10,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: cardioOrange.withValues(
                  alpha: _isDark(context) ? 0.22 : 0.16,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: cardioOrange,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'If steps or calories are empty, Fitza will estimate them from activity, duration and distance.',
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
    bool allowDecimal = false,
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
                  color: cardioOrange,
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
              keyboardType: TextInputType.numberWithOptions(
                decimal: allowDecimal,
              ),
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
            color: cardioOrange.withValues(
              alpha: _isDark(context) ? 0.20 : 0.10,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: cardioOrange,
            size: 24,
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? suffixText,
    IconData? prefixIcon,
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
              color: cardioOrange,
              size: 22,
            ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 42,
        minHeight: 42,
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
        borderSide: const BorderSide(
          color: cardioOrange,
          width: 1.7,
        ),
      ),
    );
  }

  InputDecoration _notesInputDecoration() {
    final fitzaColors = _colors(context);

    return InputDecoration(
      hintText: 'How did the cardio session feel?',
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
        borderSide: const BorderSide(
          color: cardioOrange,
          width: 1.7,
        ),
      ),
    );
  }
}