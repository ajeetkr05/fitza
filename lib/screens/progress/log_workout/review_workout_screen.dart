import 'package:flutter/material.dart';

import '../../../services/progress/workout_firestore_service.dart';
import 'workout_saved_screen.dart';

class ReviewWorkoutScreen extends StatefulWidget {
  final List<Map<String, String>> exercises;
  final String notes;
  final String workoutType;
  final String duration;

  const ReviewWorkoutScreen({
    super.key,
    required this.exercises,
    required this.notes,
    required this.workoutType,
    required this.duration,
  });

  @override
  State<ReviewWorkoutScreen> createState() => _ReviewWorkoutScreenState();
}

class _ReviewWorkoutScreenState extends State<ReviewWorkoutScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);

  bool _isSaving = false;

  bool get _isGym => widget.workoutType == 'Gym';

  Future<void> _saveWorkout() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await WorkoutFirestoreService.instance.saveWorkout(
        workoutType: widget.workoutType,
        duration: widget.duration,
        notes: widget.notes,
        exercises: widget.exercises,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSavedScreen(
            exerciseCount: widget.exercises.length,
            workoutType: widget.workoutType,
            duration: widget.duration,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save workout: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save workout. Please check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: darkText,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Review Workout',
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
              const SizedBox(height: 24),
              _summaryCard(),
              const SizedBox(height: 28),
              Text(
                _isGym ? 'Exercises' : 'Workout Details',
                style: const TextStyle(
                  color: darkText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ...widget.exercises.map(_exerciseCard),
              const SizedBox(height: 24),
              const Text(
                'Notes',
                style: TextStyle(
                  color: darkText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _notesCard(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: const BorderSide(color: primaryBlue, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Edit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Saving Workout...',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Save Workout',
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

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _summaryRow(
            icon: _workoutIcon(),
            title: 'Workout Type',
            value: widget.workoutType,
          ),
          const Divider(height: 34),
          _summaryRow(
            icon: Icons.calendar_month_outlined,
            title: 'Date',
            value: 'Today',
          ),
          const Divider(height: 34),
          _summaryRow(
            icon: Icons.schedule_outlined,
            title: 'Duration',
            value: widget.duration,
          ),
        ],
      ),
    );
  }

  IconData _workoutIcon() {
    switch (widget.workoutType) {
      case 'Yoga':
        return Icons.self_improvement_outlined;
      case 'Calisthenics':
        return Icons.accessibility_new_rounded;
      case 'Cardio':
        return Icons.monitor_heart_outlined;
      default:
        return Icons.fitness_center_outlined;
    }
  }

  Widget _summaryRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: primaryBlue, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: greyText,
              fontSize: 18,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: darkText,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _cardioDetails(Map<String, String> exercise) {
    final parts = <String>[];

    if ((exercise['reps'] ?? '').isNotEmpty) {
      parts.add('${exercise['reps']} min');
    }

    if ((exercise['distance'] ?? '').isNotEmpty) {
      parts.add('${exercise['distance']} km');
    }

    if ((exercise['steps'] ?? '').isNotEmpty) {
      parts.add('${exercise['steps']} steps');
    }

    if ((exercise['calories'] ?? '').isNotEmpty) {
      parts.add('${exercise['calories']} kcal');
    }

    return parts.join(' • ');
  }

  Widget _exerciseCard(Map<String, String> exercise) {
    final name = exercise['name'] ?? 'Workout';
    final sets = exercise['sets'] ?? '';
    final reps = exercise['reps'] ?? '';
    final weight = exercise['weight'] ?? '';

    final detailText = _isGym
        ? '$weight kg × $reps reps × $sets sets'
        : widget.workoutType == 'Cardio'
            ? _cardioDetails(exercise)
            : sets.isEmpty || sets == '—'
                ? '$reps min • ${exercise['difficulty'] ?? 'Easy'}'
                : '$reps min • $sets sets • ${exercise['difficulty'] ?? 'Easy'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _workoutIcon(),
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
                    name,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detailText,
                    style: const TextStyle(
                      color: greyText,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              color: primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _notesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.edit_note_outlined,
              color: primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.notes.trim().isEmpty
                  ? 'No notes added.'
                  : widget.notes,
              style: const TextStyle(
                color: darkText,
                fontSize: 18,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}