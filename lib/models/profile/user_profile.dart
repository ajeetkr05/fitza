import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  static const String systemTheme = 'system';
  static const String lightTheme = 'light';
  static const String darkTheme = 'dark';

  final String uid;
  final String email;
  final String displayName;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String goal;
  final String activityLevel;
  final String gender;
  final String location;
  final String workoutPreference;
  final String dietaryPreference;
  final String fitnessExperience;
  final bool profileSetupCompleted;

  /// Stored as: system, light, or dark.
  final String themeMode;

  /// Kept for compatibility with older parts of the app and older
  /// Firestore documents. New theme changes should use [themeMode].
  final bool darkModeEnabled;

  final bool notificationsEnabled;
  final bool workoutRemindersEnabled;

  // Custom target values
  final double? targetCalories;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFat;
  final int? targetWaterMl;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activityLevel,
    required this.gender,
    required this.location,
    required this.workoutPreference,
    required this.dietaryPreference,
    required this.fitnessExperience,
    required this.profileSetupCompleted,
    required this.darkModeEnabled,
    required this.notificationsEnabled,
    required this.workoutRemindersEnabled,
    this.themeMode = systemTheme,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
    this.targetWaterMl,
  });

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document, {
    required String fallbackEmail,
    required String fallbackDisplayName,
  }) {
    final data = document.data() ?? <String, dynamic>{};
    final themeMode = _readThemeMode(data);

    return UserProfile(
      uid: document.id,
      email: data['email'] as String? ?? fallbackEmail,
      displayName: data['displayName'] as String? ?? fallbackDisplayName,
      age: (data['age'] as num?)?.toInt(),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      goal: data['goal'] as String? ?? 'Stay Fit',
      activityLevel: data['activityLevel'] as String? ?? 'Moderate',
      gender: data['gender'] as String? ?? 'Prefer not to say',
      location: data['location'] as String? ?? 'Home',
      workoutPreference: data['workoutPreference'] as String? ?? 'Both',
      dietaryPreference: data['dietaryPreference'] as String? ?? 'Not set',
      fitnessExperience: data['fitnessExperience'] as String? ?? 'Beginner',
      profileSetupCompleted:
          data['profileSetupCompleted'] as bool? ?? false,
      themeMode: themeMode,
      darkModeEnabled: themeMode == darkTheme,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      workoutRemindersEnabled:
          data['workoutRemindersEnabled'] as bool? ?? true,
      targetCalories: (data['targetCalories'] as num?)?.toDouble(),
      targetProtein: (data['targetProtein'] as num?)?.toDouble(),
      targetCarbs: (data['targetCarbs'] as num?)?.toDouble(),
      targetFat: (data['targetFat'] as num?)?.toDouble(),
      targetWaterMl: (data['targetWaterMl'] as num?)?.toInt(),
    );
  }

  static String _readThemeMode(Map<String, dynamic> data) {
    final storedThemeMode = data['themeMode'];

    if (storedThemeMode is String &&
        const {systemTheme, lightTheme, darkTheme}.contains(storedThemeMode)) {
      return storedThemeMode;
    }

    final legacyDarkModeEnabled =
        data['darkModeEnabled'] as bool? ?? false;

    return legacyDarkModeEnabled ? darkTheme : systemTheme;
  }
}
