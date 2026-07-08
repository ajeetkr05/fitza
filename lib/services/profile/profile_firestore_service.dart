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

  Future<void> updateProfileDetails({
    required String displayName,
    required int? age,
    required String goal,
    required String activityLevel,
    required String location,
  }) async {
    final cleanedDisplayName = displayName.trim();

    await _userDocument.set(
      {
        'displayName': cleanedDisplayName,
        'age': age,
        'goal': goal,
        'activityLevel': activityLevel,
        'location': location,
        'email': _currentUser.email,
        'updatedAt': FieldValue.serverTimestamp(),
      },
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