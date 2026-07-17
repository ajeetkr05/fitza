import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../../widgets/fitza_header.dart';
import 'auth_gate.dart';

class OnboardingTargetsScreen extends StatefulWidget {
  final String displayName;
  final int age;
  final double heightCm;
  final double? weightKg;
  final String goal;
  final String activityLevel;
  final String gender;
  final String location;
  final String workoutPreference;
  final String dietaryPreference;
  final String fitnessExperience;

  const OnboardingTargetsScreen({
    super.key,
    required this.displayName,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activityLevel,
    required this.gender,
    required this.location,
    required this.workoutPreference,
    required this.dietaryPreference,
    required this.fitnessExperience,
  });

  @override
  State<OnboardingTargetsScreen> createState() =>
      _OnboardingTargetsScreenState();
}

class _OnboardingTargetsScreenState
    extends State<OnboardingTargetsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _waterController;

  bool _isSaving = false;

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void initState() {
    super.initState();

    _caloriesController = TextEditingController(text: '2200');
    _proteinController = TextEditingController(text: '120');
    _carbsController = TextEditingController(text: '275');
    _fatController = TextEditingController(text: '73');
    _waterController = TextEditingController(text: '3000');
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  String? _numberValidator({
    required String? value,
    required String fieldName,
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter your $fieldName target.';
    }

    final number = double.tryParse(text);

    if (number == null || number < 0) {
      return 'Enter a valid $fieldName target.';
    }

    return null;
  }

  String? _waterValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter your water target.';
    }

    final water = int.tryParse(text);

    if (water == null || water < 0) {
      return 'Enter a valid water target.';
    }

    return null;
  }

  Future<void> _saveTargets({
    required bool useDefaultValues,
  }) async {
    FocusScope.of(context).unfocus();

    if (!useDefaultValues &&
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final calories = useDefaultValues
          ? 2200.0
          : double.parse(
              _caloriesController.text.trim(),
            );

      final protein = useDefaultValues
          ? 120.0
          : double.parse(
              _proteinController.text.trim(),
            );

      final carbs = useDefaultValues
          ? 275.0
          : double.parse(
              _carbsController.text.trim(),
            );

      final fat = useDefaultValues
          ? 73.0
          : double.parse(
              _fatController.text.trim(),
            );

      final water = useDefaultValues
          ? 3000
          : int.parse(
              _waterController.text.trim(),
            );

      await ProfileFirestoreService.instance.saveOnboardingProfile(
        displayName: widget.displayName,
        age: widget.age,
        heightCm: widget.heightCm,
        weightKg: widget.weightKg,
        goal: widget.goal,
        activityLevel: widget.activityLevel,
        gender: widget.gender,
        location: widget.location,
        workoutPreference: widget.workoutPreference,
        dietaryPreference: widget.dietaryPreference,
        fitnessExperience: widget.fitnessExperience,
        targetCalories: calories,
        targetProtein: protein,
        targetCarbs: carbs,
        targetFat: fat,
        targetWaterMl: water,
      );

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
            'Could not save your targets. Please try again.',
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

  InputDecoration _inputDecoration({
    required IconData icon,
  }) {
    final fitzaColors = _colors(context);

    return InputDecoration(
      isDense: true,
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

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
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
              padding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FitzaHeader(
                      trailing: _OnboardingTargetsStepBadge(),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Set your nutrition targets',
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Choose your daily calorie, macronutrient and water targets.',
                      style: TextStyle(
                        color: fitzaColors.secondaryText,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _targetField(
                      controller: _caloriesController,
                      label: 'Calories (kcal)',
                      icon: Icons.local_fire_department_outlined,
                      inputAction: TextInputAction.next,
                      validator: (value) => _numberValidator(
                        value: value,
                        fieldName: 'calorie',
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _targetField(
                            controller: _proteinController,
                            label: 'Protein (g)',
                            icon: Icons.fitness_center_outlined,
                            inputAction: TextInputAction.next,
                            validator: (value) => _numberValidator(
                              value: value,
                              fieldName: 'protein',
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _targetField(
                            controller: _carbsController,
                            label: 'Carbs (g)',
                            icon: Icons.grain_outlined,
                            inputAction: TextInputAction.next,
                            validator: (value) => _numberValidator(
                              value: value,
                              fieldName: 'carbohydrate',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _targetField(
                            controller: _fatController,
                            label: 'Fat (g)',
                            icon: Icons.opacity_outlined,
                            inputAction: TextInputAction.next,
                            validator: (value) => _numberValidator(
                              value: value,
                              fieldName: 'fat',
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _targetField(
                            controller: _waterController,
                            label: 'Water (ml)',
                            icon: Icons.water_drop_outlined,
                            allowDecimal: false,
                            inputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_isSaving) {
                                _saveTargets(
                                  useDefaultValues: false,
                                );
                              }
                            },
                            validator: _waterValidator,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _recommendationNote(),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                _saveTargets(
                                  useDefaultValues: false,
                                );
                              },
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
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      fitzaColors.textOnBlue,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                'Save & Continue',
                                style: TextStyle(
                                  color:
                                      fitzaColors.textOnBlue,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: TextButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                _saveTargets(
                                  useDefaultValues: true,
                                );
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Use recommended values',
                          style: TextStyle(
                            color: fitzaColors.primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              fitzaColors.secondaryText,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: fitzaColors.secondaryText,
                          size: 18,
                        ),
                        label: Text(
                          'Back to profile',
                          style: TextStyle(
                            color: fitzaColors.secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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

  Widget _targetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputAction inputAction,
    required String? Function(String?) validator,
    bool allowDecimal = true,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    final fitzaColors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 6,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fitzaColors.secondaryText,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: !_isSaving,
          onTap: () {
            Future.delayed(const Duration(milliseconds: 80), () {
              if (!mounted) {
                return;
              }

              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            });
          },
          keyboardType: TextInputType.numberWithOptions(
            decimal: allowDecimal,
          ),
          textInputAction: inputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            color: fitzaColors.primaryText,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(
            icon: icon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _recommendationNote() {
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
              Icons.auto_awesome_outlined,
              color: fitzaColors.primaryBlue,
              size: 18,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'These starting values can be changed later from Nutrition settings.',
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

class _OnboardingTargetsStepBadge extends StatelessWidget {
  const _OnboardingTargetsStepBadge();

  @override
  Widget build(BuildContext context) {
    final fitzaColors =
        Theme.of(context).extension<FitzaThemeColors>()!;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fitzaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fitzaColors.border,
        ),
      ),
      child: Text(
        '2 of 2',
        style: TextStyle(
          color: fitzaColors.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}