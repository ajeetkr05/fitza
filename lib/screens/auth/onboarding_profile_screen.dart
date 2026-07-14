import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../../widgets/fitza_header.dart';
import 'auth_gate.dart';
import 'onboarding_targets_screen.dart';

class OnboardingProfileScreen extends StatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  State<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen> {
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

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

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

    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingTargetsScreen(
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

  Future<void> _skipForNow() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      await ProfileFirestoreService.instance.skipProfileSetup();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not skip profile setup. Please try again.',
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

  String? _nameValidator(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Enter your full name.';
    }

    if (name.length < 2) {
      return 'Enter a valid name.';
    }

    return null;
  }

  String? _ageValidator(String? value) {
    final text = value?.trim() ?? '';
    final age = int.tryParse(text);

    if (text.isEmpty) {
      return 'Enter your age.';
    }

    if (age == null || age < 10 || age > 100) {
      return 'Enter a valid age.';
    }

    return null;
  }

  String? _heightValidator(String? value) {
    final text = value?.trim() ?? '';
    final height = double.tryParse(text);

    if (text.isEmpty) {
      return 'Enter your height.';
    }

    if (height == null || height < 50 || height > 250) {
      return 'Enter a valid height.';
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
    final fitzaColors = _colors(context);

    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: fitzaColors.primaryBlue,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Icon(
        icon,
        color: fitzaColors.secondaryText,
        size: 21,
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 46,
        minHeight: 46,
      ),
      filled: true,
      fillColor: fitzaColors.inputSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: fitzaColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: fitzaColors.primaryBlue,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitzaColors = _colors(context);
    final isDarkMode = _isDark(context);

    return Scaffold(
      backgroundColor: fitzaColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FitzaHeader(
                      trailing: _OnboardingStepBadge(),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Create your profile',
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Tell us about yourself so we can personalise your fitness plan.',
                      style: TextStyle(
                        color: fitzaColors.secondaryText,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [
                        AutofillHints.name,
                      ],
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        label: 'Full name',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: _nameValidator,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              color: fitzaColors.primaryText,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration(
                              label: 'Age',
                              icon: Icons.calendar_today_outlined,
                            ),
                            validator: _ageValidator,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            enabled: !_isSaving,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              color: fitzaColors.primaryText,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration(
                              label: 'Height (cm)',
                              icon: Icons.height_rounded,
                            ),
                            validator: _heightValidator,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _weightController,
                      enabled: !_isSaving,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        label: 'Weight (kg) — optional',
                        icon: Icons.monitor_weight_outlined,
                      ),
                      validator: _optionalWeightValidator,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Weight helps us calculate your starting BMI.',
                      style: TextStyle(
                        color: fitzaColors.secondaryText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _sectionTitle('Fitness goal'),

                    const SizedBox(height: 9),

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

                    _sectionTitle('Activity level'),

                    const SizedBox(height: 9),

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _dropdownField(
                            label: 'Gender (optional)',
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
                            icon: Icons.location_on_outlined,
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

                    _sectionTitle('Workout preference'),

                    const SizedBox(height: 9),

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
                      label: 'Dietary preference (optional)',
                      icon: Icons.eco_outlined,
                      value: _selectedDietaryPreference,
                      options: _dietaryOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedDietaryPreference = value;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    _dropdownField(
                      label: 'Fitness experience (optional)',
                      icon: Icons.star_border_rounded,
                      value: _selectedFitnessExperience,
                      options: _experienceOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedFitnessExperience = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    _privacyNote(),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _isSaving ? null : _completeProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              fitzaColors.primaryBlue,
                          foregroundColor:
                              fitzaColors.textOnBlue,
                          elevation: isDarkMode ? 0 : 3,
                          shadowColor:
                              fitzaColors.primaryBlue.withValues(
                            alpha: 0.22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            color: fitzaColors.textOnBlue,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: TextButton(
                        onPressed:
                            _isSaving ? null : _skipForNow,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: _isSaving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color:
                                      fitzaColors.primaryBlue,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(
                                'Skip for now',
                                style: TextStyle(
                                  color:
                                      fitzaColors.primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final fitzaColors = _colors(context);

    return Text(
      title,
      style: TextStyle(
        color: fitzaColors.primaryText,
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.1,
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
    final fitzaColors = _colors(context);
    final isDarkMode = _isDark(context);

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: fitzaColors.surface,
      borderRadius: BorderRadius.circular(15),
      menuMaxHeight: 300,
      itemHeight: 48,
      elevation: isDarkMode ? 2 : 6,
      focusColor: Colors.transparent,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 24,
      ),
      iconEnabledColor: fitzaColors.secondaryText,
      iconDisabledColor: fitzaColors.disabled,
      style: TextStyle(
        color: fitzaColors.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(
        label: label,
        icon: icon,
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(
            option,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
      onChanged: _isSaving
          ? null
          : (selectedValue) {
              if (selectedValue != null) {
                onChanged(selectedValue);
              }
            },
    );
  }

  Widget _choiceChips({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    final fitzaColors = _colors(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;

        return ChoiceChip(
          selected: isSelected,
          showCheckmark: false,
          label: Text(option),
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 5,
          ),
          labelPadding: const EdgeInsets.symmetric(
            horizontal: 3,
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
          selectedColor:
              fitzaColors.primaryBlue.withValues(alpha: 0.12),
          backgroundColor: fitzaColors.surface,
          side: BorderSide(
            color: isSelected
                ? fitzaColors.primaryBlue
                : fitzaColors.border,
            width: isSelected ? 1.4 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: TextStyle(
            color: isSelected
                ? fitzaColors.primaryBlue
                : fitzaColors.primaryText,
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
          onSelected: _isSaving
              ? null
              : (_) {
                  onSelected(option);
                },
        );
      }).toList(),
    );
  }

  Widget _privacyNote() {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fitzaColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: fitzaColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fitzaColors.primaryBlue.withValues(
                alpha: 0.12,
              ),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: fitzaColors.primaryBlue,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Your information is private and can be updated later from Profile.',
              style: TextStyle(
                color: fitzaColors.secondaryText,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepBadge extends StatelessWidget {
  const _OnboardingStepBadge();

  @override
  Widget build(BuildContext context) {
    final fitzaColors =
        Theme.of(context).extension<FitzaThemeColors>()!;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fitzaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fitzaColors.border,
        ),
      ),
      child: Text(
        '1 of 2',
        style: TextStyle(
          color: fitzaColors.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}