import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/common_food_suggestions.dart';
import '../../main.dart';
import '../../models/Nutrition/food_item.dart';
import '../../models/profile/user_profile.dart';
import '../../services/Nutrition/gemini_service.dart';
import '../../services/Nutrition/nutrition_firestore_service.dart';
import '../../services/profile/profile_firestore_service.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  bool _isSearching = false;
  List<FoodItem> _searchResults = [];
  final List<FoodItem> _selectedItems = [];

  bool _isLoadingFoods = true;
  List<FoodItem> _displayFoods = [];
  String _sectionTitleText = 'Suggested Foods';

  bool _showSuggestionsDropdown = false;
  List<FoodItem> _autocompleteSuggestions = [];

  FitzaThemeColors get _colors => Theme.of(context).extension<FitzaThemeColors>()!;
  Color get primaryBlue => _colors.primaryBlue;
  Color get darkText => _colors.primaryText;
  Color get greyText => _colors.secondaryText;
  Color get background => _colors.background;
  Color get surface => _colors.surface;
  Color get inputSurface => _colors.inputSurface;
  Color get border => _colors.border;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchQueryChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _showSuggestionsDropdown) {
        setState(() {
          _showSuggestionsDropdown = false;
        });
      }
    });
    _loadFoodsData();
  }

  Future<void> _loadFoodsData() async {
    setState(() {
      _isLoadingFoods = true;
    });

    try {
      // 1. Check if user has recently eaten foods from last 8 meals in Firestore
      final recentItems = await NutritionFirestoreService.instance.getRecentlyEatenFoods(mealLimit: 8);

      if (recentItems.isNotEmpty) {
        if (mounted) {
          setState(() {
            _displayFoods = recentItems;
            _sectionTitleText = 'Recently Eaten Foods';
            _isLoadingFoods = false;
          });
        }
        return;
      }

      // 2. If new user or no recent history, get dietary preference from UserProfile
      final profile = await ProfileFirestoreService.instance.getProfileStream().first;
      final lowerPref = (profile.dietaryPreference).toLowerCase();

      List<CommonFoodItem> suggested = commonFoodSuggestions;
      if (lowerPref == 'vegan') {
        suggested = commonFoodSuggestions.where((f) => f.isVegan).toList();
      } else if (lowerPref == 'vegetarian') {
        suggested = commonFoodSuggestions.where((f) => f.isVegetarian).toList();
      }

      if (mounted) {
        setState(() {
          _displayFoods = suggested.take(6).toList();
          _sectionTitleText = 'Suggested Foods';
          _isLoadingFoods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _displayFoods = commonFoodSuggestions.take(6).toList();
          _sectionTitleText = 'Suggested Foods';
          _isLoadingFoods = false;
        });
      }
    }
  }

  void _onSearchQueryChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _debounceTimer?.cancel();
      setState(() {
        _showSuggestionsDropdown = false;
        _autocompleteSuggestions = [];
        _searchResults = [];
      });
      return;
    }

    final lowerQuery = query.toLowerCase();

    // 1. Instant match from common food database (0ms latency)
    final startsWithMatches = commonFoodSuggestions.where((food) {
      return food.name.toLowerCase().startsWith(lowerQuery);
    }).toList();

    final wordMatches = commonFoodSuggestions.where((food) {
      final lower = food.name.toLowerCase();
      return !startsWithMatches.contains(food) &&
          lower.split(' ').any((w) => w.startsWith(lowerQuery));
    }).toList();

    final containsMatches = commonFoodSuggestions.where((food) {
      final lower = food.name.toLowerCase();
      return !startsWithMatches.contains(food) &&
          !wordMatches.contains(food) &&
          lower.contains(lowerQuery);
    }).toList();

    final initialMatches = <FoodItem>[
      ...startsWithMatches,
      ...wordMatches,
      ...containsMatches,
    ];

    setState(() {
      _autocompleteSuggestions = initialMatches.take(6).toList();
      _showSuggestionsDropdown = initialMatches.isNotEmpty;
      _searchResults = initialMatches; // Live populates Search Results on screen as user types!
    });

    // 2. Debounced live search to Firestore / Gemini so ANY dish (pizza, paratha, momos, etc.) updates live!
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_searchController.text.trim().toLowerCase() != lowerQuery) return;

      try {
        List<FoodItem> dbResults = await NutritionFirestoreService.instance.searchLocalFoodComposition(query);
        if (dbResults.isEmpty && query.length >= 3) {
          dbResults = await GeminiService.instance.searchFood(query);
        }

        if (_searchController.text.trim().toLowerCase() == lowerQuery && mounted) {
          final Set<String> existingNames = initialMatches.map((e) => e.name.toLowerCase()).toSet();
          final combined = List<FoodItem>.from(initialMatches);

          for (var item in dbResults) {
            if (!existingNames.contains(item.name.toLowerCase())) {
              existingNames.add(item.name.toLowerCase());
              combined.add(item);
            }
          }

          setState(() {
            _autocompleteSuggestions = combined.take(8).toList();
            _showSuggestionsDropdown = combined.isNotEmpty;
            _searchResults = combined; // Live updates Search Results on screen!
          });
        }
      } catch (e) {
        // Ignore background lookup errors
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    _debounceTimer?.cancel();
    setState(() {
      _showSuggestionsDropdown = false;
      _isSearching = true;
      _searchResults = [];
    });

    try {
      List<FoodItem> results = await NutritionFirestoreService.instance.searchLocalFoodComposition(query);

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
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          'Add Meal',
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
      body: _isSearching
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryBlue),
                  const SizedBox(height: 16),
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
                  color: surface,
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
                                  color: isSelected ? primaryBlue : inputSurface,
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
                      // Search bar
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search food (e.g. Rajma, Roti, Chicken)',
                          hintStyle: TextStyle(color: greyText, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: greyText),
                          filled: true,
                          fillColor: inputSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      // Autocomplete Suggestions Dropdown
                      if (_showSuggestionsDropdown && _autocompleteSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryBlue.withValues(alpha: 0.4), width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _autocompleteSuggestions.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: border),
                            itemBuilder: (context, index) {
                              final item = _autocompleteSuggestions[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                leading: Icon(Icons.restaurant_outlined, color: primaryBlue, size: 20),
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    color: darkText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.quantity} | P: ${item.protein.toStringAsFixed(0)}g C: ${item.carbs.toStringAsFixed(0)}g F: ${item.fat.toStringAsFixed(0)}g',
                                  style: TextStyle(color: greyText, fontSize: 11),
                                ),
                                trailing: Text(
                                  '${item.calories.toStringAsFixed(0)} kcal',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                onTap: () {
                                  _addItem(item);
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                  setState(() {
                                    _showSuggestionsDropdown = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
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
                          Text(
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
                              Text(
                                'Selected Foods',
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_selectedItems.length} item(s)',
                                style: TextStyle(color: greyText, fontSize: 13),
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
                        Text(
                          _sectionTitleText,
                          style: TextStyle(
                            color: darkText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_isLoadingFoods)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          _foodListCard(_displayFoods, isSearch: true),
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: border),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            title: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              '${item.quantity} | P: ${item.protein.toStringAsFixed(0)}g C: ${item.carbs.toStringAsFixed(0)}g F: ${item.fat.toStringAsFixed(0)}g',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: greyText, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.calories.toStringAsFixed(0)} kcal',
                  style: TextStyle(
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
                          icon: Icon(Icons.add, color: primaryBlue, size: 18),
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

