import 'package:flutter/material.dart';
import '../../services/profile/profile_firestore_service.dart';
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
  State<OnboardingTargetsScreen> createState() => _OnboardingTargetsScreenState();
}

class _OnboardingTargetsScreenState extends State<OnboardingTargetsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _waterController;

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color background = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    // Pre-fill with standard app values
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

  String? _nonNegativeValidator(String? value, String fieldName) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter $fieldName target';
    }
    final numVal = double.tryParse(text);
    if (numVal == null || numVal < 0) {
      return '$fieldName must be 0 or greater';
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD4DDEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Future<void> _saveTargets({bool useDefault = false}) async {
    if (!useDefault && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final calories = useDefault ? 2200.0 : double.parse(_caloriesController.text.trim());
      final protein = useDefault ? 120.0 : double.parse(_proteinController.text.trim());
      final carbs = useDefault ? 275.0 : double.parse(_carbsController.text.trim());
      final fat = useDefault ? 73.0 : double.parse(_fatController.text.trim());
      final water = useDefault ? 3000 : int.parse(_waterController.text.trim());

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

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save targets: $e')),
        );
      }
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
                  controller: _caloriesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Calorie Target (kcal)',
                    icon: Icons.local_fire_department_outlined,
                  ),
                  validator: (value) => _nonNegativeValidator(value, 'calories'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _proteinController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Protein Target (g)',
                    icon: Icons.fitness_center_outlined,
                  ),
                  validator: (value) => _nonNegativeValidator(value, 'protein'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _carbsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Carbohydrate Target (g)',
                    icon: Icons.grain_outlined,
                  ),
                  validator: (value) => _nonNegativeValidator(value, 'carbs'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fatController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Fat Target (g)',
                    icon: Icons.opacity_outlined,
                  ),
                  validator: (value) => _nonNegativeValidator(value, 'fat'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _waterController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    label: 'Water Intake Target (ml)',
                    icon: Icons.water_drop_outlined,
                  ),
                  validator: (value) => _nonNegativeValidator(value, 'water'),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _saveTargets(useDefault: false),
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
                            'Save & Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _isSaving ? null : () => _saveTargets(useDefault: true),
                  child: const Text(
                    'Skip with default values',
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD4DDEA)),
          ),
          child: const Row(
            children: [
              Text(
                'Targets',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 42,
                child: LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 5,
                  backgroundColor: Color(0xFFD4DDEA),
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Set Your Nutrition Targets',
            style: TextStyle(
              color: darkText,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Customize your daily calorie, macronutrient, and water targets or skip to use our recommendations.',
          style: TextStyle(
            color: greyText,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
