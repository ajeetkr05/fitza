import 'package:flutter/material.dart';
import '../../models/Nutrition/food_item.dart';
import '../../services/Nutrition/gemini_service.dart';
import '../../services/Nutrition/nutrition_firestore_service.dart';
import 'review_meal_screen.dart';

class AddMealScreen extends StatefulWidget {
  final double remainingCalories;

  const AddMealScreen({
    super.key,
    required this.remainingCalories,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  String _selectedMealType = 'Breakfast';
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearching = false;
  List<FoodItem> _searchResults = [];
  final List<FoodItem> _selectedItems = [];

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color background = Color(0xFFF5F5F5);

  // Quick/Recent/Frequently eaten foods list for mock suggestions
  final List<FoodItem> _frequentFoods = const [
    FoodItem(name: 'Boiled Egg', quantity: '1 piece', calories: 78, protein: 6.3, carbs: 0.6, fat: 5.3),
    FoodItem(name: 'Oatmeal with Milk', quantity: '1 bowl', calories: 250, protein: 10, carbs: 42, fat: 4.5),
    FoodItem(name: 'Roti (Chapati)', quantity: '1 piece', calories: 85, protein: 3, carbs: 18, fat: 0.5),
    FoodItem(name: 'Dal Tadka', quantity: '1 bowl', calories: 150, protein: 7, carbs: 20, fat: 4.5),
    FoodItem(name: 'Paneer Butter Masala', quantity: '150g', calories: 320, protein: 12, carbs: 8, fat: 26),
    FoodItem(name: 'Grilled Chicken Breast', quantity: '150g', calories: 240, protein: 35, carbs: 0, fat: 4),
  ];

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      // 1. Search local Firestore collection (representing the IFCT dataset) first
      List<FoodItem> results = await NutritionFirestoreService.instance.searchLocalFoodComposition(query);

      // 2. If local database yields no results, fallback to Gemini AI search
      if (results.isEmpty) {
        results = await GeminiService.instance.searchFood(query);
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed. Using AI fallback.')),
        );
      }
    }
  }

  void _addItem(FoodItem item) {
    setState(() {
      _selectedItems.add(item);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Add Meal',
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
      body: _isSearching
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryBlue),
                  SizedBox(height: 16),
                  Text(
                    'Searching food databases...',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  child: Column(
                    children: [
                      // Meal Type selection Row
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
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryBlue : const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : darkText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Search bar - Textfield only
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search food (e.g. 2 Roti, Chicken)',
                          hintStyle: const TextStyle(color: greyText, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: greyText),
                          filled: true,
                          fillColor: const Color(0xFFF2F4F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchResults.isNotEmpty) ...[
                          const Text(
                            'Search Results',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _foodListCard(_searchResults, isSearch: true),
                          const SizedBox(height: 20),
                        ],
                        if (_selectedItems.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Selected Foods',
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_selectedItems.length} item(s)',
                                style: const TextStyle(color: greyText, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _foodListCard(_selectedItems, isSearch: false),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewMealScreen(
                                      mealType: _selectedMealType,
                                      selectedItems: _selectedItems,
                                      remainingCalories: widget.remainingCalories,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Review Meal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const Text(
                          'Frequently Eaten Foods',
                          style: TextStyle(
                            color: darkText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _foodListCard(_frequentFoods, isSearch: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _foodListCard(List<FoodItem> items, {required bool isSearch}) {
    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEAECF0)),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            title: Text(
              item.name,
              style: const TextStyle(
                color: darkText,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              '${item.quantity} | P: ${item.protein.toStringAsFixed(0)}g C: ${item.carbs.toStringAsFixed(0)}g F: ${item.fat.toStringAsFixed(0)}g',
              style: const TextStyle(color: greyText, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                isSearch
                    ? Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0EAFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: primaryBlue, size: 18),
                          onPressed: () => _addItem(item),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                        onPressed: () => _removeItem(index),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
