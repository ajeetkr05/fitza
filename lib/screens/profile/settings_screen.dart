import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/profile/user_profile.dart';
import '../../services/auth/auth_service.dart';
import '../../services/profile/profile_firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile profile;

  const SettingsScreen({
    super.key,
    required this.profile,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color dangerRed = Color(0xFFD32F2F);

  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FitzaThemeController.setDarkModeEnabled(_profile.darkModeEnabled);
    });
  }

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _softBackground(BuildContext context, Color color) {
    return color.withValues(alpha: _isDark(context) ? 0.20 : 0.10);
  }

  Future<void> _updatePreference({
    required String fieldName,
    required bool value,
  }) async {
    final previousProfile = _profile;

    setState(() {
      _profile = _profile.copyWithPreference(
        fieldName: fieldName,
        value: value,
      );
    });

    if (fieldName == 'darkModeEnabled') {
      FitzaThemeController.setDarkModeEnabled(value);
    }

    try {
      await ProfileFirestoreService.instance.updatePreference(
        fieldName: fieldName,
        value: value,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = previousProfile;
      });

      if (fieldName == 'darkModeEnabled') {
        FitzaThemeController.setDarkModeEnabled(
          previousProfile.darkModeEnabled,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update setting. Please try again.'),
        ),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final fitzaColors = _colors(dialogContext);

        return AlertDialog(
          backgroundColor: fitzaColors.surface,
          title: Text(
            'Log out?',
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'You will need to log in again to access your Fitza account.',
            style: TextStyle(
              color: fitzaColors.secondaryText,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Log Out',
                style: TextStyle(color: dangerRed),
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
          content: Text('Could not log out. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showEditProfileSheet() async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: _profile.displayName,
    );

    final ageController = TextEditingController(
      text: _profile.age == null ? '' : _profile.age.toString(),
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
        goalOptions.contains(_profile.goal) ? _profile.goal : 'Stay Fit';

    String selectedActivity = activityOptions.contains(_profile.activityLevel)
        ? _profile.activityLevel
        : 'Moderate';

    String selectedLocation =
        locationOptions.contains(_profile.location) ? _profile.location : 'Home';

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

              final updatedName = nameController.text.trim();
              final updatedAge = ageController.text.trim().isEmpty
                  ? null
                  : int.tryParse(ageController.text.trim());

              try {
                await ProfileFirestoreService.instance.updateProfileDetails(
                  displayName: updatedName,
                  age: updatedAge,
                  goal: selectedGoal,
                  activityLevel: selectedActivity,
                  location: selectedLocation,
                );

                if (!mounted || !sheetContext.mounted) {
                  return;
                }

                setState(() {
                  _profile = _profile.copyWithProfileDetails(
                    displayName: updatedName,
                    age: updatedAge,
                    goal: selectedGoal,
                    activityLevel: selectedActivity,
                    location: selectedLocation,
                  );
                });

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
                            'Edit Profile',
                            style: TextStyle(
                              color: fitzaColors.primaryText,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
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
                              label: 'Location',
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
                                      'Save Profile',
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

  void _showAccountInfo() {
    final fitzaColors = _colors(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: fitzaColors.surface,
          title: Text(
            'Account Information',
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogInfoLine('Name', _profile.displayName),
              const SizedBox(height: 12),
              _dialogInfoLine('Email', _profile.email),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogInfoLine(String label, String value) {
    final fitzaColors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: fitzaColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: fitzaColors.primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context),

              const SizedBox(height: 16),

              _accountHeader(),

              const SizedBox(height: 14),

              _sectionCard(
                title: 'Account',
                children: [
                  _navigationRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Update your name and fitness details',
                    onTap: _showEditProfileSheet,
                  ),
                  _divider(),
                  _navigationRow(
                    icon: Icons.alternate_email_rounded,
                    title: 'Email / Account Information',
                    subtitle: _profile.email,
                    onTap: _showAccountInfo,
                  ),
                  _divider(),
                  _navigationRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your login password',
                    onTap: () => _showComingSoon('Change password'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                title: 'App Preferences',
                children: [
                  _switchRow(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Use Fitza in dark theme',
                    value: _profile.darkModeEnabled,
                    onChanged: (value) => _updatePreference(
                      fieldName: 'darkModeEnabled',
                      value: value,
                    ),
                  ),
                  _divider(),
                  _switchRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Receive app notifications',
                    value: _profile.notificationsEnabled,
                    onChanged: (value) => _updatePreference(
                      fieldName: 'notificationsEnabled',
                      value: value,
                    ),
                  ),
                  _divider(),
                  _switchRow(
                    icon: Icons.event_available_outlined,
                    title: 'Workout Reminders',
                    subtitle: 'Get reminders for workouts',
                    value: _profile.workoutRemindersEnabled,
                    onChanged: (value) => _updatePreference(
                      fieldName: 'workoutRemindersEnabled',
                      value: value,
                    ),
                  ),
                  _divider(),
                  _navigationRow(
                    icon: Icons.straighten_rounded,
                    title: 'Measurement Units',
                    subtitle: 'kg, cm and other units',
                    onTap: () => _showComingSoon('Measurement units'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                title: 'Privacy & Data',
                children: [
                  _navigationRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Settings',
                    subtitle: 'Manage privacy preferences',
                    onTap: () => _showComingSoon('Privacy settings'),
                  ),
                  _divider(),
                  _navigationRow(
                    icon: Icons.download_outlined,
                    title: 'Export Data',
                    subtitle: 'Download your Fitza data',
                    onTap: () => _showComingSoon('Export data'),
                  ),
                  _divider(),
                  _navigationRow(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your account',
                    iconColor: dangerRed,
                    titleColor: dangerRed,
                    onTap: () => _showComingSoon('Delete account'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                title: 'Support',
                children: [
                  _navigationRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Help and Feedback',
                    subtitle: 'Get support or send feedback',
                    onTap: () => _showComingSoon('Help and feedback'),
                  ),
                  _divider(),
                  _navigationRow(
                    icon: Icons.info_outline_rounded,
                    title: 'About Fitza',
                    subtitle: 'App version and information',
                    onTap: () => _showComingSoon('About Fitza'),
                  ),
                  _divider(),
                  _navigationRow(
                    icon: Icons.description_outlined,
                    title: 'Terms and Privacy Policy',
                    subtitle: 'Read Fitza policies',
                    onTap: () => _showComingSoon('Terms and privacy policy'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dangerRed,
                    side: BorderSide(
                      color: dangerRed.withValues(alpha: 0.45),
                      width: 1.4,
                    ),
                    backgroundColor: fitzaColors.surface,
                    textStyle: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final fitzaColors = _colors(context);

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context, _profile),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: fitzaColors.primaryText,
            size: 29,
          ),
        ),
        Expanded(
          child: Text(
            'Settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fitzaColors.primaryText,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _accountHeader() {
    final fitzaColors = _colors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: _softBackground(context, fitzaColors.primaryBlue),
            child: Icon(
              Icons.person_rounded,
              color: fitzaColors.primaryBlue,
              size: 31,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fitzaColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fitzaColors.secondaryText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
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

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final fitzaColors = _colors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _rowIcon(icon, fitzaColors.primaryBlue),
          const SizedBox(width: 13),
          Expanded(
            child: _rowText(
              title: title,
              subtitle: subtitle,
            ),
          ),
          Switch(
            value: value,
            activeColor: fitzaColors.textOnBlue,
            activeTrackColor: fitzaColors.primaryBlue,
            inactiveThumbColor: fitzaColors.textOnBlue,
            inactiveTrackColor:
                _isDark(context) ? const Color(0xFF4A4A4A) : const Color(0xFFD1D5DB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _navigationRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final fitzaColors = _colors(context);
    final rowIconColor = iconColor ?? fitzaColors.primaryBlue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.5),
        child: Row(
          children: [
            _rowIcon(icon, rowIconColor),
            const SizedBox(width: 13),
            Expanded(
              child: _rowText(
                title: title,
                subtitle: subtitle,
                titleColor: titleColor,
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

  Widget _rowIcon(IconData icon, Color color) {
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

  Widget _rowText({
    required String title,
    required String subtitle,
    Color? titleColor,
  }) {
    final fitzaColors = _colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor ?? fitzaColors.primaryText,
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
    );
  }

  Widget _divider() {
    final fitzaColors = _colors(context);

    return Divider(
      height: 1,
      color: fitzaColors.border,
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

extension _SettingsProfileCopy on UserProfile {
  UserProfile copyWithPreference({
    required String fieldName,
    required bool value,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      goal: goal,
      activityLevel: activityLevel,
      gender: gender,
      location: location,
      workoutPreference: workoutPreference,
      dietaryPreference: dietaryPreference,
      fitnessExperience: fitnessExperience,
      profileSetupCompleted: profileSetupCompleted,
      darkModeEnabled:
          fieldName == 'darkModeEnabled' ? value : darkModeEnabled,
      notificationsEnabled:
          fieldName == 'notificationsEnabled' ? value : notificationsEnabled,
      workoutRemindersEnabled: fieldName == 'workoutRemindersEnabled'
          ? value
          : workoutRemindersEnabled,
    );
  }

  UserProfile copyWithProfileDetails({
    required String displayName,
    required int? age,
    required String goal,
    required String activityLevel,
    required String location,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      goal: goal,
      activityLevel: activityLevel,
      gender: gender,
      location: location,
      workoutPreference: workoutPreference,
      dietaryPreference: dietaryPreference,
      fitnessExperience: fitnessExperience,
      profileSetupCompleted: profileSetupCompleted,
      darkModeEnabled: darkModeEnabled,
      notificationsEnabled: notificationsEnabled,
      workoutRemindersEnabled: workoutRemindersEnabled,
    );
  }
}