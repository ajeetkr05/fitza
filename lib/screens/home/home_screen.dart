import 'package:flutter/material.dart';

import '../../main.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/fitza_header.dart';
import '../../models/profile/user_profile.dart';
import '../../models/progress/workout_entry.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../../services/progress/workout_firestore_service.dart';
import '../../services/progress/weight_firestore_service.dart';
import '../../models/progress/weight_entry.dart';
import '../../models/workout/calorie_summary.dart';
import '../../models/Nutrition/meal_entry.dart';
import '../../services/Nutrition/nutrition_firestore_service.dart';
import '../../services/workout/recommendation_service.dart';
import '../../models/workout/daily_recommendation.dart';
import '../workout/workout_details_screen.dart';
import '../progress/add_weight/add_weight_screen.dart';
import '../Nutrition/add_meal_screen.dart';

class HomeScreen extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const HomeScreen({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color calorieOrange = Color(0xFFFF7A00);

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _softBackground(BuildContext context, Color color) {
    return color.withValues(alpha: _isDark(context) ? 0.20 : 0.12);
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be connected later.'),
      ),
    );
  }

  String get _timeOfDayGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Consecutive-day workout streak, counted backward from today. If no
  /// workout was logged today, the streak counts backward from yesterday
  /// instead (so a user who hasn't worked out YET today doesn't see their
  /// streak drop to 0 before the day is even over).
  int _computeStreak(List<WorkoutEntry> workouts) {
    if (workouts.isEmpty) return 0;

    final workoutDates = workouts
        .map((w) => DateTime(w.recordedAt.year, w.recordedAt.month, w.recordedAt.day))
        .toSet();

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);

    if (!workoutDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!workoutDates.contains(cursor)) return 0;
    }

    var streak = 0;
    while (workoutDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Returns (latestWeightKg, changeSinceLastWeek) or null if no entries.
  /// getWeightEntriesStream() orders ascending, so the latest is last.
  /// "This week" comparison uses the entry closest to (but not after) 7
  /// days before the latest entry's date - falls back to the earliest
  /// entry if the full history is shorter than a week.
  (double, double)? _computeWeightSummary(List<WeightEntry> entries) {
    if (entries.isEmpty) return null;

    final sorted = [...entries]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final latest = sorted.last;
    final weekAgoCutoff = latest.recordedAt.subtract(const Duration(days: 7));

    WeightEntry? weekAgoEntry;
    for (final entry in sorted) {
      if (entry.recordedAt.isBefore(weekAgoCutoff) || entry.recordedAt.isAtSameMomentAs(weekAgoCutoff)) {
        weekAgoEntry = entry; // keeps advancing to the closest one before cutoff
      }
    }
    weekAgoEntry ??= sorted.first; // history shorter than a week - compare to earliest available

    return (latest.weightKg, latest.weightKg - weekAgoEntry.weightKg);
  }

  /// Returns (steps, caloriesBurned, activeMinutes) for today.
  ///
  /// Steps and calories come from CardioWorkoutScreen's saved exercise data
  /// ('steps' / 'caloriesBurned' fields, either user-entered or estimated
  /// there) - only Cardio-type entries carry these fields. Active minutes
  /// sums durationMinutes across ALL of today's workouts regardless of
  /// type, as a reasonable proxy for "time spent active today".
  (int, int, int) _computeTodayCardioStats(List<WorkoutEntry> workouts) {
    final today = DateTime.now();
    final todaysWorkouts = workouts.where((w) {
      return w.recordedAt.year == today.year &&
          w.recordedAt.month == today.month &&
          w.recordedAt.day == today.day;
    }).toList();

    var steps = 0;
    var calories = 0;
    var activeMinutes = 0;

    for (final workout in todaysWorkouts) {
      activeMinutes += workout.durationMinutes;

      if (workout.workoutType != 'Cardio') continue;

      for (final exercise in workout.exercises) {
        final exerciseSteps = exercise['steps'];
        final exerciseCalories = exercise['caloriesBurned'];
        if (exerciseSteps is num) steps += exerciseSteps.toInt();
        if (exerciseCalories is num) calories += exerciseCalories.toInt();
      }
    }

    return (steps, calories, activeMinutes);
  }

   String get _todayDateKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
 
  /// Calories remaining today = target - consumed so far, clamped to 0
  /// (never negative - AddMealScreen expects a sensible budget, not a
  /// deficit number). Uses the user's personalized target if set, falling
  /// back to the shared default otherwise (see calorie_summary.dart for
  /// why that default exists).
  double _computeRemainingCalories(UserProfile? profile, List<MealEntry> todaysMeals) {
    final target = profile?.targetCalories ?? kDefaultTargetCalories;
    final consumed = todaysMeals.fold<double>(0, (sum, meal) => sum + meal.totalCalories);
    final remaining = target - consumed;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors(context).background,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: widget.selectedIndex,
        onTap: widget.onTabChanged,
      ),
      body: SafeArea(
        child: StreamBuilder<UserProfile>(
          stream: ProfileFirestoreService.instance.getProfileStream(),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;

            return StreamBuilder<List<WorkoutEntry>>(
              stream: WorkoutFirestoreService.instance.getWorkoutEntriesStream(),
              builder: (context, workoutsSnapshot) {
                final workouts = workoutsSnapshot.data ?? [];
                final recentWorkouts = workouts.take(5).toList();
                final streak = _computeStreak(workouts);
                final cardioStats = _computeTodayCardioStats(workouts);

                DailyRecommendation? recommendation;
                if (profile != null) {
                  recommendation = RecommendationService().generateRecommendation(
                    profile: profile,
                    recentWorkouts: recentWorkouts,
                  );
                }

                return StreamBuilder<List<WeightEntry>>(
                  stream: WeightFirestoreService.instance.getWeightEntriesStream(),
                  builder: (context, weightSnapshot) {
                    final weightSummary = _computeWeightSummary(weightSnapshot.data ?? []);

                    return StreamBuilder<List<MealEntry>>(
                    stream: NutritionFirestoreService.instance.getMealsStream(_todayDateKey),
                    builder: (context, mealsSnapshot) {
                      final remainingCalories = _computeRemainingCalories(
                        profile,
                        mealsSnapshot.data ?? [],
                      );

                    return _content(context, profile, recommendation, streak, weightSummary, cardioStats, remainingCalories);
                  },
                );
              },
            );
          },
        );
          },
    ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    UserProfile? profile,
    DailyRecommendation? recommendation,
    int streak,
    (double, double)? weightSummary,
    (int, int, int) cardioStats,
    double remainingCalories,
  ) {
    final fitzaColors = _colors(context);
    final displayName = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName
        : 'there';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FitzaHeader(
            trailing: FitzaHeaderIconButton(
              icon: Icons.notifications_none_rounded,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            '$_timeOfDayGreeting, $displayName',
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Earn it, Every day',
            style: TextStyle(
              color: fitzaColors.primaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                      Text(
                        'Today’s Summary',
                        style: TextStyle(
                          color: fitzaColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    // Steps/Calories come from Cardio-logged workouts only
                    // (CardioWorkoutScreen's steps/caloriesBurned fields) -
                    // not from a device pedometer. Will read 0 on days with
                    // no cardio logged, even if the user was actually active.
                    Expanded(
                      child: _summaryItem(
                        icon: Icons.directions_walk_rounded,
                        iconColor: primaryBlue,
                        title: 'Steps',
                        value: '${cardioStats.$1}',
                        subtitle: 'today',
                      ),
                    ),
                    Expanded(
                      child: _summaryItem(
                        icon: Icons.local_fire_department_outlined,
                        iconColor: calorieOrange,
                        title: 'Calories',
                        value: '${cardioStats.$2}',
                        subtitle: 'kcal burned',
                      ),
                    ),
                    Expanded(
                      child: _summaryItem(
                        icon: Icons.timer_outlined,
                        iconColor: successGreen,
                        title: 'Active',
                        value: '${cardioStats.$3}',
                        subtitle: 'min today',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today’s Workout',
                  style: TextStyle(
                    color: fitzaColors.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  recommendation?.title ?? 'Loading...',
                  style: TextStyle(
                    color: fitzaColors.primaryText,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _workoutTag(
                      icon: Icons.schedule_outlined,
                      label: recommendation != null
                          ? '${recommendation.durationMinutes} min'
                          : '--',
                    ),
                    _workoutTag(
                      icon: Icons.bar_chart_rounded,
                      label: recommendation?.difficulty ?? '--',
                    ),
                    _workoutTag(
                      icon: Icons.fitness_center_outlined,
                      label: (recommendation?.exercises.any(
                                (p) => p.exercise.equipmentTags.isNotEmpty,
                              ) ??
                              false)
                          ? 'Equipment'
                          : 'Bodyweight',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: recommendation == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutDetailsScreen(
                                  recommendation: recommendation!,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fitzaColors.primaryBlue,
                      foregroundColor: fitzaColors.textOnBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: _isDark(context) ? 0 : 2,
                    ),
                    child: Text(
                      'Start Workout',
                      style: TextStyle(
                        color: fitzaColors.textOnBlue,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  title: 'Your Progress',
                  actionText: 'View Progress',
                  onTap: () => widget.onTabChanged(3)
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _progressMiniCard(
                        icon: Icons.trending_up_rounded,
                        title: 'Weight',
                        value: weightSummary != null
                            ? '${weightSummary.$1.toStringAsFixed(1)} kg'
                            : '--',
                        subtitle: weightSummary != null
                            ? '${weightSummary.$2 <= 0 ? '' : '+'}${weightSummary.$2.toStringAsFixed(1)} kg this week'
                            : 'not logged yet',
                        iconColor: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _progressMiniCard(
                        icon: Icons.local_fire_department_outlined,
                        title: 'Streak',
                        value: streak == 0 ? '0 days' : '$streak day${streak == 1 ? '' : 's'}',
                        subtitle: streak > 0 ? 'Keep it up!' : 'Start today',
                        iconColor: successGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Quick Actions',
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _quickAction(
                  icon: Icons.restaurant_outlined,
                  label: 'Log Meal',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddMealScreen(remainingCalories: remainingCalories),
                          ),
                        );
                      },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickAction(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Add Weight',
                    onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddWeightScreen(),
                          ),
                        );
                      },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fitzaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: fitzaColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDark(context)
                ? const Color(0x33000000)
                : const Color(0x0F000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    final fitzaColors = _colors(context);

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: fitzaColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            child: Row(
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    color: fitzaColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: fitzaColors.primaryBlue,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final fitzaColors = _colors(context);

    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _softBackground(context, iconColor),
          child: Icon(
            icon,
            color: iconColor,
            size: 25,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fitzaColors.secondaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: fitzaColors.primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: fitzaColors.secondaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _workoutTag({
    required IconData icon,
    required String label,
  }) {
    final fitzaColors = _colors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: fitzaColors.inputSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: fitzaColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: fitzaColors.secondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressMiniCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
  }) {
    final fitzaColors = _colors(context);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: fitzaColors.inputSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fitzaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 25,
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: TextStyle(
              color: fitzaColors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: iconColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final fitzaColors = _colors(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: fitzaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: fitzaColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: fitzaColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fitzaColors.primaryText,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
