import 'dart:async';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/workout/daily_recommendation.dart';
import 'workout_summary_screen.dart';

/// "Active Workout" (screen 5). Pushed from WorkoutDetailsScreen's
/// "Start Workout" button. Walks through each ExercisePrescription one at
/// a time with a manually-started rest timer between exercises (per your
/// choice - no auto-start).
class ActiveWorkoutScreen extends StatefulWidget {
  final DailyRecommendation recommendation;

  const ActiveWorkoutScreen({super.key, required this.recommendation});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  FitzaThemeColors get _colors => Theme.of(context).extension<FitzaThemeColors>()!;
  Color get primaryBlue => _colors.primaryBlue;
  Color get darkText => _colors.primaryText;
  Color get greyText => _colors.secondaryText;
  Color get background => _colors.background;
  Color get surface => _colors.surface;

  int _currentIndex = 0;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  final Stopwatch _workoutStopwatch = Stopwatch();

  List<ExercisePrescription> get _exercises => widget.recommendation.exercises;
  ExercisePrescription get _current => _exercises[_currentIndex];
  bool get _isLastExercise => _currentIndex == _exercises.length - 1;

  @override
  void initState() {
    super.initState();
    _workoutStopwatch.start();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
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
                style: TextStyle(color: greyText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Expanded(child: _isResting ? _restView() : _exerciseView()),
              const SizedBox(height: 16),
              _navigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: primaryBlue, size: 26),
        ),
        Expanded(
          child: Text(
            widget.recommendation.title,
            textAlign: TextAlign.center,
            style: TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _exerciseView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _current.exercise.name,
            textAlign: TextAlign.center,
            style: TextStyle(color: darkText, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_current.sets} sets  •  ${_current.repsMin}-${_current.repsMax} reps',
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _current.exercise.instructions,
            textAlign: TextAlign.center,
            style: TextStyle(color: greyText, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _startRest,
            icon: Icon(Icons.timer_outlined, color: primaryBlue),
            label: Text('Start Rest', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Resting', style: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(
            '$_restSecondsRemaining',
            style: TextStyle(color: primaryBlue, fontSize: 56, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'seconds remaining',
            style: TextStyle(color: greyText, fontSize: 14),
          ),
          const SizedBox(height: 28),
          Text(
            _isLastExercise ? 'Almost done!' : 'Next: ${_exercises[_currentIndex + 1].exercise.name}',
            style: TextStyle(color: greyText, fontSize: 15),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _skipRest,
            child: Text('Skip Rest', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _navigationButtons() {
    return Row(
      children: [
        if (_currentIndex > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _goToPrevious,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Previous', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
            ),
          ),
        if (_currentIndex > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _goToNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 5)),
      ],
    );
  }
}
