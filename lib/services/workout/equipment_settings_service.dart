import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stores which equipment tags the user has available. Shares the same
/// Firestore document as InjurySettingsService
/// (users/{uid}/workout_settings/preferences) but writes to a different
/// field ('availableEquipment' vs 'injuredMuscleGroups'), using
/// SetOptions(merge: true) so the two services never clobber each other's
/// data even though they share a doc. Kept as a separate service class
/// (rather than merging into InjurySettingsService) to avoid renaming code
/// you already have wired up.
///
/// EQUIPMENT VOCABULARY: tags here must exactly match the strings used in
/// Exercise.equipmentTags (see exercise_database.dart) - 'barbell',
/// 'dumbbells', 'bench', 'pull_up_bar', 'squat_rack' are what the current
/// seed library actually uses. If the exercise library grows, add new
/// equipment tags here to match, in both places.
class EquipmentSettingsService {
  EquipmentSettingsService._();

  static final EquipmentSettingsService instance = EquipmentSettingsService._();

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

  /// Returns null if the user has never saved equipment preferences (so
  /// callers should treat equipment as "not tracked, don't restrict") -
  /// vs a real list (possibly empty, meaning "explicitly bodyweight only")
  /// once they have. This distinction matters: kSeedExercises has NO
  /// bodyweight-only options for Back/Shoulders/Arms, so treating an
  /// unconfigured user as "zero equipment" would silently return an empty
  /// exercise list on those muscle-group days.
  Stream<List<String>?> getAvailableEquipmentStream() {
    return _preferencesDocument.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null || !data.containsKey('availableEquipment')) {
        return null; // never configured
      }
      final raw = data['availableEquipment'] as List?;
      return raw?.map((e) => e.toString()).toList() ?? <String>[];
    });
  }

  Future<void> saveAvailableEquipment(List<String> equipmentTags) async {
    await _preferencesDocument.set(
      {
        'availableEquipment': equipmentTags,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
