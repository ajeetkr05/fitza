import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/progress/weight_entry.dart';

class WeightFirestoreService {
  WeightFirestoreService._();

  static final WeightFirestoreService instance =
      WeightFirestoreService._();

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No signed-in user found.');
    }

    return user.uid;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    return _firestore.collection('users').doc(_currentUserId);
  }

  CollectionReference<Map<String, dynamic>> get _weightEntriesCollection {
    return _userDocument.collection('weight_entries');
  }

  Future<void> saveWeightEntry({
    required double weightKg,
    required double heightCm,
    required String notes,
    required DateTime recordedAt,
  }) async {
    final entryDocument = _weightEntriesCollection.doc();

    final weightEntry = WeightEntry(
      id: entryDocument.id,
      weightKg: weightKg,
      heightCm: heightCm,
      notes: notes,
      recordedAt: recordedAt,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    batch.set(
      _userDocument,
      {
        'heightCm': heightCm,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(entryDocument, weightEntry.toMap());

    await batch.commit();
  }

  Stream<List<WeightEntry>> getWeightEntriesStream() {
    return _weightEntriesCollection
        .orderBy('recordedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WeightEntry.fromFirestore)
              .toList(),
        );
  }

  Future<double?> getSavedHeight() async {
    final userSnapshot = await _userDocument.get();
    final data = userSnapshot.data();

    if (data == null || data['heightCm'] == null) {
      return null;
    }

    return (data['heightCm'] as num).toDouble();
  }
}