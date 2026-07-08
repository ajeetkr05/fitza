import 'package:flutter/material.dart';

import '../../models/profile/user_profile.dart';
import '../../models/progress/weight_entry.dart';
import '../../services/auth/auth_service.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../../services/progress/weight_firestore_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/fitza_header.dart';
import '../progress/exercise_history/exercise_history_screen.dart';

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
  static const Color darkText = Color(0xFF0B1B4D);
  static const Color greyText = Color(0xFF667085);
  static const Color background = Color(0xFFF5F5F5);
  static const Color successGreen = Color(0xFF2E7D32);

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will need to log in again to access your Fitza account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) {
      return;
    }

    try {
      await AuthService.instance.signOut();
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not sign out. Please try again.'),
        ),
      );
    }
  }

  Future<void> _updatePreference({
    required String fieldName,
    required bool value,
  }) async {
    try {
      await ProfileFirestoreService.instance.updatePreference(
        fieldName: fieldName,
        value: value,
      );

      if (fieldName == 'darkModeEnabled' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dark mode preference saved. UI theme will be added later.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update preference. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showEditProfileSheet(UserProfile profile) async {
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
          Future<void> saveProfile() async {
            if (!formKey.currentState!.validate()) {
              return;
            }

            setSheetState(() {
              isSaving = true;
            });

            try {
              await ProfileFirestoreService.instance.updateProfileDetails(
                displayName: nameController.text,
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
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
                                color: const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
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
                            decoration: _inputDecoration(
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
                          DropdownButtonFormField<String>(
                            value: selectedGoal,
                            decoration: _inputDecoration(
                              label: 'Goal',
                              icon: Icons.track_changes_rounded,
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
                            decoration: _inputDecoration(
                              label: 'Activity Level',
                              icon: Icons.bar_chart_rounded,
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
                            decoration: _inputDecoration(
                              label: 'Location',
                              icon: Icons.location_on_outlined,
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
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isSaving ? null : saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 23,
                                      width: 23,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Save Profile',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFD1D5DB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 2,
        ),
      ),
    );
  }

  WeightEntry? _latestWeightEntry(List<WeightEntry> entries) {
    if (entries.isEmpty) {
      return null;
    }

    return entries.last;
  }

  String _formatWeight(WeightEntry? entry) {
    if (entry == null) {
      return '—';
    }

    return '${entry.weightKg.toStringAsFixed(1)} kg';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
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
                iconColor: primaryBlue,
                isLoading: true,
              );
            }

            final profile = profileSnapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: StreamBuilder<List<WeightEntry>>(
                stream: WeightFirestoreService.instance.getWeightEntriesStream(),
                builder: (context, weightSnapshot) {
                  final latestEntry = weightSnapshot.hasData
                      ? _latestWeightEntry(weightSnapshot.data!)
                      : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(),
                      const SizedBox(height: 20),
                      _profileHeroCard(profile),
                      const SizedBox(height: 18),
                      _profileStatsGrid(profile, latestEntry),
                      const SizedBox(height: 18),
                      _sectionCard(
                        title: 'Preferences',
                        children: [
                          _switchRow(
                            icon: Icons.dark_mode_outlined,
                            title: 'Dark Mode',
                            value: profile.darkModeEnabled,
                            onChanged: (value) => _updatePreference(
                              fieldName: 'darkModeEnabled',
                              value: value,
                            ),
                          ),
                          _divider(),
                          _switchRow(
                            icon: Icons.notifications_none_rounded,
                            title: 'Notifications',
                            value: profile.notificationsEnabled,
                            onChanged: (value) => _updatePreference(
                              fieldName: 'notificationsEnabled',
                              value: value,
                            ),
                          ),
                          _divider(),
                          _switchRow(
                            icon: Icons.event_available_outlined,
                            title: 'Workout Reminders',
                            value: profile.workoutRemindersEnabled,
                            onChanged: (value) => _updatePreference(
                              fieldName: 'workoutRemindersEnabled',
                              value: value,
                            ),
                          ),
                          _divider(),
                          _navigationRow(
                            icon: Icons.straighten_rounded,
                            title: 'Measurement Units',
                            onTap: () => _showComingSoon('Measurement units'),
                          ),
                          _divider(),
                          _navigationRow(
                            icon: Icons.volume_up_outlined,
                            title: 'Sound & Haptics',
                            onTap: () => _showComingSoon('Sound and haptics'),
                          ),
                          _divider(),
                          _navigationRow(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy',
                            onTap: () => _showComingSoon('Privacy settings'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _sectionCard(
                        title: 'Account',
                        children: [
                          _navigationRow(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Profile',
                            onTap: () => _showEditProfileSheet(profile),
                          ),
                          _divider(),
                          _navigationRow(
                            icon: Icons.badge_outlined,
                            title: 'Personal Details',
                            onTap: () => _showEditProfileSheet(profile),
                          ),
                          _divider(),
                          _navigationRow(
                            icon: Icons.fitness_center_outlined,
                            title: 'Workout History',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ExerciseHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          _divider(),
                          _navigationRow(
                            icon: Icons.watch_outlined,
                            title: 'Connected Devices',
                            onTap: () => _showComingSoon('Connected devices'),
                          ),
                          _divider(),
                          _navigationRow(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Subscription / Premium',
                            onTap: () => _showComingSoon('Subscription'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _sectionCard(
                        title: 'Support',
                        children: [
                          _navigationRow(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            onTap: () => _showComingSoon('Help and support'),
                          ),
                          _divider(),
                          _navigationRow(
                            icon: Icons.security_outlined,
                            title: 'Privacy & Security',
                            onTap: () =>
                                _showComingSoon('Privacy and security'),
                          ),
                          _divider(),
                          _navigationRow(
                            icon: Icons.info_outline_rounded,
                            title: 'About Fitza',
                            onTap: () => _showComingSoon('About Fitza'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton.icon(
                          onPressed: () => _signOut(context),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryBlue,
                            side: const BorderSide(
                              color: Color(0xFFC8D9F6),
                              width: 1.5,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statusScreen({
    required String message,
    required IconData icon,
    required Color iconColor,
    bool isLoading = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
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
              style: const TextStyle(
                color: darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be added later.'),
      ),
    );
  }

  Widget _topBar() {
    return FitzaHeader(
      centerTitle: 'Profile',
      trailing: FitzaHeaderIconButton(
        icon: Icons.settings_outlined,
        onTap: () => _showComingSoon('Profile settings'),
      ),
    );
  }

  Widget _profileHeroCard(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFEAF3FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFC8D9F6),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                height: 92,
                width: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEAF3FF),
                  border: Border.all(
                    color: primaryBlue,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: primaryBlue,
                  size: 58,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: () => _showComingSoon('Profile photo update'),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentBlue,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: greyText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Active Member',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileStatsGrid(
    UserProfile profile,
    WeightEntry? latestEntry,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _smallStatCard(
                icon: Icons.calendar_today_outlined,
                value: _formatAge(profile),
                label: 'Age',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallStatCard(
                icon: Icons.height_rounded,
                value: _formatHeight(profile, latestEntry),
                label: 'Height',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallStatCard(
                icon: Icons.monitor_weight_outlined,
                value: _formatWeight(latestEntry),
                label: 'Weight',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _smallStatCard(
                icon: Icons.track_changes_rounded,
                value: profile.goal,
                label: 'Goal',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallStatCard(
                icon: Icons.bar_chart_rounded,
                value: profile.activityLevel,
                label: 'Activity',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallStatCard(
                icon: Icons.location_on_outlined,
                value: profile.location,
                label: 'Location',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _smallStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryBlue,
            size: 27,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: greyText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryBlue,
            size: 27,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: darkText,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: primaryBlue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD1D5DB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _navigationRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(
              icon,
              color: primaryBlue,
              size: 27,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: greyText,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      color: Color(0xFFE5EAF2),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: const Color(0xFFE1E7F0),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}