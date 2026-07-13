import 'package:flutter/material.dart';

import '../../models/profile/user_profile.dart';
import '../../models/progress/workout_entry.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../../services/progress/workout_firestore_service.dart';
import '../../services/workout/recommendation_service.dart';
import '../../models/workout/daily_recommendation.dart';
import '../../widgets/app_bottom_navigation.dart'; // adjust path if different

/// "Workout Home" + "Today's Recommendation" combined (screens 1 & 2 in the
/// low-level wireflow).

class WorkoutHomeScreen extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const WorkoutHomeScreen({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  // Matches the palette used in ExerciseDetailScreen for visual consistency.
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: selectedIndex,
        onTap: onTabChanged,
      ),
      body: SafeArea(
        child: StreamBuilder<UserProfile>(
          stream: ProfileFirestoreService.instance.getProfileStream(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _statusMessage('Could not load your profile.');
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
                  return _statusMessage('Could not load workout history.');
                }
                if (!workoutsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Most recent first, capped to a small recent window - the
                // recommendation engine only looks at the last couple of
                // sessions for rotation purposes.
                final recentWorkouts = workoutsSnapshot.data!.take(5).toList();

                final recommendation =
                    RecommendationService().generateRecommendation(
                  profile: profile,
                  recentWorkouts: recentWorkouts,
                  // calorieSummary, availableEquipment, injuredMuscleGroups
                  // intentionally omitted - not built yet. Add them here
                  // once those features exist; no other change needed.
                );

                return _content(context, profile, recommendation);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _statusMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: greyText, fontSize: 16),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    UserProfile profile,
    DailyRecommendation recommendation,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${profile.displayName.isNotEmpty ? profile.displayName : 'there'}!',
            style: const TextStyle(
              color: darkText,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ready to crush your goals today?',
            style: TextStyle(color: greyText, fontSize: 15),
          ),
          const SizedBox(height: 24),
          _recommendationCard(context, recommendation),
          const SizedBox(height: 20),
          _whyThisWorkoutCard(recommendation),
          const SizedBox(height: 24),
          _actionButtons(context),
        ],
      ),
    );
  }

  Widget _recommendationCard(
    BuildContext context,
    DailyRecommendation recommendation,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Recommendation",
            style: TextStyle(color: greyText, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.title,
            style: const TextStyle(
              color: darkText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _infoChip(Icons.timer_outlined, '${recommendation.durationMinutes} min'),
              const SizedBox(width: 10),
              _infoChip(Icons.bar_chart_rounded, recommendation.difficulty),
              const SizedBox(width: 10),
              _infoChip(Icons.fitness_center_rounded, recommendation.targetMuscles),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
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
              style: const TextStyle(
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

  Widget _whyThisWorkoutCard(DailyRecommendation recommendation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why this workout?',
            style: TextStyle(
              color: darkText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...recommendation.reasonBullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: primaryBlue)),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(color: greyText, fontSize: 14),
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

  Widget _actionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            // TODO: wire to Active Workout screen once built (screen 5 in
            // the detailed wireflow).
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Start Workout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            // TODO: wire to Customize Plan screen (flow B) once built.
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: TextButton(
            // TODO: wire to Update Recommendation screen (flow C) once built.
            onPressed: () {},
            child: const Text(
              'Update Recommendation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: greyText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
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