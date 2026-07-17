import 'package:flutter/material.dart';

import '../../models/profile/user_profile.dart';
import '../../models/progress/workout_entry.dart';
import '../../models/Nutrition/meal_entry.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../../services/progress/workout_firestore_service.dart';
import '../../services/Nutrition/nutrition_firestore_service.dart';
import '../../services/workout/recommendation_service.dart';
import '../../models/workout/daily_recommendation.dart';
import '../../models/workout/plan_customization.dart';
import '../../models/workout/calorie_summary.dart';
import '../../services/Nutrition/gemini_service.dart';
import '../../widgets/app_bottom_navigation.dart'; // adjust path if different
import '../../main.dart';
import 'workout_details_screen.dart';
import 'customize_plan_screen.dart';

/// "Workout Home" + "Today's Recommendation" combined (screens 1 & 2 in the
/// low-level wireflow). Slots into AppShell in place of
/// `_placeholderScreen('Workout')`.
///
/// STATE OWNERSHIP: `customization` is now owned by AppShell (the one
/// stable parent that survives tab switches), not this widget. Previously
/// this was a StatefulWidget holding its own customization state, but
/// AppShell rebuilds a fresh `pages` list on every tab switch - meaning a
/// self-owned state would silently reset every time the user switched
/// tabs and came back. Passing it down as a prop (plus a callback to
/// update it) fixes that.
class WorkoutHomeScreen extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final PlanCustomization? customization;
  final ValueChanged<PlanCustomization?> onCustomizationChanged;

  const WorkoutHomeScreen({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.customization,
    required this.onCustomizationChanged,
  });


  Future<void> _openCustomizePlan(BuildContext context) async {
    final result = await Navigator.push<PlanCustomization>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomizePlanScreen(initialCustomization: customization),
      ),
    );

    if (result != null) {
      onCustomizationChanged(result);
    }
  }

  /// Matches the 'yyyy-MM-dd' format NutritionFirestoreService.getMealsStream
  /// expects - built manually rather than pulling in intl, since this is a
  /// simple fixed-width case.
  String get _todayDateKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: selectedIndex,
        onTap: onTabChanged,
      ),
      body: SafeArea(
        child: StreamBuilder<UserProfile>(
          stream: ProfileFirestoreService.instance.getProfileStream(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _statusMessage(context, 'Could not load your profile.');
            }
            if (!profileSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = profileSnapshot.data!;

            return StreamBuilder<List<WorkoutEntry>>(
              stream:
                  WorkoutFirestoreService.instance.getWorkoutEntriesStream(),
              builder: (context, workoutsSnapshot) {
                if (workoutsSnapshot.hasError) {
                  return _statusMessage(context, 'Could not load workout history.');
                }
                if (!workoutsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Most recent first, capped to a small recent window - the
                // recommendation engine only looks at the last couple of
                // sessions for rotation purposes.
                final recentWorkouts = workoutsSnapshot.data!.take(5).toList();

                return StreamBuilder<List<MealEntry>>(
                  stream: NutritionFirestoreService.instance.getMealsStream(_todayDateKey),
                  builder: (context, mealsSnapshot) {
                    // Calorie data isn't critical to showing a recommendation -
                    // if it's still loading or errors out, just proceed
                    // without it rather than blocking the whole screen.
                    CalorieSummary? calorieSummary;
                    if (mealsSnapshot.hasData) {
                      calorieSummary = CalorieSummary.fromDailyTotals(
                        mealsSnapshot.data!.map((meal) => meal.totalCalories).toList(),
                      );
                    }

                    final recommendation =
                        RecommendationService().generateRecommendation(
                      profile: profile,
                      recentWorkouts: recentWorkouts,
                      customization: customization,
                      calorieSummary: calorieSummary,
                      // availableEquipment, injuredMuscleGroups intentionally
                      // omitted - not built yet. Add them here once those
                      // features exist; no other change needed.
                    );

                    return _content(context, profile, recommendation);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _statusMessage(BuildContext context, String message) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.secondaryText, fontSize: 16),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    UserProfile profile,
    DailyRecommendation recommendation,
  ) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final darkText = colors.primaryText;
    final greyText = colors.secondaryText;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${profile.displayName.isNotEmpty ? profile.displayName : 'there'}!',
            style: TextStyle(
              color: darkText,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ready to crush your goals today?',
            style: TextStyle(color: greyText, fontSize: 15),
          ),
          const SizedBox(height: 24),
          if (customization != null) _customizedBanner(context),
          if (customization != null) const SizedBox(height: 16),
          _recommendationCard(context, recommendation),
          const SizedBox(height: 20),
          _whyThisWorkoutCard(context, recommendation),
          const SizedBox(height: 24),
          _actionButtons(context, recommendation),
        ],
      ),
    );
  }

  Widget _customizedBanner(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, color: primaryBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Today's plan reflects your custom preferences",
              style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => onCustomizationChanged(null),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
            child: Text('Reset', style: TextStyle(color: primaryBlue, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _recommendationCard(
    BuildContext context,
    DailyRecommendation recommendation,
  ) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final darkText = colors.primaryText;
    final greyText = colors.secondaryText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Recommendation",
            style: TextStyle(color: greyText, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.title,
            style: TextStyle(
              color: darkText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _infoChip(context, Icons.timer_outlined, '${recommendation.durationMinutes} min'),
              const SizedBox(width: 10),
              _infoChip(context, Icons.bar_chart_rounded, recommendation.difficulty),
              const SizedBox(width: 10),
              _infoChip(context, Icons.fitness_center_rounded, recommendation.targetMuscles),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    final darkText = colors.primaryText;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryBlue, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: darkText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whyThisWorkoutCard(BuildContext context, DailyRecommendation recommendation) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final darkText = colors.primaryText;
    final greyText = colors.secondaryText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why this workout?',
            style: TextStyle(
              color: darkText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<String>(
            future: GeminiService.instance.explainWorkout(
              workoutTitle: recommendation.title,
              ruleBasedBullets: recommendation.reasonBullets,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ExplanationShimmer();
              }
              if (!snapshot.hasData || snapshot.hasError) {
                return _reasonBulletsList(context, recommendation.reasonBullets);
              }
              return Text(
                snapshot.data!,
                style: TextStyle(color: greyText, fontSize: 14, height: 1.4),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _reasonBulletsList(BuildContext context, List<String> bullets) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    final greyText = colors.secondaryText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets
          .map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: primaryBlue)),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(color: greyText, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _actionButtons(BuildContext context, DailyRecommendation recommendation) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    final primaryBlue = colors.primaryBlue;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutDetailsScreen(recommendation: recommendation),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'View Workout Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _openCustomizePlan(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Customize Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}

/// Simple animated shimmer placeholder shown while waiting on
/// GeminiService.explainWorkout - three pulsing bars mimicking text lines.
/// No external shimmer package needed; just an opacity pulse loop.
class _ExplanationShimmer extends StatefulWidget {
  const _ExplanationShimmer();

  @override
  State<_ExplanationShimmer> createState() => _ExplanationShimmerState();
}

class _ExplanationShimmerState extends State<_ExplanationShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBar(widthFraction: 1.0),
          const SizedBox(height: 8),
          _shimmerBar(widthFraction: 0.9),
          const SizedBox(height: 8),
          _shimmerBar(widthFraction: 0.6),
        ],
      ),
    );
  }

  Widget _shimmerBar({required double widthFraction}) {
    final colors = Theme.of(context).extension<FitzaThemeColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 13,
          width: constraints.maxWidth * widthFraction,
          decoration: BoxDecoration(
            color: colors.border,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}
