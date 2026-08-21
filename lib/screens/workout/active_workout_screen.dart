import 'dart:async';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/workout/daily_recommendation.dart';
import '../../models/workout/exercise_performance.dart';
import 'workout_summary_screen.dart';

/// "Active Workout" (screen 5). Pushed from WorkoutDetailsScreen's
/// "Start Workout" button. Walks through each ExercisePrescription one at
/// a time with a manually-started rest timer between exercises.
///
/// PERFORMANCE TRACKING: captures what the user actually did (sets/reps/
/// weight) via _performance, defaulted from the prescription but fully
/// editable - see ExercisePerformance for why this matters.
class ActiveWorkoutScreen extends StatefulWidget {
  final DailyRecommendation recommendation;

  const ActiveWorkoutScreen({super.key, required this.recommendation});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _currentIndex = 0;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  final Stopwatch _workoutStopwatch = Stopwatch();

  late final List<ExercisePerformance> _performance;
  late final List<TextEditingController> _weightControllers;

  List<ExercisePrescription> get _exercises => widget.recommendation.exercises;
  ExercisePrescription get _current => _exercises[_currentIndex];
  ExercisePerformance get _currentPerformance => _performance[_currentIndex];
  bool get _isLastExercise => _currentIndex == _exercises.length - 1;
  bool get _needsWeight => _current.exercise.equipmentTags.isNotEmpty;

  FitzaThemeColors _colors(BuildContext context) => Theme.of(context).extension<FitzaThemeColors>()!;
  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _workoutStopwatch.start();
    _performance = _exercises
        .map((p) => ExercisePerformance.fromPrescriptionDefaults(p))
        .toList();
    _weightControllers = _performance
        .map((perf) => TextEditingController(text: perf.weightKg?.toString() ?? ''))
        .toList();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = _current.restSeconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _isResting = false;
          _restSecondsRemaining = 0;
        });
      } else {
        setState(() => _restSecondsRemaining--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  void _adjustSets(int delta) {
    setState(() {
      _currentPerformance.setsCompleted =
          (_currentPerformance.setsCompleted + delta).clamp(0, 20);
    });
  }

  void _adjustReps(int delta) {
    setState(() {
      _currentPerformance.repsCompleted =
          (_currentPerformance.repsCompleted + delta).clamp(0, 100);
    });
  }

  void _saveWeightInput(String value) {
    _currentPerformance.weightKg = double.tryParse(value.trim());
  }

  void _goToNext() {
    if (_isLastExercise) {
      _finishWorkout();
      return;
    }
    _restTimer?.cancel();
    setState(() {
      _currentIndex++;
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  void _goToPrevious() {
    if (_currentIndex == 0) return;
    _restTimer?.cancel();
    setState(() {
      _currentIndex--;
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  void _finishWorkout() {
    _workoutStopwatch.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          recommendation: widget.recommendation,
          actualDuration: _workoutStopwatch.elapsed,
          performance: _performance,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 8),
              Text(
                'Exercise ${_currentIndex + 1} of ${_exercises.length}',
                style: TextStyle(color: colors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: _isResting ? _restView(context) : _exerciseView(context),
                ),
              ),
              const SizedBox(height: 16),
              _navigationButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final colors = _colors(context);
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: colors.primaryBlue, size: 26),
        ),
        Expanded(
          child: Text(
            widget.recommendation.title,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _exerciseView(BuildContext context) {
    final colors = _colors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Text(
            _current.exercise.name,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.primaryText, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colors.primaryBlue.withValues(alpha: _isDark(context) ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Target: ${_current.sets} sets  •  ${_current.repsMin}-${_current.repsMax} reps',
              style: TextStyle(color: colors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _current.exercise.instructions,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.secondaryText, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 24),
          _logYourSetCard(context),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _startRest,
            icon: Icon(Icons.timer_outlined, color: colors.primaryBlue),
            label: Text('Start Rest', style: TextStyle(color: colors.primaryBlue, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logYourSetCard(BuildContext context) {
    final colors = _colors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.inputSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            'Log what you actually did',
            style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _stepperField(context, 'Sets', _currentPerformance.setsCompleted, _adjustSets)),
              const SizedBox(width: 12),
              Expanded(child: _stepperField(context, 'Reps', _currentPerformance.repsCompleted, _adjustReps)),
            ],
          ),
          if (_needsWeight) ...[
            const SizedBox(height: 14),
            TextField(
              key: ValueKey('weight_$_currentIndex'),
              controller: _weightControllers[_currentIndex],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: _saveWeightInput,
              style: TextStyle(color: colors.primaryText),
              decoration: InputDecoration(
                labelText: 'Weight used (kg)',
                labelStyle: TextStyle(color: colors.secondaryText),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primaryBlue, width: 1.7),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepperField(BuildContext context, String label, int value, void Function(int) onAdjust) {
    final colors = _colors(context);
    return Column(
      children: [
        Text(label, style: TextStyle(color: colors.secondaryText, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => onAdjust(-1),
                icon: Icon(Icons.remove_rounded, color: colors.primaryBlue, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                visualDensity: VisualDensity.compact,
              ),
              Text('$value', style: TextStyle(color: colors.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => onAdjust(1),
                icon: Icon(Icons.add_rounded, color: colors.primaryBlue, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _restView(BuildContext context) {
    final colors = _colors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Resting', style: TextStyle(color: colors.primaryText, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(
            '$_restSecondsRemaining',
            style: TextStyle(color: colors.primaryBlue, fontSize: 56, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('seconds remaining', style: TextStyle(color: colors.secondaryText, fontSize: 14)),
          const SizedBox(height: 28),
          Text(
            _isLastExercise ? 'Almost done!' : 'Next: ${_exercises[_currentIndex + 1].exercise.name}',
            style: TextStyle(color: colors.secondaryText, fontSize: 15),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _skipRest,
            child: Text('Skip Rest', style: TextStyle(color: colors.primaryBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _navigationButtons(BuildContext context) {
    final colors = _colors(context);
    return Row(
      children: [
        if (_currentIndex > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _goToPrevious,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Previous', style: TextStyle(color: colors.primaryBlue, fontWeight: FontWeight.w600)),
            ),
          ),
        if (_currentIndex > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _goToNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryBlue,
              foregroundColor: colors.textOnBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _isLastExercise ? 'Finish Workout' : 'Next',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final colors = _colors(context);
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: _isDark(context) ? const Color(0x33000000) : const Color(0x0F000000),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
