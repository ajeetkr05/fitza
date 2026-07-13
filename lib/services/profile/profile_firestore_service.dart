import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/profile/user_profile.dart';

class ProfileFirestoreService {
  ProfileFirestoreService._();

  static final ProfileFirestoreService instance =
      ProfileFirestoreService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No signed-in user found.');
    }

    return user;
  }

  DocumentReference<Map<String, dynamic>> get _userDocument {
    return _firestore.collection('users').doc(_currentUser.uid);
  }

  CollectionReference<Map<String, dynamic>> get _weightEntriesCollection {
    return _userDocument.collection('weight_entries');
  }

  Stream<UserProfile> getProfileStream() {
    final user = _currentUser;

    return _userDocument.snapshots().map(
          (snapshot) => UserProfile.fromFirestore(
            snapshot,
            fallbackEmail: user.email ?? '',
            fallbackDisplayName: _displayNameFromEmail(user.email),
          ),
        );
  }

  Future<void> saveOnboardingProfile({
    required String displayName,
    required int age,
    required double heightCm,
    required double? weightKg,
    required String goal,
    required String activityLevel,
    required String gender,
    required String location,
    required String workoutPreference,
    required String dietaryPreference,
    required String fitnessExperience,
    required double targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    required int targetWaterMl,
  }) async {
    final cleanedDisplayName = displayName.trim();
    final now = DateTime.now();

    final batch = _firestore.batch();

    batch.set(
      _userDocument,
      {
        'email': _currentUser.email,
        'displayName': cleanedDisplayName,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goal': goal,
        'activityLevel': activityLevel,
        'gender': gender,
        'location': location,
        'workoutPreference': workoutPreference,
        'dietaryPreference': dietaryPreference,
        'fitnessExperience': fitnessExperience,
        'profileSetupCompleted': true,
        'notificationsEnabled': true,
        'workoutRemindersEnabled': true,
        'darkModeEnabled': false,
        'targetCalories': targetCalories,
        'targetProtein': targetProtein,
        'targetCarbs': targetCarbs,
        'targetFat': targetFat,
        'targetWaterMl': targetWaterMl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (weightKg != null && weightKg > 0) {
      batch.set(
        _weightEntriesCollection.doc('initial_profile_weight'),
        {
          'weightKg': weightKg,
          'heightCm': heightCm,
          'notes': 'Added during profile setup',
          'recordedAt': Timestamp.fromDate(now),
          'createdAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> skipProfileSetup() async {
    await _userDocument.set(
      {
        'profileSetupCompleted': true,
        'targetCalories': 2200.0,
        'targetProtein': 120.0,
        'targetCarbs': 275.0,
        'targetFat': 73.0,
        'targetWaterMl': 3000,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateProfileTargets({
    required double targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    required int targetWaterMl,
  }) async {
    await _userDocument.set(
      {
        'targetCalories': targetCalories,
        'targetProtein': targetProtein,
        'targetCarbs': targetCarbs,
        'targetFat': targetFat,
        'targetWaterMl': targetWaterMl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateProfileDetails({
    required String displayName,
    required int? age,
    required String goal,
    required String activityLevel,
    required String location,
    double? heightCm,
    String? gender,
    String? workoutPreference,
    String? dietaryPreference,
    String? fitnessExperience,
  }) async {
    final cleanedDisplayName = displayName.trim();

    final updateData = <String, dynamic>{
      'displayName': cleanedDisplayName,
      'age': age,
      'goal': goal,
      'activityLevel': activityLevel,
      'location': location,
      'email': _currentUser.email,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (heightCm != null) {
      updateData['heightCm'] = heightCm;
    }

    if (gender != null) {
      updateData['gender'] = gender;
    }

    if (workoutPreference != null) {
      updateData['workoutPreference'] = workoutPreference;
    }

    if (dietaryPreference != null) {
      updateData['dietaryPreference'] = dietaryPreference;
    }

    if (fitnessExperience != null) {
      updateData['fitnessExperience'] = fitnessExperience;
    }

    await _userDocument.set(
      updateData,
      SetOptions(merge: true),
    );
  }

  Future<void> updatePreference({
    required String fieldName,
    required bool value,
  }) async {
    await _userDocument.set(
      {
        fieldName: value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  String _displayNameFromEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Fitza User';
    }

    final namePart = email.split('@').first;

    final words = namePart
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'Fitza User';
    }

    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}