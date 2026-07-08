import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/progress/weight_entry.dart';
import '../../services/auth/auth_service.dart';
import '../../services/progress/weight_firestore_service.dart';
import '../../widgets/app_bottom_navigation.dart';
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

  bool _notificationsEnabled = true;
  bool _workoutRemindersEnabled = true;
  bool _darkModeEnabled = false;

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

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be added later.'),
      ),
    );
  }

  String _userEmail(User? user) {
    final email = user?.email?.trim();

    if (email == null || email.isEmpty) {
      return 'No email found';
    }

    return email;
  }

  String _displayName(User? user) {
    final email = user?.email?.trim();

    if (email == null || email.isEmpty) {
      return 'Fitza User';
    }

    final namePart = email.split('@').first;

    return namePart
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map(
          (word) => word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
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

  String _formatHeight(WeightEntry? entry) {
    if (entry == null) {
      return '—';
    }

    return '${entry.heightCm.toStringAsFixed(0)} cm';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: widget.selectedIndex,
        onTap: widget.onTabChanged,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: StreamBuilder<List<WeightEntry>>(
            stream: WeightFirestoreService.instance.getWeightEntriesStream(),
            builder: (context, snapshot) {
              final latestEntry = snapshot.hasData
                  ? _latestWeightEntry(snapshot.data!)
                  : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(),
                  const SizedBox(height: 20),
                  _profileHeroCard(
                    user: user,
                    latestEntry: latestEntry,
                  ),
                  const SizedBox(height: 18),
                  _profileStatsGrid(latestEntry),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'Preferences',
                    children: [
                      _switchRow(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });

                          _showComingSoon('Dark mode');
                        },
                      ),
                      _divider(),
                      _switchRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                      _divider(),
                      _switchRow(
                        icon: Icons.event_available_outlined,
                        title: 'Workout Reminders',
                        value: _workoutRemindersEnabled,
                        onChanged: (value) {
                          setState(() {
                            _workoutRemindersEnabled = value;
                          });
                        },
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
                        onTap: () => _showComingSoon('Edit profile'),
                      ),
                      _divider(),
                      _navigationRow(
                        icon: Icons.badge_outlined,
                        title: 'Personal Details',
                        onTap: () => _showComingSoon('Personal details'),
                      ),
                      _divider(),
                      _navigationRow(
                        icon: Icons.fitness_center_outlined,
                        title: 'Workout History',
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
                        onTap: () => _showComingSoon('Privacy and security'),
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
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        const Icon(
          Icons.bolt_rounded,
          color: primaryBlue,
          size: 36,
        ),
        const SizedBox(width: 8),
        const Text(
          'Fitza',
          style: TextStyle(
            color: darkText,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        const Text(
          'Profile',
          style: TextStyle(
            color: darkText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _showComingSoon('Profile settings'),
          icon: const Icon(
            Icons.settings_outlined,
            color: darkText,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _profileHeroCard({
    required User? user,
    required WeightEntry? latestEntry,
  }) {
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
                  _displayName(user),
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
                  _userEmail(user),
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

  Widget _profileStatsGrid(WeightEntry? latestEntry) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _smallStatCard(
                icon: Icons.calendar_today_outlined,
                value: '—',
                label: 'Age',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallStatCard(
                icon: Icons.height_rounded,
                value: _formatHeight(latestEntry),
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
                value: 'Stay Fit',
                label: 'Goal',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallStatCard(
                icon: Icons.bar_chart_rounded,
                value: 'Moderate',
                label: 'Activity',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallStatCard(
                icon: Icons.location_on_outlined,
                value: 'Home',
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
                    fontSize: 17,
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