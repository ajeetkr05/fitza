import 'package:flutter/material.dart';
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
import 'nutrition_history_screen.dart';

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
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color background = Color(0xFFF5F5F5);
  static const Color successGreen = Color(0xFF2E7D32);

  // Targets
  double targetCalories = 2200.0;
  double targetProtein = 120.0;
  double targetCarbs = 275.0;
  double targetFat = 73.0;
  int targetWaterMl = 3000;

  String get _currentDateString {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  String get _formattedHeaderDate {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    // weekday is 1-indexed, starting from Monday in Dart
    final weekdayStr = weekdays[now.weekday == 7 ? 0 : now.weekday];
    return "${months[now.month - 1]} ${now.day}, $weekdayStr";
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _currentDateString;
    print('NutritionHome: querying for date=$dateStr');

    return StreamBuilder<UserProfile>(
      stream: ProfileFirestoreService.instance.getProfileStream(),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          print('NutritionHome: profileStream error=${profileSnapshot.error}');
        }
        final profile = profileSnapshot.data;
        if (profile != null) {
          targetCalories = profile.targetCalories ?? 2200.0;
          targetProtein = profile.targetProtein ?? 120.0;
          targetCarbs = profile.targetCarbs ?? 275.0;
          targetFat = profile.targetFat ?? 73.0;
          targetWaterMl = profile.targetWaterMl ?? 3000;
        }
        final displayName = profile?.displayName ?? 'User';
        final goal = profile?.goal ?? 'Stay Fit';
        final dietaryPref = profile?.dietaryPreference ?? 'Not set';

        return StreamBuilder<List<MealEntry>>(
          stream: NutritionFirestoreService.instance.getMealsStream(dateStr),
          builder: (context, mealsSnapshot) {
            if (mealsSnapshot.hasError) {
              print('NutritionHome: mealsStream error=${mealsSnapshot.error}');
            }
            final meals = mealsSnapshot.data ?? [];
            print('NutritionHome: meals count=${meals.length}');

            return StreamBuilder<List<WaterLog>>(
              stream: NutritionFirestoreService.instance.getWaterStream(dateStr),
              builder: (context, waterSnapshot) {
                if (waterSnapshot.hasError) {
                  print('NutritionHome: waterStream error=${waterSnapshot.error}');
                }
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
                                // Top Header
                                FitzaHeader(
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const NutritionHistoryScreen(),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFF1555C0), width: 1.5),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x0A000000),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.bar_chart_rounded,
                                                color: Color(0xFF1555C0),
                                                size: 18,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Progress',
                                                style: TextStyle(
                                                  color: Color(0xFF1555C0),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Hello, $displayName!',
                                  style: const TextStyle(
                                    color: darkText,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 14, color: primaryBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formattedHeaderDate,
                                      style: const TextStyle(
                                        color: primaryBlue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

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
          style: const TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailingText.isNotEmpty)
          Text(
            trailingText,
            style: const TextStyle(
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
        color: Colors.white,
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
                const Text(
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
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${targetCalories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
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
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remaining.toStringAsFixed(0),
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
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
        color: Colors.white,
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
            style: const TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                val.toStringAsFixed(0),
                style: const TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '/${target.toStringAsFixed(0)}g',
                style: const TextStyle(color: greyText, fontSize: 10),
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
                    const Text(
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
                      style: const TextStyle(color: greyText, fontSize: 12),
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
                child: const Text(
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLogged ? const Color(0xFFD1FADF) : const Color(0xFFEAECF0),
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
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isLogged)
                      const Icon(Icons.check_circle_rounded, color: successGreen, size: 16)
                    else
                      const Icon(Icons.circle_outlined, color: greyText, size: 16),
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
                      style: const TextStyle(color: greyText, fontSize: 10),
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
        color: Colors.white,
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
        itemCount: meals.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEAECF0)),
        itemBuilder: (context, index) {
          final meal = meals[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            title: Text(
              meal.mealType,
              style: const TextStyle(
                color: darkText,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              '${meal.items.length} items logged',
              style: const TextStyle(color: greyText, fontSize: 12),
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
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'P: ${meal.totalProtein.toStringAsFixed(0)}g C: ${meal.totalCarbs.toStringAsFixed(0)}g',
                      style: const TextStyle(color: greyText, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => NutritionFirestoreService.instance.deleteMeal(meal.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
