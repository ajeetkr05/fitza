import 'package:cloud_firestore/cloud_firestore.dart';

class WaterLog {
  final String id;
  final String userId;
  final String date; // format: yyyy-MM-dd
  final int amountMl;
  final DateTime timestamp;

  const WaterLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.amountMl,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date,
      'amountMl': amountMl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory WaterLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return WaterLog(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      amountMl: (data['amountMl'] as num?)?.toInt() ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
