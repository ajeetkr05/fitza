import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stores which muscle groups the user has flagged as injured/limited.
/// Deliberately kept OUT of UserProfile (owned by the profile feature) -
/// this is a self-contained workout-feature setting, stored at
/// users/{uid}/workout_settings/preferences. Equipment settings could live
/// in this same doc later without restructuring anything.
class InjurySettingsService {
  InjurySettingsService._();

  static final InjurySettingsService instance = InjurySettingsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed-in user found.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _preferencesDocument {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('workout_settings')
        .doc('preferences');
  }

  Stream<List<String>> getInjuredMuscleGroupsStream() {
    return _preferencesDocument.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return <String>[];
      final raw = data['injuredMuscleGroups'] as List?;
      return raw?.map((e) => e.toString()).toList() ?? <String>[];
    });
  }

  Future<void> saveInjuredMuscleGroups(List<String> muscleGroups) async {
    await _preferencesDocument.set(
      {
        'injuredMuscleGroups': muscleGroups,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
