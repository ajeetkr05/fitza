import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/profile/user_profile.dart';
import '../../models/progress/weight_entry.dart';
import '../../models/progress/workout_entry.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../../services/progress/weight_firestore_service.dart';
import '../../services/progress/workout_firestore_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../progress/exercise_history/exercise_history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const ProfileScreen({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color orange = Colors.orange;

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _softBackground(BuildContext context, Color color) {
    return color.withValues(alpha: _isDark(context) ? 0.20 : 0.10);
  }

  WeightEntry? _latestWeightEntry(List<WeightEntry> entries) {
    if (entries.isEmpty) {
      return null;
    }

    return entries.last;
  }

  String _formatWeight(UserProfile profile, WeightEntry? entry) {
    final weight = entry?.weightKg ?? profile.weightKg;

    if (weight == null) {
      return '—';
    }

    return '${weight.toStringAsFixed(1)} kg';
  }

  String _formatHeight(UserProfile profile, WeightEntry? entry) {
    final height = entry?.heightCm ?? profile.heightCm;

    if (height == null) {
      return '—';
    }

    return '${height.toStringAsFixed(0)} cm';
  }

  String _formatAge(UserProfile profile) {
    if (profile.age == null) {
      return '—';
    }

    return profile.age.toString();
  }

  String _currentBmi(UserProfile profile, WeightEntry? entry) {
    final weight = entry?.weightKg ?? profile.weightKg;
    final height = entry?.heightCm ?? profile.heightCm;

    if (weight == null || height == null || height <= 0) {
      return '—';
    }

    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);

    return bmi.toStringAsFixed(1);
  }

  int _currentStreak(List<WorkoutEntry> workouts) {
    if (workouts.isEmpty) {
      return 0;
    }

    final workoutDays = workouts.map((workout) {
      final date = workout.recordedAt;
      return DateTime(date.year, date.month, date.day);
    }).toSet();

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterday = todayOnly.subtract(const Duration(days: 1));

    DateTime cursor;

    if (workoutDays.contains(todayOnly)) {
      cursor = todayOnly;
    } else if (workoutDays.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }

    var streak = 0;

    while (workoutDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String _memberSinceText(UserProfile profile) {
    return profile.profileSetupCompleted ? 'Active' : 'New';
  }

  Future<void> _openSettings(UserProfile profile) async {
    final updatedProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(profile: profile),
      ),
    );

    if (updatedProfile != null && mounted) {
      FitzaThemeController.setDarkModeEnabled(updatedProfile.darkModeEnabled);
    }
  }

  Future<void> _showEditProfileSheet(
    UserProfile profile, {
    bool focusGoal = false,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: profile.displayName,
    );

    final ageController = TextEditingController(
      text: profile.age == null ? '' : profile.age.toString(),
    );

    final goalOptions = [
      'Lose Weight',
      'Gain Muscle',
      'Stay Fit',
      'Improve Endurance',
      'Build Strength',
    ];

    final activityOptions = [
      'Low',
      'Moderate',
      'High',
      'Very Active',
    ];

    final locationOptions = [
      'Home',
      'Gym',
      'Gym & Home',
      'Outdoor',
    ];

    String selectedGoal =
        goalOptions.contains(profile.goal) ? profile.goal : 'Stay Fit';

    String selectedActivity = activityOptions.contains(profile.activityLevel)
        ? profile.activityLevel
        : 'Moderate';

    String selectedLocation =
        locationOptions.contains(profile.location) ? profile.location : 'Home';

    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final fitzaColors = _colors(sheetContext);

            Future<void> saveProfile() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setSheetState(() {
                isSaving = true;
              });

              try {
                await ProfileFirestoreService.instance.updateProfileDetails(
                  displayName: nameController.text.trim(),
                  age: ageController.text.trim().isEmpty
                      ? null
                      : int.tryParse(ageController.text.trim()),
                  goal: selectedGoal,
                  activityLevel: selectedActivity,
                  location: selectedLocation,
                );

                if (!sheetContext.mounted) {
                  return;
                }

                Navigator.pop(sheetContext);
              } catch (_) {
                if (!sheetContext.mounted) {
                  return;
                }

                setSheetState(() {
                  isSaving = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not save profile. Please try again.'),
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: fitzaColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: 4,
                              width: 44,
                              decoration: BoxDecoration(
                                color: fitzaColors.border,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            focusGoal ? 'Update Fitness Goal' : 'Edit Profile',
                            style: TextStyle(
                              color: fitzaColors.primaryText,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (!focusGoal) ...[
                            TextFormField(
                              controller: nameController,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(
                                color: fitzaColors.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _inputDecoration(
                                sheetContext,
                                label: 'Display Name',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Enter your display name.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            TextFormField(
                              controller: ageController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(
                                color: fitzaColors.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _inputDecoration(
                                sheetContext,
                                label: 'Age',
                                icon: Icons.calendar_today_outlined,
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';

                                if (text.isEmpty) {
                                  return null;
                                }

                                final age = int.tryParse(text);

                                if (age == null || age < 10 || age > 100) {
                                  return 'Enter a valid age between 10 and 100.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),
                          ],

                          DropdownButtonFormField<String>(
                            value: selectedGoal,
                            dropdownColor: fitzaColors.surface,
                            decoration: _inputDecoration(
                              sheetContext,
                              label: 'Goal',
                              icon: Icons.track_changes_rounded,
                            ),
                            style: TextStyle(
                              color: fitzaColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                            items: goalOptions
                                .map(
                                  (goal) => DropdownMenuItem(
                                    value: goal,
                                    child: Text(goal),
                                  ),
                                )
                                .toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setSheetState(() {
                                      selectedGoal = value;
                                    });
                                  },
                          ),

                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            value: selectedActivity,
                            dropdownColor: fitzaColors.surface,
                            decoration: _inputDecoration(
                              sheetContext,
                              label: 'Activity Level',
                              icon: Icons.bar_chart_rounded,
                            ),
                            style: TextStyle(
                              color: fitzaColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                            items: activityOptions
                                .map(
                                  (activity) => DropdownMenuItem(
                                    value: activity,
                                    child: Text(activity),
                                  ),
                                )
                                .toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setSheetState(() {
                                      selectedActivity = value;
                                    });
                                  },
                          ),

                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            value: selectedLocation,
                            dropdownColor: fitzaColors.surface,
                            decoration: _inputDecoration(
                              sheetContext,
                              label: 'Workout Location',
                              icon: Icons.location_on_outlined,
                            ),
                            style: TextStyle(
                              color: fitzaColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                            items: locationOptions
                                .map(
                                  (location) => DropdownMenuItem(
                                    value: location,
                                    child: Text(location),
                                  ),
                                )
                                .toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setSheetState(() {
                                      selectedLocation = value;
                                    });
                                  },
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isSaving ? null : saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fitzaColors.primaryBlue,
                                foregroundColor: fitzaColors.textOnBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isSaving
                                  ? SizedBox(
                                      height: 23,
                                      width: 23,
                                      child: CircularProgressIndicator(
                                        color: fitzaColors.textOnBlue,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        color: fitzaColors.textOnBlue,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    ageController.dispose();
  }

Future<void> _showEditTargetsSheet(UserProfile profile) async {
  final messenger = ScaffoldMessenger.of(context);

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _EditTargetsSheet(profile: profile),
  );

  if (result == true && mounted) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Nutrition targets updated successfully.'),
        backgroundColor: successGreen,
      ),
    );
  }
}

void _showComingSoon(String title) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$title will be added later.'),
    ),
  );
}
     
  

  @override
  Widget build(BuildContext context) {
    final fitzaColors = _colors(context);

    return Scaffold(
      backgroundColor: fitzaColors.background,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: widget.selectedIndex,
        onTap: widget.onTabChanged,
      ),
      body: SafeArea(
        child: StreamBuilder<UserProfile>(
          stream: ProfileFirestoreService.instance.getProfileStream(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _statusScreen(
                message: 'Could not load profile details.',
                icon: Icons.error_outline_rounded,
                iconColor: Colors.red,
              );
            }

            if (!profileSnapshot.hasData) {
              return _statusScreen(
                message: 'Loading profile...',
                icon: Icons.hourglass_top_rounded,
                iconColor: fitzaColors.primaryBlue,
                isLoading: true,
              );
            }

            final profile = profileSnapshot.data!;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              FitzaThemeController.setDarkModeEnabled(
                profile.darkModeEnabled,
              );
            });

            return StreamBuilder<List<WeightEntry>>(
              stream: WeightFirestoreService.instance.getWeightEntriesStream(),
              builder: (context, weightSnapshot) {
                final latestEntry = weightSnapshot.hasData
                    ? _latestWeightEntry(weightSnapshot.data!)
                    : null;

                return StreamBuilder<List<WorkoutEntry>>(
                  stream:
                      WorkoutFirestoreService.instance.getWorkoutEntriesStream(),
                  builder: (context, workoutSnapshot) {
                    final List<WorkoutEntry> workouts = workoutSnapshot.hasData
                        ? workoutSnapshot.data!
                        : <WorkoutEntry>[];

                    final streak = _currentStreak(workouts);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _topBar(profile),

                          const SizedBox(height: 14),

                          _profileHeroCard(profile),

                          const SizedBox(height: 14),

                          _sectionTitle('Personal Fitness Details'),

                          const SizedBox(height: 10),

                          _detailsGrid(
                            items: [
                              _ProfileInfoItem(
                                icon: Icons.calendar_today_outlined,
                                value: _formatAge(profile),
                                label: 'Age',
                                color: primaryBlue,
                              ),
                              _ProfileInfoItem(
                                icon: Icons.height_rounded,
                                value: _formatHeight(profile, latestEntry),
                                label: 'Height',
                                color: primaryBlue,
                              ),
                              _ProfileInfoItem(
                                icon: Icons.monitor_weight_outlined,
                                value: _formatWeight(profile, latestEntry),
                                label: 'Weight',
                                color: primaryBlue,
                              ),
                              _ProfileInfoItem(
                                icon: Icons.track_changes_rounded,
                                value: profile.goal,
                                label: 'Goal',
                                color: successGreen,
                              ),
                              _ProfileInfoItem(
                                icon: Icons.bar_chart_rounded,
                                value: profile.activityLevel,
                                label: 'Activity Level',
                                color: orange,
                              ),
                              _ProfileInfoItem(
                                icon: Icons.location_on_outlined,
                                value: profile.location,
                                label: 'Workout Location',
                                color: accentBlue,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _sectionTitle('Fitness Summary'),

                          const SizedBox(height: 10),

                          _summaryGrid(
                            items: [
                              _ProfileInfoItem(
                                icon: Icons.monitor_weight_outlined,
                                value: _currentBmi(profile, latestEntry),
                                label: 'Current BMI',
                                color: primaryBlue,
                              ),
                              _ProfileInfoItem(
                                icon: Icons.local_fire_department_outlined,
                                value: '$streak days',
                                label: 'Current Streak',
                                color: orange,
                              ),
                              _ProfileInfoItem(
                                icon: Icons.fitness_center_outlined,
                                value: workouts.length.toString(),
                                label: 'Workouts Completed',
                                color: successGreen,
                              ),
                              _ProfileInfoItem(
                                icon: Icons.workspace_premium_outlined,
                                value: _memberSinceText(profile),
                                label: 'Member Since',
                                color: accentBlue,
                              ),
                            ],
                          ),
const SizedBox(height: 16),

_sectionCard(
  title: 'Profile Actions',
  children: [
    _navigationRow(
      icon: Icons.person_outline_rounded,
      title: 'Edit Profile',
      subtitle: 'Update your basic profile details',
      onTap: () => _showEditProfileSheet(profile),
    ),
    _divider(),
    _navigationRow(
      icon: Icons.track_changes_rounded,
      title: 'Update Fitness Goal',
      subtitle: 'Change your goal and activity level',
      onTap: () => _showEditProfileSheet(
        profile,
        focusGoal: true,
      ),
    ),
    _divider(),
    _navigationRow(
      icon: Icons.local_fire_department_outlined,
      title: 'Nutrition Targets',
      subtitle: 'Set calories, macros and water goals',
      onTap: () => _showEditTargetsSheet(profile),
    ),
    _divider(),
    _navigationRow(
      icon: Icons.fitness_center_outlined,
      title: 'Workout History',
      subtitle: 'View your saved workout sessions',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ExerciseHistoryScreen(),
          ),
        );
      },
    ),
    _divider(),
    _navigationRow(
      icon: Icons.emoji_events_outlined,
      title: 'View Achievements',
      subtitle: 'Badges and milestones',
      onTap: () => _showComingSoon('Achievements'),
    ),
    _divider(),
    _navigationRow(
      icon: Icons.leaderboard_outlined,
      title: 'View Personal Records',
      subtitle: 'Best lifts and workout records',
      onTap: () => _showComingSoon('Personal records'),
    ),
  ],
),
                            ],
                          ),
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

  Widget _topBar(UserProfile profile) {
    final fitzaColors = _colors(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        InkWell(
          onTap: () => _openSettings(profile),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: fitzaColors.surface,
              borderRadius: BorderRadius.circular(16),
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
            child: Icon(
              Icons.settings_outlined,
              color: fitzaColors.primaryText,
              size: 25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileHeroCard(UserProfile profile) {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fitzaColors.surface,
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _softBackground(context, fitzaColors.primaryBlue),
                  border: Border.all(
                    color: fitzaColors.primaryBlue,
                    width: 2.4,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: fitzaColors.primaryBlue,
                  size: 44,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: () => _showComingSoon('Profile photo update'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentBlue,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fitzaColors.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fitzaColors.secondaryText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditProfileSheet(profile),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 17,
                    ),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fitzaColors.primaryBlue,
                      side: BorderSide(
                        color: fitzaColors.primaryBlue.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final fitzaColors = _colors(context);

    return Text(
      title,
      style: TextStyle(
        color: fitzaColors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _detailsGrid({
    required List<_ProfileInfoItem> items,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _detailCard(items[0])),
            const SizedBox(width: 10),
            Expanded(child: _detailCard(items[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _detailCard(items[2])),
            const SizedBox(width: 10),
            Expanded(child: _detailCard(items[3])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _detailCard(items[4])),
            const SizedBox(width: 10),
            Expanded(child: _detailCard(items[5])),
          ],
        ),
      ],
    );
  }

  Widget _summaryGrid({
    required List<_ProfileInfoItem> items,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard(items[0])),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard(items[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _summaryCard(items[2])),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard(items[3])),
          ],
        ),
      ],
    );
  }

  Widget _detailCard(_ProfileInfoItem item) {
    final fitzaColors = _colors(context);

    return Container(
      height: 78,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _smallIconBox(item.icon, item.color),
          const SizedBox(width: 10),
          Expanded(
            child: _infoText(
              value: item.value,
              label: item.label,
              fitzaColors: fitzaColors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(_ProfileInfoItem item) {
    final fitzaColors = _colors(context);

    return Container(
      height: 78,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _smallIconBox(item.icon, item.color),
          const SizedBox(width: 10),
          Expanded(
            child: _infoText(
              value: item.value,
              label: item.label,
              fitzaColors: fitzaColors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallIconBox(IconData icon, Color color) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: _softBackground(context, color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 21,
      ),
    );
  }

  Widget _infoText({
    required String value,
    required String label,
    required FitzaThemeColors fitzaColors,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fitzaColors.primaryText,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fitzaColors.secondaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: fitzaColors.primaryBlue,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _navigationRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final fitzaColors = _colors(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.5),
        child: Row(
          children: [
            _smallIconBox(icon, fitzaColors.primaryBlue),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fitzaColors.secondaryText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: fitzaColors.secondaryText,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    final fitzaColors = _colors(context);

    return Divider(
      height: 1,
      color: fitzaColors.border,
    );
  }

  Widget _statusScreen({
    required String message,
    required IconData icon,
    required Color iconColor,
    bool isLoading = false,
  }) {
    final fitzaColors = _colors(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              CircularProgressIndicator(
                color: fitzaColors.primaryBlue,
              )
            else
              Icon(
                icon,
                color: iconColor,
                size: 48,
              ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fitzaColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final fitzaColors = _colors(context);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: fitzaColors.primaryBlue,
      ),
      filled: true,
      fillColor: fitzaColors.inputSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: fitzaColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: fitzaColors.primaryBlue,
          width: 1.7,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    final fitzaColors = _colors(context);

    return BoxDecoration(
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
    );
  }
}

class _EditTargetsSheet extends StatefulWidget {
  final UserProfile profile;

  const _EditTargetsSheet({
    required this.profile,
  });

  @override
  State<_EditTargetsSheet> createState() => _EditTargetsSheetState();
}

class _EditTargetsSheetState extends State<_EditTargetsSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _waterController;

  bool _isSaving = false;

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  @override
  void initState() {
    super.initState();

    _caloriesController = TextEditingController(
      text: (widget.profile.targetCalories ?? 2200.0).toStringAsFixed(0),
    );

    _proteinController = TextEditingController(
      text: (widget.profile.targetProtein ?? 120.0).toStringAsFixed(0),
    );

    _carbsController = TextEditingController(
      text: (widget.profile.targetCarbs ?? 275.0).toStringAsFixed(0),
    );

    _fatController = TextEditingController(
      text: (widget.profile.targetFat ?? 73.0).toStringAsFixed(0),
    );

    _waterController = TextEditingController(
      text: (widget.profile.targetWaterMl ?? 3000).toString(),
    );
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    FocusManager.instance.primaryFocus?.unfocus();

    try {
      await ProfileFirestoreService.instance.updateProfileTargets(
        targetCalories: double.parse(_caloriesController.text.trim()),
        targetProtein: double.parse(_proteinController.text.trim()),
        targetCarbs: double.parse(_carbsController.text.trim()),
        targetFat: double.parse(_fatController.text.trim()),
        targetWaterMl: int.parse(_waterController.text.trim()),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save targets: $error'),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    final fitzaColors = _colors(context);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: fitzaColors.primaryBlue,
      ),
      filled: true,
      fillColor: fitzaColors.inputSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: fitzaColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: fitzaColors.primaryBlue,
          width: 1.7,
        ),
      ),
    );
  }

  String? _validateDouble(String? value, String fieldName) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter $fieldName.';
    }

    final number = double.tryParse(text);

    if (number == null || number < 0) {
      return 'Enter a valid $fieldName.';
    }

    return null;
  }

  String? _validateInt(String? value, String fieldName) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter $fieldName.';
    }

    final number = int.tryParse(text);

    if (number == null || number < 0) {
      return 'Enter a valid $fieldName.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fitzaColors = _colors(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: fitzaColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 44,
                      decoration: BoxDecoration(
                        color: fitzaColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Edit Nutrition Targets',
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                      label: 'Calorie Target (kcal)',
                      icon: Icons.local_fire_department_outlined,
                    ),
                    validator: (value) => _validateDouble(
                      value,
                      'calorie target',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                      label: 'Protein Target (g)',
                      icon: Icons.fitness_center_outlined,
                    ),
                    validator: (value) => _validateDouble(
                      value,
                      'protein target',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                      label: 'Carbohydrate Target (g)',
                      icon: Icons.grain_outlined,
                    ),
                    validator: (value) => _validateDouble(
                      value,
                      'carbohydrate target',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                      label: 'Fat Target (g)',
                      icon: Icons.opacity_outlined,
                    ),
                    validator: (value) => _validateDouble(
                      value,
                      'fat target',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _waterController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      color: fitzaColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                      label: 'Water Intake Target (ml)',
                      icon: Icons.water_drop_outlined,
                    ),
                    validator: (value) => _validateInt(
                      value,
                      'water target',
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: fitzaColors.primaryBlue,
                        foregroundColor: fitzaColors.textOnBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 23,
                              width: 23,
                              child: CircularProgressIndicator(
                                color: fitzaColors.textOnBlue,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Save Targets',
                              style: TextStyle(
                                color: fitzaColors.textOnBlue,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ProfileInfoItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}