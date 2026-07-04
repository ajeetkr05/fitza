import 'package:flutter/material.dart';

class WeightUpdatedScreen extends StatelessWidget {
  final double weight;
  final double bmi;

  const WeightUpdatedScreen({
    super.key,
    required this.weight,
    required this.bmi,
  });

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color successGreen = Color(0xFF2E7D32);

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
                      'Weight Updated',
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

              const SizedBox(height: 70),

              Container(
                height: 170,
                width: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: successGreen,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 100,
                ),
              ),

              const SizedBox(height: 48),

              const Text(
                'Weight and BMI updated',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkText,
                  fontSize: 31,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Great job staying consistent!',
                style: TextStyle(
                  color: greyText,
                  fontSize: 19,
                ),
              ),

              const SizedBox(height: 44),

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
                    _summaryRow(
                      icon: Icons.monitor_weight_outlined,
                      iconColor: primaryBlue,
                      title: 'Current Weight',
                      value: '${weight.toStringAsFixed(1)} kg',
                    ),
                    const Divider(height: 34),
                    _summaryRow(
                      icon: Icons.calculate_outlined,
                      iconColor: primaryBlue,
                      title: 'BMI',
                      value: bmi.toStringAsFixed(1),
                    ),
                    const Divider(height: 34),
                    _summaryRow(
                      icon: Icons.trending_down_rounded,
                      iconColor: successGreen,
                      title: 'Change from last week',
                      value: '↓ 1.2 kg',
                      valueColor: successGreen,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'View Progress Dashboard',
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
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Weight Trend screen will be connected later.'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: const BorderSide(
                      color: primaryBlue,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'View Weight Trend',
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

  Widget _summaryRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color valueColor = darkText,
  }) {
    return Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 29,
          ),
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
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}