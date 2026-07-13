import 'package:flutter/material.dart';
import '../../models/Nutrition/food_item.dart';
import '../../models/Nutrition/meal_entry.dart';
import '../../services/Nutrition/nutrition_firestore_service.dart';

class MealDetailsScreen extends StatefulWidget {
  final String categoryTitle;
  final Map<String, dynamic> mealData;

  const MealDetailsScreen({
    super.key,
    required this.categoryTitle,
    required this.mealData,
  });

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  bool _isSaving = false;
  String _selectedMealType = 'Lunch'; // default meal type

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color background = Color(0xFFF5F5F5);

  List<FoodItem> _parseFoodItems() {
    final itemsList = widget.mealData['items'] as List<dynamic>?;
    if (itemsList == null) return [];

    return itemsList.map((item) {
      return FoodItem(
        name: item['name'] as String? ?? '',
        quantity: item['quantity'] as String? ?? '',
        calories: (item['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (item['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (item['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (item['fat'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  Future<void> _acceptRecommendation() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final items = _parseFoodItems();
      final double totalCalories = (widget.mealData['estimatedCalories'] as num?)?.toDouble() ?? 0.0;
      
      double totalProtein = 0.0;
      double totalCarbs = 0.0;
      double totalFat = 0.0;
      for (var item in items) {
        totalProtein += item.protein;
        totalCarbs += item.carbs;
        totalFat += item.fat;
      }

      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final meal = MealEntry(
        id: '',
        userId: '',
        date: dateStr,
        mealType: _selectedMealType,
        items: items,
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        timestamp: now,
      );

      await NutritionFirestoreService.instance.saveMeal(meal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.mealData['mealName']} logged as $_selectedMealType successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        // Pop back to the Nutrition Home (which is 2 screens back: Recommendations and Details)
        // Or pop back twice
        int count = 0;
        Navigator.popUntil(context, (route) => count++ >= 2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save recommended meal.')),
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
    final String mealName = widget.mealData['mealName'] ?? 'Meal Details';
    final double calories = (widget.mealData['estimatedCalories'] as num?)?.toDouble() ?? 0.0;
    final String whyMsg = widget.mealData['whyThisRecommendation'] ?? '';
    final items = _parseFoodItems();

    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    for (var item in items) {
      totalProtein += item.protein;
      totalCarbs += item.carbs;
      totalFat += item.fat;
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Meal Details',
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
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
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
                        Text(
                          widget.categoryTitle.toUpperCase(),
                          style: const TextStyle(
                            color: primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mealName,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _macroValueColumn('Calories', '${calories.toStringAsFixed(0)} kcal', primaryBlue),
                            _macroValueColumn('Protein', '${totalProtein.toStringAsFixed(1)}g', const Color(0xFF2E7D32)),
                            _macroValueColumn('Carbs', '${totalCarbs.toStringAsFixed(1)}g', const Color(0xFFE65100)),
                            _macroValueColumn('Fat', '${totalFat.toStringAsFixed(1)}g', const Color(0xFFC2185B)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ingredients / Food Items',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEAECF0)),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  color: darkText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                item.quantity,
                                style: const TextStyle(color: greyText, fontSize: 13),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.calories.toStringAsFixed(0)} kcal',
                                    style: const TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'P: ${item.protein.toStringAsFixed(0)}g | C: ${item.carbs.toStringAsFixed(0)}g | F: ${item.fat.toStringAsFixed(0)}g',
                                    style: const TextStyle(color: greyText, fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Recommendation Details',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706)),
                            SizedBox(width: 8),
                            Text(
                              'Why was this recommended?',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          whyMsg,
                          style: const TextStyle(
                            color: Color(0xFF78350F),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Which meal is this for?',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Breakfast', 'Lunch', 'Snack', 'Dinner'].map((type) {
                      final isSelected = _selectedMealType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMealType = type;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryBlue : const Color(0xFFEAECF0),
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isSelected ? Colors.white : darkText,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _acceptRecommendation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Accept Recommendation & Log',
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

  Widget _macroValueColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: greyText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
