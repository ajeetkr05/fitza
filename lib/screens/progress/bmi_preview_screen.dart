import 'package:flutter/material.dart';

class BmiPreviewScreen extends StatelessWidget {
  final double weight;
  final double height;
  final String notes;
  final DateTime selectedDate;

  const BmiPreviewScreen({
    super.key,
    required this.weight,
    required this.height,
    required this.notes,
    required this.selectedDate,
  });

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color successGreen = Color(0xFF2E7D32);

  double get bmi {
    final heightInMetres = height / 100;
    return weight / (heightInMetres * heightInMetres);
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Below standard range';
    if (bmi < 25) return 'Within standard range';
    if (bmi < 30) return 'Above standard range';
    return 'High range';
  }

  Color get bmiColor {
    if (bmi >= 18.5 && bmi < 25) {
      return successGreen;
    }
    return Colors.orange;
  }

  String get bmiMessage {
    if (bmi >= 18.5 && bmi < 25) {
      return 'Your BMI is within the healthy range.';
    }
    return 'BMI is only one general indicator of health.';
  }

  void _saveWeight(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weight will be saved in the next screen.'),
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
                      'BMI Preview',
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

              const SizedBox(height: 34),

              Container(
                height: 165,
                width: 165,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(42),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: primaryBlue,
                  size: 92,
                ),
              ),

              const SizedBox(height: 36),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                  children: [
                    _infoRow(
                      icon: Icons.monitor_weight_outlined,
                      title: 'Current Weight',
                      value: '${weight.toStringAsFixed(1)} kg',
                    ),
                    const Divider(height: 34),
                    _infoRow(
                      icon: Icons.height_rounded,
                      title: 'Height',
                      value: '${height.toStringAsFixed(0)} cm',
                    ),
                    const Divider(height: 34),
                    _infoRow(
                      icon: Icons.calculate_outlined,
                      title: 'Calculated BMI',
                      value: bmi.toStringAsFixed(1),
                    ),
                    const Divider(height: 34),
                    _infoRow(
                      icon: Icons.favorite_border_rounded,
                      title: 'BMI Category',
                      value: bmiCategory,
                      valueColor: bmiColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 38),

              CircleAvatar(
                radius: 46,
                backgroundColor: bmiColor.withValues(alpha: 0.14),
                child: Icon(
                  Icons.check_rounded,
                  color: bmiColor,
                  size: 56,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                bmiMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: bmiColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 34),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _saveWeight(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Weight',
                    style: TextStyle(
                      fontSize: 21,
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

Widget _infoRow({
  required IconData icon,
  required String title,
  required String value,
  Color valueColor = darkText,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: primaryBlue,
          size: 28,
        ),
      ),
      const SizedBox(width: 16),

      SizedBox(
        width: 135,
        child: Text(
          title,
          style: const TextStyle(
            color: greyText,
            fontSize: 17,
          ),
        ),
      ),

      const SizedBox(width: 8),

      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: value.length > 15 ? 17 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
  }
}