import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final int? age;
  final double? heightCm;
  final String goal;
  final String activityLevel;
  final String location;
  final bool darkModeEnabled;
  final bool notificationsEnabled;
  final bool workoutRemindersEnabled;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.age,
    required this.heightCm,
    required this.goal,
    required this.activityLevel,
    required this.location,
    required this.darkModeEnabled,
    required this.notificationsEnabled,
    required this.workoutRemindersEnabled,
  });

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document, {
    required String fallbackEmail,
    required String fallbackDisplayName,
  }) {
    final data = document.data() ?? <String, dynamic>{};

    return UserProfile(
      uid: document.id,
      email: data['email'] as String? ?? fallbackEmail,
      displayName: data['displayName'] as String? ?? fallbackDisplayName,
      age: (data['age'] as num?)?.toInt(),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      goal: data['goal'] as String? ?? 'Stay Fit',
      activityLevel: data['activityLevel'] as String? ?? 'Moderate',
      location: data['location'] as String? ?? 'Home',
      darkModeEnabled: data['darkModeEnabled'] as bool? ?? false,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      workoutRemindersEnabled:
          data['workoutRemindersEnabled'] as bool? ?? true,
    );
  }
}