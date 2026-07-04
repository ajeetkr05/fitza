import 'package:flutter/material.dart';

import 'bmi_preview_screen.dart';

class SetHeightScreen extends StatefulWidget {
  final double weight;
  final String notes;
  final DateTime selectedDate;

  const SetHeightScreen({
    super.key,
    required this.weight,
    required this.notes,
    required this.selectedDate,
  });

  @override
  State<SetHeightScreen> createState() => _SetHeightScreenState();
}

class _SetHeightScreenState extends State<SetHeightScreen> {
  final TextEditingController _heightController = TextEditingController();

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  void _saveHeight() {
    final height = double.tryParse(_heightController.text.trim());

    if (height == null || height < 50 || height > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid height between 50 cm and 250 cm.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BmiPreviewScreen(
          weight: widget.weight,
          height: height,
          notes: widget.notes,
          selectedDate: widget.selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: darkText,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Set Your Height',
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

              const SizedBox(height: 54),

              Container(
                height: 190,
                width: 190,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.height_rounded,
                  size: 105,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 44),

              const Text(
                'One quick detail',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkText,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Your height helps Fitza calculate\nyour BMI accurately.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: greyText,
                  fontSize: 19,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 52),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Height',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 24,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter height',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9AA4B5),
                          fontSize: 24,
                        ),
                        suffixText: 'cm',
                        suffixStyle: const TextStyle(
                          color: primaryBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 22,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'e.g. 175 cm',
                      style: TextStyle(
                        color: greyText,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _saveHeight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Height and Continue',
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
}