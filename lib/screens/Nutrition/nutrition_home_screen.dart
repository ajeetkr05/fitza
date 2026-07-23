import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/Nutrition/meal_entry.dart';
import '../../models/Nutrition/water_log.dart';
import '../../models/profile/user_profile.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../../services/Nutrition/nutrition_firestore_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/fitza_header.dart';
import 'add_meal_screen.dart';
import 'add_water_screen.dart';
import 'food_recommendation_screen.dart';

class NutritionHomeScreen extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const NutritionHomeScreen({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  State<NutritionHomeScreen> createState() => _NutritionHomeScreenState();
}

class _NutritionHomeScreenState extends State<NutritionHomeScreen> {
  FitzaThemeColors get _colors => Theme.of(context).extension<FitzaThemeColors>()!;
  Color get primaryBlue => _colors.primaryBlue;
  Color get darkText => _colors.primaryText;
  Color get greyText => _colors.secondaryText;
  Color get background => _colors.background;
  Color get successGreen => _colors.successGreen;
  Color get surface => _colors.surface;
  Color get inputSurface => _colors.inputSurface;
  Color get border => _colors.border;

  // Targets
  double targetCalories = 2200.0;
  double targetProtein = 120.0;
  double targetCarbs = 275.0;
  double targetFat = 73.0;
  int targetWaterMl = 3000;

  // History state: 0 = Weekly (7 days), 1 = Monthly (30 days)
  int _selectedHistoryTab = 0;
  bool _isHistoryLoading = true;
  List<MealEntry> _historyMeals = [];
  List<WaterLog> _historyWaterLogs = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      int daysBack = _selectedHistoryTab == 0 ? 7 : 30;

      final mealsList = await NutritionFirestoreService.instance.getHistoryMeals(daysBack);
      final waterList = await NutritionFirestoreService.instance.getHistoryWater(daysBack);

      if (mounted) {
        setState(() {
          _historyMeals = mealsList;
          _historyWaterLogs = waterList;
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
        });
      }
    }
  }

  String get _currentDateString {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _currentDateString;

    return StreamBuilder<UserProfile>(
      stream: ProfileFirestoreService.instance.getProfileStream(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        if (profile != null) {
          targetCalories = profile.targetCalories ?? 2200.0;
          targetProtein = profile.targetProtein ?? 120.0;
          targetCarbs = profile.targetCarbs ?? 275.0;
          targetFat = profile.targetFat ?? 73.0;
          targetWaterMl = profile.targetWaterMl ?? 3000;
        }
        final goal = profile?.goal ?? 'Stay Fit';
        final dietaryPref = profile?.dietaryPreference ?? 'Not set';

        return StreamBuilder<List<MealEntry>>(
          stream: NutritionFirestoreService.instance.getMealsStream(dateStr),
          builder: (context, mealsSnapshot) {
            final meals = mealsSnapshot.data ?? [];

            return StreamBuilder<List<WaterLog>>(
              stream: NutritionFirestoreService.instance.getWaterStream(dateStr),
              builder: (context, waterSnapshot) {
                final waterLogs = waterSnapshot.data ?? [];

                // Calculation calculations
                double consumedCals = 0.0;
                double consumedP = 0.0;
                double consumedC = 0.0;
                double consumedF = 0.0;

                for (var meal in meals) {
                  consumedCals += meal.totalCalories;
                  consumedP += meal.totalProtein;
                  consumedC += meal.totalCarbs;
                  consumedF += meal.totalFat;
                }

                int consumedWaterMl = 0;
                for (var w in waterLogs) {
                  consumedWaterMl += w.amountMl;
                }

                double remainingCals = targetCalories - consumedCals;
                if (remainingCals < 0) remainingCals = 0;
                double remainingP = targetProtein - consumedP;
                if (remainingP < 0) remainingP = 0;
                double remainingC = targetCarbs - consumedC;
                if (remainingC < 0) remainingC = 0;
                double remainingF = targetFat - consumedF;
                if (remainingF < 0) remainingF = 0;

                // Meal states
                final mealStates = {
                  'Breakfast': meals.where((m) => m.mealType == 'Breakfast').toList(),
                  'Lunch': meals.where((m) => m.mealType == 'Lunch').toList(),
                  'Snack': meals.where((m) => m.mealType == 'Snack').toList(),
                  'Dinner': meals.where((m) => m.mealType == 'Dinner').toList(),
                };

                int completedMealsCount = mealStates.values.where((list) => list.isNotEmpty).length;

                return Scaffold(
                  backgroundColor: background,
                  bottomNavigationBar: AppBottomNavigation(
                    currentIndex: widget.selectedIndex,
                    onTap: widget.onTabChanged,
                  ),
                  body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Header (clean, without extra greeting or Progress button)
                                const FitzaHeader(),
                                const SizedBox(height: 16),

                                // Calories Progress Card
                                _calorieProgressCard(consumedCals, remainingCals),
                                const SizedBox(height: 18),

                                // Macros Progress Row
                                _macrosRow(consumedP, consumedC, consumedF),
                                const SizedBox(height: 18),

                                // Water Intake Card
                                _waterIntakeCard(consumedWaterMl),
                                const SizedBox(height: 18),

                                // Today's Meals Section
                                _sectionTitle('Today’s Meals', '$completedMealsCount / 4 Completed'),
                                const SizedBox(height: 12),
                                _mealsHorizontalChecklist(mealStates),
                                const SizedBox(height: 22),

                                // Quick Actions Panel
                                _sectionTitle('Nutrition Tools', ''),
                                const SizedBox(height: 12),
                                _quickActionsPanel(
                                  remainingCals: remainingCals,
                                  remainingP: remainingP,
                                  remainingC: remainingC,
                                  remainingF: remainingF,
                                  completedMealsCount: completedMealsCount,
                                  goal: goal,
                                  dietaryPref: dietaryPref,
                                ),
                                const SizedBox(height: 22),

                                // Recent Logged Items
                                if (meals.isNotEmpty) ...[
                                  _sectionTitle('Recent Logs', ''),
                                  const SizedBox(height: 12),
                                  _recentLogsCard(meals),
                                  const SizedBox(height: 22),
                                ],

                                // Nutrition History Section (Weekly / Monthly)
                                _sectionTitle('Nutrition History', ''),
                                const SizedBox(height: 12),
                                _historyToggleButtons(),
                                const SizedBox(height: 16),
                                if (_isHistoryLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 36),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                else ...[
                                  _calorieChartCard(),
                                  const SizedBox(height: 18),
                                  _sectionTitle('Averages & Summary', ''),
                                  const SizedBox(height: 12),
                                  _metricsSummaryCard(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String title, String trailingText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailingText.isNotEmpty)
          Text(
            trailingText,
            style: TextStyle(
              color: greyText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _calorieProgressCard(double consumed, double remaining) {
    final double fraction = (consumed / targetCalories).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calorie Progress',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${consumed.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${targetCalories.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 90,
                width: 90,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFFEAECF0),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remaining.toStringAsFixed(0),
                    style: TextStyle(
                      color: darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'remaining',
                    style: TextStyle(
                      color: greyText,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macrosRow(double p, double c, double f) {
    return Row(
      children: [
        Expanded(child: _macroMiniCard('Protein', p, targetProtein, const Color(0xFF2E7D32))),
        const SizedBox(width: 10),
        Expanded(child: _macroMiniCard('Carbs', c, targetCarbs, const Color(0xFFE65100))),
        const SizedBox(width: 10),
        Expanded(child: _macroMiniCard('Fat', f, targetFat, const Color(0xFFC2185B))),
      ],
    );
  }

  Widget _macroMiniCard(String label, double val, double target, Color progressColor) {
    final double fraction = (val / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                val.toStringAsFixed(0),
                style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '/${target.toStringAsFixed(0)}g',
                style: TextStyle(color: greyText, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: const Color(0xFFEAECF0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterIntakeCard(int currentMl) {
    final double fraction = (currentMl / targetWaterMl).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(Icons.water_drop_rounded, color: Colors.lightBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Water Intake',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(currentMl / 1000.0).toStringAsFixed(currentMl % 1000 == 0 ? 0 : 1)} L / ${(targetWaterMl / 1000.0).toStringAsFixed(targetWaterMl % 1000 == 0 ? 0 : 1)} L',
                      style: TextStyle(color: greyText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddWaterScreen()),
                  );
                },
                child: Text(
                  '+ Add Water',
                  style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: const Color(0xFFF2F4F7),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealsHorizontalChecklist(Map<String, List<MealEntry>> mealStates) {
    return SizedBox(
      height: 105,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: mealStates.entries.map((entry) {
          final type = entry.key;
          final logs = entry.value;
          final isLogged = logs.isNotEmpty;
          final calories = isLogged ? logs.fold(0.0, (sum, m) => sum + m.totalCalories) : 0.0;

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLogged ? const Color(0xFFD1FADF) : border,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        type,
                        style: TextStyle(
                          color: darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isLogged)
                      Icon(Icons.check_circle_rounded, color: successGreen, size: 16)
                    else
                      Icon(Icons.circle_outlined, color: greyText, size: 16),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLogged ? '${calories.toStringAsFixed(0)} kcal' : 'Not Added',
                      style: TextStyle(
                        color: isLogged ? primaryBlue : greyText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLogged ? 'Logged' : '—',
                      style: TextStyle(color: greyText, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _quickActionsPanel({
    required double remainingCals,
    required double remainingP,
    required double remainingC,
    required double remainingF,
    required int completedMealsCount,
    required String goal,
    required String dietaryPref,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _quickActionButton(
                icon: Icons.restaurant_outlined,
                label: 'Add Meal',
                color: primaryBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMealScreen(
                        remainingCalories: remainingCals,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionButton(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Recommendation',
                color: const Color(0xFFD97706),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodRecommendationScreen(
                        remainingCalories: remainingCals,
                        remainingProtein: remainingP,
                        remainingCarbs: remainingC,
                        remainingFat: remainingF,
                        mealsRemaining: 4 - completedMealsCount,
                        goal: goal,
                        dietaryPreference: dietaryPref,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recentLogsCard(List<MealEntry> meals) {
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
        itemCount: meals.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: border),
        itemBuilder: (context, index) {
          final meal = meals[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            title: Text(
              meal.mealType,
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              '${meal.items.length} items logged',
              style: TextStyle(color: greyText, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${meal.totalCalories.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'P: ${meal.totalProtein.toStringAsFixed(0)}g C: ${meal.totalCarbs.toStringAsFixed(0)}g',
                      style: TextStyle(color: greyText, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () {
                    NutritionFirestoreService.instance.deleteMeal(meal.id);
                    _loadHistoryData();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _historyToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _historyTabButton(0, 'Weekly'),
          _historyTabButton(1, 'Monthly'),
        ],
      ),
    );
  }

  Widget _historyTabButton(int index, String label) {
    final isSelected = _selectedHistoryTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedHistoryTab != index) {
            setState(() {
              _selectedHistoryTab = index;
            });
            _loadHistoryData();
          }
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : darkText,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _calorieChartCard() {
    final now = DateTime.now();
    int daysCount = _selectedHistoryTab == 0 ? 7 : 30;
    List<DateTime> dateTimes = List.generate(daysCount, (i) => now.subtract(Duration(days: i))).reversed.toList();

    Map<String, double> calMap = {};
    for (var date in dateTimes) {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      calMap[dateStr] = 0.0;
    }

    for (var meal in _historyMeals) {
      if (calMap.containsKey(meal.date)) {
        calMap[meal.date] = calMap[meal.date]! + meal.totalCalories;
      }
    }

    List<double> caloriesList = dateTimes.map((dt) {
      final dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      return calMap[dateStr] ?? 0.0;
    }).toList();

    List<String> labelList = dateTimes.map((dt) {
      if (_selectedHistoryTab == 0) {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[dt.weekday - 1];
      } else {
        return dt.day.toString();
      }
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Calories Over Time',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Target: ${targetCalories.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _CalorieBarChartPainter(
                values: caloriesList,
                labels: labelList,
                target: targetCalories,
                tabIndex: _selectedHistoryTab == 0 ? 1 : 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsSummaryCard() {
    double totalCals = 0.0;
    double totalP = 0.0;
    double totalC = 0.0;
    double totalF = 0.0;

    int daysWithData = _selectedHistoryTab == 0 ? 7 : 30;

    final now = DateTime.now();
    List<DateTime> dateTimes = List.generate(daysWithData, (i) => now.subtract(Duration(days: i))).reversed.toList();
    Set<String> allowedDates = dateTimes.map((dt) {
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    }).toSet();

    for (var meal in _historyMeals) {
      if (allowedDates.contains(meal.date)) {
        totalCals += meal.totalCalories;
        totalP += meal.totalProtein;
        totalC += meal.totalCarbs;
        totalF += meal.totalFat;
      }
    }

    double totalWaterMl = 0.0;
    for (var w in _historyWaterLogs) {
      if (allowedDates.contains(w.date)) {
        totalWaterMl += w.amountMl;
      }
    }

    double avgCal = totalCals / daysWithData;
    double avgP = totalP / daysWithData;
    double avgC = totalC / daysWithData;
    double avgF = totalF / daysWithData;
    double avgWaterL = (totalWaterMl / 1000.0) / daysWithData;
    double targetWaterL = targetWaterMl / 1000.0;

    double calProgress = targetCalories > 0 ? (avgCal / targetCalories).clamp(0.0, 1.0) : 0.0;
    double pProgress = targetProtein > 0 ? (avgP / targetProtein).clamp(0.0, 1.0) : 0.0;
    double cProgress = targetCarbs > 0 ? (avgC / targetCarbs).clamp(0.0, 1.0) : 0.0;
    double fProgress = targetFat > 0 ? (avgF / targetFat).clamp(0.0, 1.0) : 0.0;
    double waterProgress = targetWaterL > 0 ? (avgWaterL / targetWaterL).clamp(0.0, 1.0) : 0.0;

    double goalCompletion = ((calProgress + pProgress + cProgress + fProgress + waterProgress) / 5.0) * 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _metricRow('Average Calories', '${avgCal.toStringAsFixed(0)} kcal', '/ ${targetCalories.toStringAsFixed(0)} kcal', avgCal / targetCalories),
          Divider(height: 24, color: border),
          _metricRow('Protein', '${avgP.toStringAsFixed(1)} g', '/ ${targetProtein.toStringAsFixed(0)} g', avgP / targetProtein),
          Divider(height: 24, color: border),
          _metricRow('Carbohydrates', '${avgC.toStringAsFixed(1)} g', '/ ${targetCarbs.toStringAsFixed(0)} g', avgC / targetCarbs),
          Divider(height: 24, color: border),
          _metricRow('Fats', '${avgF.toStringAsFixed(1)} g', '/ ${targetFat.toStringAsFixed(0)} g', avgF / targetFat),
          Divider(height: 24, color: border),
          _metricRow('Water Intake', '${avgWaterL.toStringAsFixed(avgWaterL % 1 == 0 ? 0 : 1)} L', '/ ${targetWaterL % 1 == 0 ? targetWaterL.toStringAsFixed(0) : targetWaterL.toStringAsFixed(1)} L', avgWaterL / targetWaterL),
          Divider(height: 24, color: border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal Completion',
                style: TextStyle(
                  color: darkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${goalCompletion.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String title, String value, String limit, double fraction) {
    final boundedFraction = fraction.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: greyText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  limit,
                  style: TextStyle(
                    color: greyText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: boundedFraction,
            backgroundColor: border,
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _CalorieBarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double target;
  final int tabIndex;

  _CalorieBarChartPainter({
    required this.values,
    required this.labels,
    required this.target,
    required this.tabIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final double paddingLeft = 32.0;
    final double paddingRight = 10.0;
    final double paddingTop = 20.0;
    final double paddingBottom = 24.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    double maxVal = target;
    for (var val in values) {
      if (val > maxVal) {
        maxVal = val;
      }
    }
    maxVal = maxVal * 1.15;

    final gridPaint = Paint()
      ..color = const Color(0xFFF2F4F7)
      ..strokeWidth = 1.0;

    final textStyle = const TextStyle(
      color: Color(0xFF667085),
      fontSize: 10,
    );

    int divisions = 3;
    double rawStep = maxVal / divisions;
    double step = (rawStep / 50.0).roundToDouble() * 50.0;
    if (step < 50.0) step = 50.0;
    maxVal = step * divisions;

    for (int i = 0; i <= divisions; i++) {
      final yVal = step * i;
      final y = paddingTop + chartHeight - (yVal / maxVal * chartHeight);

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final textSpan = TextSpan(
        text: yVal.toStringAsFixed(0),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    final targetPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final targetY = paddingTop + chartHeight - (target / maxVal * chartHeight);
    canvas.drawLine(
      Offset(paddingLeft, targetY),
      Offset(size.width - paddingRight, targetY),
      targetPaint,
    );

    final barCount = values.length;
    final double barSpacing = tabIndex == 2 ? 2.5 : 12.0;

    double barWidth;
    if (barCount == 1) {
      barWidth = 40.0;
    } else {
      final double totalSpacing = barSpacing * (barCount - 1);
      barWidth = (chartWidth - totalSpacing) / barCount;
    }

    for (int i = 0; i < barCount; i++) {
      final val = values[i];
      final label = labels[i];

      final double barHeight = (val / maxVal) * chartHeight;
      double x;
      if (barCount == 1) {
        x = paddingLeft + (chartWidth - barWidth) / 2;
      } else {
        x = paddingLeft + (i * (barWidth + barSpacing));
      }
      final double y = paddingTop + chartHeight - barHeight;

      paint.color = val > target ? const Color(0xFFFF9800) : const Color(0xFF1555C0);

      final double radiusValue = (barWidth < 16.0) ? barWidth / 2.0 : 8.0;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight == 0 ? 2 : barHeight),
        topLeft: Radius.circular(radiusValue),
        topRight: Radius.circular(radiusValue),
      );
      canvas.drawRRect(rect, paint);

      bool showLabel = true;
      if (tabIndex == 2 && i % 5 != 0) {
        showLabel = false;
      }

      if (showLabel) {
        final textSpan = TextSpan(
          text: label,
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + (barWidth - textPainter.width) / 2, size.height - paddingBottom + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieBarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels || oldDelegate.target != target || oldDelegate.tabIndex != tabIndex;
  }
}

