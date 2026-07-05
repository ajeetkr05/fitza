import 'package:cloud_firestore/cloud_firestore.dart';

class WeightEntry {
  final String id;
  final double weightKg;
  final double heightCm;
  final String notes;
  final DateTime recordedAt;
  final DateTime createdAt;

  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.heightCm,
    required this.notes,
    required this.recordedAt,
    required this.createdAt,
  });

  double get bmi {
    final heightInMetres = heightCm / 100;
    return weightKg / (heightInMetres * heightInMetres);
  }

  Map<String, dynamic> toMap() {
    return {
      'weightKg': weightKg,
      'heightCm': heightCm,
      'notes': notes,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WeightEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;

    return WeightEntry(
      id: document.id,
      weightKg: (data['weightKg'] as num).toDouble(),
      heightCm: (data['heightCm'] as num).toDouble(),
      notes: data['notes'] as String? ?? '',
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}