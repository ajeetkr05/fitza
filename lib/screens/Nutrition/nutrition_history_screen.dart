import 'package:flutter/material.dart';
import '../../models/Nutrition/meal_entry.dart';
import '../../models/Nutrition/water_log.dart';
import '../../services/Nutrition/nutrition_firestore_service.dart';

class NutritionHistoryScreen extends StatefulWidget {
  const NutritionHistoryScreen({super.key});

  @override
  State<NutritionHistoryScreen> createState() => _NutritionHistoryScreenState();
}

class _NutritionHistoryScreenState extends State<NutritionHistoryScreen> {
  int _selectedTab = 1; // 0 = Daily, 1 = Weekly, 2 = Monthly
  bool _isLoading = true;
  List<MealEntry> _meals = [];
  List<WaterLog> _waterLogs = [];

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color background = Color(0xFFF5F5F5);

  // Target values
  static const double targetCalories = 2200.0;
  static const double targetProtein = 120.0;
  static const double targetCarbs = 275.0;
  static const double targetFat = 73.0;
  static const double targetWaterL = 3.0;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      int daysBack = 7;
      if (_selectedTab == 0) {
        daysBack = 1;
      } else if (_selectedTab == 2) {
        daysBack = 30;
      }

      final mealsList = await NutritionFirestoreService.instance.getHistoryMeals(daysBack);
      final waterList = await NutritionFirestoreService.instance.getHistoryWater(daysBack);

      setState(() {
        _meals = mealsList;
        _waterLogs = waterList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load history data.')),
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
          'Nutrition History',
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              children: [
                _tabButton(0, 'Daily'),
                _tabButton(1, 'Weekly'),
                _tabButton(2, 'Monthly'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _calorieChartCard(),
                        const SizedBox(height: 18),
                        const Text(
                          'Averages & Summary',
                          style: TextStyle(
                            color: darkText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _metricsSummaryCard(),
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
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTab != index) {
            setState(() {
              _selectedTab = index;
            });
            _loadHistoryData();
          }
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(index == 0 ? 12 : 0),
              right: Radius.circular(index == 2 ? 12 : 0),
            ),
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
    // Generate dates list
    final now = DateTime.now();
    int daysCount = _selectedTab == 0 ? 1 : (_selectedTab == 1 ? 7 : 30);
    List<DateTime> dateTimes = List.generate(daysCount, (i) => now.subtract(Duration(days: i))).reversed.toList();

    // Map of date string to total calories
    Map<String, double> calMap = {};
    for (var date in dateTimes) {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      calMap[dateStr] = 0.0;
    }

    for (var meal in _meals) {
      if (calMap.containsKey(meal.date)) {
        calMap[meal.date] = calMap[meal.date]! + meal.totalCalories;
      }
    }

    List<double> caloriesList = dateTimes.map((dt) {
      final dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      return calMap[dateStr] ?? 0.0;
    }).toList();

    List<String> labelList = dateTimes.map((dt) {
      if (_selectedTab == 0) {
        return 'Today';
      } else if (_selectedTab == 1) {
        // Mon, Tue, Wed...
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[dt.weekday - 1];
      } else {
        // Date numbers: e.g. "12", "13"
        return dt.day.toString();
      }
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              const Text(
                'Calories Over Time',
                style: TextStyle(
                  color: darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EAFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Target: 2200 kcal',
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
                tabIndex: _selectedTab,
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

    int daysWithData = _selectedTab == 0 ? 1 : (_selectedTab == 1 ? 7 : 30);

    for (var meal in _meals) {
      totalCals += meal.totalCalories;
      totalP += meal.totalProtein;
      totalC += meal.totalCarbs;
      totalF += meal.totalFat;
    }

    double totalWaterMl = 0.0;
    for (var w in _waterLogs) {
      totalWaterMl += w.amountMl;
    }

    double avgCal = totalCals / daysWithData;
    double avgP = totalP / daysWithData;
    double avgC = totalC / daysWithData;
    double avgF = totalF / daysWithData;
    double avgWaterL = (totalWaterMl / 1000.0) / daysWithData;

    // Calculate goal completion: percentage of days calories <= targetCalories
    Map<String, double> calMap = {};
    for (var meal in _meals) {
      calMap[meal.date] = (calMap[meal.date] ?? 0) + meal.totalCalories;
    }
    int successfulDays = 0;
    calMap.forEach((date, calories) {
      if (calories <= targetCalories && calories > 0) {
        successfulDays++;
      }
    });
    double goalCompletion = daysWithData == 1 
        ? ((calMap.values.isNotEmpty && calMap.values.first <= targetCalories) ? 100.0 : 0.0)
        : (successfulDays / daysWithData) * 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _metricRow('Average Calories', '${avgCal.toStringAsFixed(0)} kcal', '/ $targetCalories kcal', avgCal / targetCalories),
          const Divider(height: 24, color: Color(0xFFF2F4F7)),
          _metricRow('Protein', '${avgP.toStringAsFixed(1)} g', '/ $targetProtein g', avgP / targetProtein),
          const Divider(height: 24, color: Color(0xFFF2F4F7)),
          _metricRow('Carbohydrates', '${avgC.toStringAsFixed(1)} g', '/ $targetCarbs g', avgC / targetCarbs),
          const Divider(height: 24, color: Color(0xFFF2F4F7)),
          _metricRow('Fats', '${avgF.toStringAsFixed(1)} g', '/ $targetFat g', avgF / targetFat),
          const Divider(height: 24, color: Color(0xFFF2F4F7)),
          _metricRow('Water Intake', '${avgWaterL.toStringAsFixed(2)} L', '/ $targetWaterL L', avgWaterL / targetWaterL),
          const Divider(height: 24, color: Color(0xFFF2F4F7)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Goal Completion',
                style: TextStyle(
                  color: darkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${goalCompletion.toStringAsFixed(0)}%',
                style: const TextStyle(
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
              style: const TextStyle(
                color: greyText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  limit,
                  style: const TextStyle(
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
            backgroundColor: const Color(0xFFF2F4F7),
            valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
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

    // Find max value in data to scale properly
    double maxVal = target;
    for (var val in values) {
      if (val > maxVal) {
        maxVal = val;
      }
    }
    // Make sure we have some breathing room
    maxVal = maxVal * 1.15;

    // Draw grid lines and Y axis labels
    final gridPaint = Paint()
      ..color = const Color(0xFFF2F4F7)
      ..strokeWidth = 1.0;

    final textStyle = const TextStyle(
      color: Color(0xFF667085),
      fontSize: 10,
    );

    int divisions = 3;
    for (int i = 0; i <= divisions; i++) {
      final yVal = (maxVal / divisions) * i;
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

    // Draw Target Line in red/orange dashed style or solid accent
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

    // Draw columns/bars
    final barCount = values.length;
    final double barSpacing = tabIndex == 2 ? 2.5 : 12.0;
    final double totalSpacing = barSpacing * (barCount - 1);
    final double barWidth = (chartWidth - totalSpacing) / barCount;

    for (int i = 0; i < barCount; i++) {
      final val = values[i];
      final label = labels[i];

      final double barHeight = (val / maxVal) * chartHeight;
      final double x = paddingLeft + (i * (barWidth + barSpacing));
      final double y = paddingTop + chartHeight - barHeight;

      // Color the bar blue, or green if target achieved
      paint.color = val > target ? const Color(0xFFFF9800) : const Color(0xFF1555C0);

      // Draw rounded bar
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight == 0 ? 2 : barHeight),
        topLeft: Radius.circular(barWidth / 2),
        topRight: Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);

      // Draw X label (only skip labels in monthly view if too cramped)
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
