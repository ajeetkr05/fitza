import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item.dart';

class MealEntry {
  final String id;
  final String userId;
  final String date; // format: yyyy-MM-dd
  final String mealType; // Breakfast, Lunch, Snack, Dinner
  final List<FoodItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime timestamp;

  const MealEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date,
      'mealType': mealType,
      'items': items.map((item) => item.toMap()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory MealEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final itemsList = (data['items'] as List<dynamic>?)
            ?.map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        <FoodItem>[];

    return MealEntry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      mealType: data['mealType'] as String? ?? '',
      items: itemsList,
      totalCalories: (data['totalCalories'] as num?)?.toDouble() ?? 0.0,
      totalProtein: (data['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (data['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (data['totalFat'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
