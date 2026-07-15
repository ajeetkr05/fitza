import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import 'onboarding_targets_screen.dart';

class OnboardingProfileScreen extends StatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  State<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color background = Color(0xFFF5F5F5);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedGoal = 'Lose Weight';
  String _selectedActivity = 'Moderately Active';
  String _selectedGender = 'Prefer not to say';
  String _selectedLocation = 'Home';
  String _selectedWorkoutPreference = 'Both';
  String _selectedDietaryPreference = 'Not set';
  String _selectedFitnessExperience = 'Beginner';

  bool _isSaving = false;

  final List<String> _goalOptions = [
    'Lose Weight',
    'Build Muscle',
    'Improve Fitness',
    'Maintain',
  ];

  final List<String> _activityOptions = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
  ];

  final List<String> _genderOptions = [
    'Prefer not to say',
    'Female',
    'Male',
    'Other',
  ];

  final List<String> _locationOptions = [
    'Home',
    'Gym',
    'Gym & Home',
    'Outdoor',
  ];

  final List<String> _workoutPreferenceOptions = [
    'Gym',
    'Home',
    'Both',
  ];

  final List<String> _dietaryOptions = [
    'Not set',
    'Vegetarian',
    'Non-vegetarian',
    'Vegan',
    'High protein',
  ];

  final List<String> _experienceOptions = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _completeProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingTargetsScreen(
          displayName: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          heightCm: double.parse(_heightController.text.trim()),
          weightKg: _weightController.text.trim().isEmpty
              ? null
              : double.parse(_weightController.text.trim()),
          goal: _selectedGoal,
          activityLevel: _selectedActivity,
          gender: _selectedGender,
          location: _selectedLocation,
          workoutPreference: _selectedWorkoutPreference,
          dietaryPreference: _selectedDietaryPreference,
          fitnessExperience: _selectedFitnessExperience,
        ),
      ),
    );
  }

  void _skipForNow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OnboardingTargetsScreen(
          displayName: 'Fitza User',
          age: 25,
          heightCm: 170.0,
          weightKg: null,
          goal: 'Stay Fit',
          activityLevel: 'Moderate',
          gender: 'Prefer not to say',
          location: 'Home',
          workoutPreference: 'Both',
          dietaryPreference: 'Not set',
          fitnessExperience: 'Beginner',
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await AuthService.instance.signOut();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not sign out. Please try again.'),
        ),
      );
    }
  }

  String? _requiredNumberValidator({
    required String? value,
    required String fieldName,
    required double minimum,
    required double maximum,
  }) {
    final text = value?.trim() ?? '';
    final number = double.tryParse(text);

    if (text.isEmpty) {
      return 'Enter your $fieldName.';
    }

    if (number == null || number < minimum || number > maximum) {
      return 'Enter a valid $fieldName.';
    }

    return null;
  }

  String? _optionalWeightValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final weight = double.tryParse(text);

    if (weight == null || weight < 20 || weight > 300) {
      return 'Enter a valid weight.';
    }

    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFD4DDEA),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _topHeader(),
                const SizedBox(height: 26),
                _heroSection(),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Enter your full name.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Age',
                          icon: Icons.calendar_today_outlined,
                        ),
                        validator: (value) => _requiredNumberValidator(
                          value: value,
                          fieldName: 'age',
                          minimum: 10,
                          maximum: 100,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Height cm',
                          icon: Icons.height_rounded,
                        ),
                        validator: (value) => _requiredNumberValidator(
                          value: value,
                          fieldName: 'height',
                          minimum: 50,
                          maximum: 250,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    label: 'Weight kg optional',
                    icon: Icons.monitor_weight_outlined,
                  ),
                  validator: _optionalWeightValidator,
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'We’ll use this to personalize your plan.',
                    style: TextStyle(
                      color: greyText,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _dropdownField(
                  label: 'Goal',
                  icon: Icons.track_changes_rounded,
                  value: _selectedGoal,
                  options: _goalOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedGoal = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _choiceChips(
                  options: _goalOptions,
                  selectedValue: _selectedGoal,
                  onSelected: (value) {
                    setState(() {
                      _selectedGoal = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _dropdownField(
                  label: 'Activity Level',
                  icon: Icons.directions_run_rounded,
                  value: _selectedActivity,
                  options: _activityOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedActivity = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _choiceChips(
                  options: _activityOptions,
                  selectedValue: _selectedActivity,
                  onSelected: (value) {
                    setState(() {
                      _selectedActivity = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _dropdownField(
                        label: 'Gender optional',
                        icon: Icons.person_outline_rounded,
                        value: _selectedGender,
                        options: _genderOptions,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropdownField(
                        label: 'Location',
                        icon: Icons.home_outlined,
                        value: _selectedLocation,
                        options: _locationOptions,
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _dropdownField(
                  label: 'Workout Preference',
                  icon: Icons.fitness_center_outlined,
                  value: _selectedWorkoutPreference,
                  options: _workoutPreferenceOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedWorkoutPreference = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _choiceChips(
                  options: _workoutPreferenceOptions,
                  selectedValue: _selectedWorkoutPreference,
                  onSelected: (value) {
                    setState(() {
                      _selectedWorkoutPreference = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _dropdownField(
                  label: 'Dietary Preference optional',
                  icon: Icons.eco_outlined,
                  value: _selectedDietaryPreference,
                  options: _dietaryOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedDietaryPreference = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _dropdownField(
                  label: 'Fitness Experience optional',
                  icon: Icons.star_border_rounded,
                  value: _selectedFitnessExperience,
                  options: _experienceOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedFitnessExperience = value;
                    });
                  },
                ),
                const SizedBox(height: 22),
                _privacyNote(),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _completeProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: primaryBlue.withValues(alpha: 0.30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _isSaving ? null : _skipForNow,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        const Icon(
          Icons.bolt_rounded,
          color: primaryBlue,
          size: 42,
        ),
        const SizedBox(width: 8),
        const Text(
          'Fitza',
          style: TextStyle(
            color: darkText,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFD4DDEA),
            ),
          ),
          child: const Row(
            children: [
              Text(
                'Profile setup',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 42,
                child: LinearProgressIndicator(
                  value: 1,
                  minHeight: 5,
                  backgroundColor: Color(0xFFD4DDEA),
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: _isSaving ? null : _signOut,
          icon: const Icon(
            Icons.close_rounded,
            color: darkText,
          ),
        ),
      ],
    );
  }

  Widget _heroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE1E7F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create your profile',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Tell us about yourself so we can personalize your fitness plan.',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            height: 112,
            width: 112,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: primaryBlue,
              size: 70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration(
        label: label,
        icon: icon,
      ),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _isSaving
          ? null
          : (value) {
              if (value == null) {
                return;
              }

              onChanged(value);
            },
    );
  }

  Widget _choiceChips({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = selectedValue == option;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(option),
              selectedColor: const Color(0xFFEAF3FF),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? primaryBlue : const Color(0xFFD4DDEA),
              ),
              labelStyle: TextStyle(
                color: isSelected ? primaryBlue : darkText,
                fontWeight: FontWeight.w600,
              ),
              onSelected: _isSaving
                  ? null
                  : (_) {
                      onSelected(option);
                    },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _privacyNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEAF3FF),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: primaryBlue,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Your information is private and secure. You can update it anytime in Profile.',
            style: TextStyle(
              color: greyText,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}