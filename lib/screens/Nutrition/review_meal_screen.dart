import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/Nutrition/food_item.dart';
import '../../models/Nutrition/meal_entry.dart';
import '../../services/Nutrition/nutrition_firestore_service.dart';

class ReviewMealScreen extends StatefulWidget {
  final String mealType;
  final List<FoodItem> selectedItems;
  final double remainingCalories;

  const ReviewMealScreen({
    super.key,
    required this.mealType,
    required this.selectedItems,
    required this.remainingCalories,
  });

  @override
  State<ReviewMealScreen> createState() => _ReviewMealScreenState();
}

class _ReviewMealScreenState extends State<ReviewMealScreen> {
  bool _isSaving = false;
  late List<FoodItem> _items;

  FitzaThemeColors get _colors => Theme.of(context).extension<FitzaThemeColors>()!;
  Color get primaryBlue => _colors.primaryBlue;
  Color get darkText => _colors.primaryText;
  Color get greyText => _colors.secondaryText;
  Color get background => _colors.background;
  Color get surface => _colors.surface;
  Color get border => _colors.border;

  @override
  void initState() {
    super.initState();
    _items = List<FoodItem>.from(widget.selectedItems);
  }

  double get _totalCalories {
    return _items.fold(0.0, (sum, item) => sum + item.calories);
  }

  double get _totalProtein {
    return _items.fold(0.0, (sum, item) => sum + item.protein);
  }

  double get _totalCarbs {
    return _items.fold(0.0, (sum, item) => sum + item.carbs);
  }

  double get _totalFat {
    return _items.fold(0.0, (sum, item) => sum + item.fat);
  }

  /// Parses a quantity string to extract the numerical value and unit.
  Map<String, dynamic> _parseQuantity(String qty) {
    final regExp = RegExp(r'^([0-9]*\.?[0-9]+)\s*(.*)$');
    final match = regExp.firstMatch(qty.trim());
    if (match != null) {
      final numVal = double.tryParse(match.group(1) ?? '') ?? 1.0;
      final unitVal = match.group(2) ?? '';
      return {'value': numVal, 'unit': unitVal.trim()};
    }
    final numberMatch = RegExp(r'([0-9]*\.?[0-9]+)').firstMatch(qty);
    if (numberMatch != null) {
      final numVal = double.tryParse(numberMatch.group(1) ?? '') ?? 1.0;
      return {'value': numVal, 'unit': qty.replaceAll(numberMatch.group(1)!, '').trim()};
    }
    return {'value': 1.0, 'unit': qty};
  }

  /// Opens a dialog to edit the quantity of a food item.
  void _editItemQuantity(int index) {
    final item = _items[index];
    final parsed = _parseQuantity(item.quantity);
    final double currentValue = parsed['value'];
    final String unit = parsed['unit'];

    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(currentValue % 1 == 0 ? 0 : 1),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Edit Quantity for\n${item.name}',
            style: TextStyle(color: darkText, fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the new quantity. Calories and macros will adjust automatically.',
                style: TextStyle(color: Color(0xFF667085), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryBlue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    unit.isEmpty ? 'units' : unit,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: greyText),
                  ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: greyText, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final newValue = double.tryParse(controller.text);
                if (newValue != null && newValue > 0) {
                  setState(() {
                    final factor = newValue / (currentValue > 0 ? currentValue : 1.0);
                    final String newQtyStr = unit.isEmpty
                        ? newValue.toStringAsFixed(newValue % 1 == 0 ? 0 : 1)
                        : '${newValue.toStringAsFixed(newValue % 1 == 0 ? 0 : 1)} $unit';

                    _items[index] = FoodItem(
                      name: item.name,
                      quantity: newQtyStr,
                      calories: item.calories * factor,
                      protein: item.protein * factor,
                      carbs: item.carbs * factor,
                      fat: item.fat * factor,
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmMeal() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No food items to log.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final meal = MealEntry(
        id: '',
        userId: '',
        date: dateStr,
        mealType: widget.mealType,
        items: _items,
        totalCalories: _totalCalories,
        totalProtein: _totalProtein,
        totalCarbs: _totalCarbs,
        totalFat: _totalFat,
        timestamp: now,
      );

      await NutritionFirestoreService.instance.saveMeal(meal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.mealType} logged successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        int count = 0;
        Navigator.popUntil(context, (route) => count++ >= 2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log meal: $e')),
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
    final double exceedsBy = _totalCalories - widget.remainingCalories;
    final bool isExceeded = exceedsBy > 0;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          'Review Meal',
          style: TextStyle(
            color: darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: surface,
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
                  Text(
                    '${widget.mealType} Summary',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
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
                          itemCount: _items.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: border),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: TextStyle(
                                            color: darkText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${item.calories.toStringAsFixed(0)} kcal',
                                        style: TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.quantity,
                                          style: TextStyle(color: greyText, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _editItemQuantity(index),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0EAFF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit_rounded, size: 10, color: primaryBlue),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color: primaryBlue,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'P: ${item.protein.toStringAsFixed(0)}g | C: ${item.carbs.toStringAsFixed(0)}g | F: ${item.fat.toStringAsFixed(0)}g',
                                        style: TextStyle(color: greyText, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: border),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Calories',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_totalCalories.toStringAsFixed(0)} kcal',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _macroSummaryCol('Protein', '${_totalProtein.toStringAsFixed(1)}g', const Color(0xFF2E7D32)),
                                  _macroSummaryCol('Carbs', '${_totalCarbs.toStringAsFixed(1)}g', const Color(0xFFE65100)),
                                  _macroSummaryCol('Fat', '${_totalFat.toStringAsFixed(1)}g', const Color(0xFFC2185B)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isExceeded) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFFFD1D1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Calorie Limit Warning',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'This meal exceeds your remaining calories budget by ${exceedsBy.toStringAsFixed(0)} kcal. (Remaining: ${widget.remainingCalories.toStringAsFixed(0)} kcal)',
                            style: const TextStyle(
                              color: Color(0xFF8C1D1D),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryBlue,
                                    side: BorderSide(color: primaryBlue),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Edit Meal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Pop twice to cancel entirely
                                    int count = 0;
                                    Navigator.popUntil(context, (route) => count++ >= 2);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Cancel Log', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _confirmMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isExceeded ? const Color(0xFFFF9800) : primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isExceeded ? 'Continue Anyway' : 'Confirm & Log Meal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Back to Search',
                        style: TextStyle(
                          color: primaryBlue,
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

  Widget _macroSummaryCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: greyText, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
