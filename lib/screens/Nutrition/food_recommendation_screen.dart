import 'package:flutter/material.dart';
import '../../services/Nutrition/gemini_service.dart';
import 'meal_details_screen.dart';

class FoodRecommendationScreen extends StatefulWidget {
  final double remainingCalories;
  final double remainingProtein;
  final double remainingCarbs;
  final double remainingFat;
  final int mealsRemaining;
  final String goal;
  final String dietaryPreference;

  const FoodRecommendationScreen({
    super.key,
    required this.remainingCalories,
    required this.remainingProtein,
    required this.remainingCarbs,
    required this.remainingFat,
    required this.mealsRemaining,
    required this.goal,
    required this.dietaryPreference,
  });

  @override
  State<FoodRecommendationScreen> createState() => _FoodRecommendationScreenState();
}

class _FoodRecommendationScreenState extends State<FoodRecommendationScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _recommendations = {};

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color background = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final data = await GeminiService.instance.getFoodRecommendations(
        remainingCalories: widget.remainingCalories,
        remainingProtein: widget.remainingProtein,
        remainingCarbs: widget.remainingCarbs,
        remainingFat: widget.remainingFat,
        mealsRemaining: widget.mealsRemaining,
        goal: widget.goal,
        dietaryPreference: widget.dietaryPreference,
      );
      setState(() {
        _recommendations = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load food recommendations. Using backup data.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Recommended For You',
          style: TextStyle(
            color: darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryBlue),
                  SizedBox(height: 16),
                  Text(
                    'AI is crafting your recommendations...',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Analyzing remaining calorie & protein budgets',
                    style: TextStyle(color: greyText, fontSize: 13),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Based on your remaining goals today',
                    style: TextStyle(
                      color: greyText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _recommendationCard(
                    categoryTitle: 'High Protein Option',
                    icon: Icons.fitness_center_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    mealData: _recommendations['highProtein'],
                  ),
                  const SizedBox(height: 16),
                  _recommendationCard(
                    categoryTitle: 'Balanced Meal Option',
                    icon: Icons.scale_rounded,
                    iconColor: primaryBlue,
                    mealData: _recommendations['balancedMeal'],
                  ),
                  const SizedBox(height: 16),
                  _recommendationCard(
                    categoryTitle: 'Low Calorie Option',
                    icon: Icons.eco_rounded,
                    iconColor: const Color(0xFFE65100),
                    mealData: _recommendations['lowCalorie'],
                  ),
                  const SizedBox(height: 16),
                  _recommendationCard(
                    categoryTitle: 'Healthy Snack Option',
                    icon: Icons.apple_rounded,
                    iconColor: const Color(0xFFC2185B),
                    mealData: _recommendations['healthySnack'],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: primaryBlue, width: 1.5),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Return Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _recommendationCard({
    required String categoryTitle,
    required IconData icon,
    required Color iconColor,
    required Map<String, dynamic>? mealData,
  }) {
    if (mealData == null) return const SizedBox.shrink();

    final String mealName = mealData['mealName'] ?? 'Recommended Option';
    final double calories = (mealData['estimatedCalories'] as num?)?.toDouble() ?? 0.0;
    final String description = mealData['shortDescription'] ?? '';
    final String whyMsg = mealData['whyThisRecommendation'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withValues(alpha: 0.1),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                categoryTitle,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            mealName,
            style: const TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: greyText,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why this meal?',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        whyMsg,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealDetailsScreen(
                      categoryTitle: categoryTitle,
                      mealData: mealData,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
