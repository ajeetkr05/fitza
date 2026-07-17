import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/workout/plan_customization.dart';

/// "Customize Plan" (screen 7). Pushed from WorkoutHomeScreen's
/// "Customize Plan" button. Returns a PlanCustomization via Navigator.pop
/// when the user saves - WorkoutHomeScreen applies it to regenerate
/// today's recommendation. Nothing here is persisted to UserProfile;
/// it's session-only, matching the wireframe's "apply changes to today's
/// plan" framing (not permanent profile settings).
class CustomizePlanScreen extends StatefulWidget {
  final PlanCustomization? initialCustomization;

  const CustomizePlanScreen({super.key, this.initialCustomization});

  @override
  State<CustomizePlanScreen> createState() => _CustomizePlanScreenState();
}

class _CustomizePlanScreenState extends State<CustomizePlanScreen> {
  FitzaThemeColors get _colors => Theme.of(context).extension<FitzaThemeColors>()!;
  Color get primaryBlue => _colors.primaryBlue;
  Color get darkText => _colors.primaryText;
  Color get greyText => _colors.secondaryText;
  Color get background => _colors.background;
  Color get surface => _colors.surface;

  static const _durationOptions = {'Short': 4, 'Medium': 6, 'Long': 8};
  static const _difficultyOptions = ['Beginner', 'Intermediate', 'Advanced'];
  static const _locationOptions = ['Gym', 'Home', 'Both'];
  static const _muscleFocusOptions = [
    'Auto (recommended)',
    'Full Body',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Core',
    'Arms',
  ];

  late String _selectedDurationLabel;
  late String _selectedDifficulty;
  late String _selectedLocation;
  late String _selectedMuscleFocus;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCustomization;

    _selectedDurationLabel = _durationOptions.entries
        .firstWhere(
          (entry) => entry.value == initial?.exerciseCount,
          orElse: () => const MapEntry('Medium', 6),
        )
        .key;
    _selectedDifficulty = initial?.difficulty ?? 'Intermediate';
    _selectedLocation = initial?.workoutPreference ?? 'Both';
    _selectedMuscleFocus = initial?.targetMuscleGroup ?? 'Auto (recommended)';
  }

  void _savePreferences() {
    final customization = PlanCustomization(
      exerciseCount: _durationOptions[_selectedDurationLabel],
      difficulty: _selectedDifficulty,
      workoutPreference: _selectedLocation,
      targetMuscleGroup:
          _selectedMuscleFocus == 'Auto (recommended)' ? null : _selectedMuscleFocus,
    );
    Navigator.pop(context, customization);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 24),
              _dropdownCard(
                context,
                label: 'Workout Duration',
                value: _selectedDurationLabel,
                options: _durationOptions.keys.toList(),
                onChanged: (value) => setState(() => _selectedDurationLabel = value),
              ),
              const SizedBox(height: 16),
              _dropdownCard(
                context,
                label: 'Difficulty',
                value: _selectedDifficulty,
                options: _difficultyOptions,
                onChanged: (value) => setState(() => _selectedDifficulty = value),
              ),
              const SizedBox(height: 16),
              _dropdownCard(
                context,
                label: 'Workout Location',
                value: _selectedLocation,
                options: _locationOptions,
                onChanged: (value) => setState(() => _selectedLocation = value),
              ),
              const SizedBox(height: 16),
              _dropdownCard(
                context,
                label: 'Target Muscle Focus',
                value: _selectedMuscleFocus,
                options: _muscleFocusOptions,
                onChanged: (value) => setState(() => _selectedMuscleFocus = value),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
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
          icon: Icon(Icons.arrow_back_rounded, color: primaryBlue, size: 28),
        ),
        Expanded(
          child: Text(
            'Customize Plan',
            textAlign: TextAlign.center,
            style: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _dropdownCard(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: greyText, fontSize: 15)),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            dropdownColor: surface,
            style: TextStyle(color: darkText, fontSize: 15, fontWeight: FontWeight.w600),
            items: options
                .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                .toList(),
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }
}
