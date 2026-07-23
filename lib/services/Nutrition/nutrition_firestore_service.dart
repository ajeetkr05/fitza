import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/Nutrition/food_item.dart';
import '../../models/Nutrition/meal_entry.dart';
import '../../models/Nutrition/water_log.dart';

class NutritionFirestoreService {
  NutritionFirestoreService._();

  static final NutritionFirestoreService instance = NutritionFirestoreService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user found.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDocument {
    return _firestore.collection('users').doc(_currentUserId);
  }

  CollectionReference<Map<String, dynamic>> get _mealLogsCollection {
    return _userDocument.collection('meal_logs');
  }

  CollectionReference<Map<String, dynamic>> get _waterLogsCollection {
    return _userDocument.collection('water_logs');
  }

  /// Streams meal logs logged on a specific date (formatted yyyy-MM-dd).
  Stream<List<MealEntry>> getMealsStream(String date) {
    print('NutritionFirestoreService: getMealsStream date=$date uid=$_currentUserId');
    return _mealLogsCollection
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      print('NutritionFirestoreService: mealsStream got ${snapshot.docs.length} docs');
      final list = snapshot.docs
          .map((doc) => MealEntry.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    }).handleError((error) {
      print('NutritionFirestoreService: mealsStream error=$error');
      return <MealEntry>[];
    });
  }

  /// Streams water logs logged on a specific date (formatted yyyy-MM-dd).
  Stream<List<WaterLog>> getWaterStream(String date) {
    print('NutritionFirestoreService: getWaterStream date=$date uid=$_currentUserId');
    return _waterLogsCollection
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      print('NutritionFirestoreService: waterStream got ${snapshot.docs.length} docs');
      final list = snapshot.docs
          .map((doc) => WaterLog.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    }).handleError((error) {
      print('NutritionFirestoreService: waterStream error=$error');
      return <WaterLog>[];
    });
  }

  /// Saves or updates a meal log in Firestore.
  Future<void> saveMeal(MealEntry meal) async {
    final docId = meal.id.isEmpty ? _mealLogsCollection.doc().id : meal.id;
    final mealWithId = MealEntry(
      id: docId,
      userId: _currentUserId,
      date: meal.date,
      mealType: meal.mealType,
      items: meal.items,
      totalCalories: meal.totalCalories,
      totalProtein: meal.totalProtein,
      totalCarbs: meal.totalCarbs,
      totalFat: meal.totalFat,
      timestamp: meal.timestamp,
    );
    await _mealLogsCollection.doc(docId).set(
          mealWithId.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// Deletes a logged meal.
  Future<void> deleteMeal(String mealId) async {
    await _mealLogsCollection.doc(mealId).delete();
  }

  /// Logs or updates water intake.
  Future<void> saveWater(WaterLog water) async {
    final docId = water.id.isEmpty ? _waterLogsCollection.doc().id : water.id;
    final waterWithId = WaterLog(
      id: docId,
      userId: _currentUserId,
      date: water.date,
      amountMl: water.amountMl,
      timestamp: water.timestamp,
    );
    await _waterLogsCollection.doc(docId).set(
          waterWithId.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// Deletes a logged water entry.
  Future<void> deleteWater(String waterId) async {
    await _waterLogsCollection.doc(waterId).delete();
  }

  /// Fetches meal history logs for a range of dates.
  Future<List<MealEntry>> getHistoryMeals(int daysBack) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final cutoffDate = todayStart.subtract(Duration(days: daysBack - 1));
    final snapshot = await _mealLogsCollection
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
        .get();

    final list = snapshot.docs
        .map((doc) => MealEntry.fromFirestore(doc))
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Fetches unique FoodItems logged across the user's last [mealLimit] meals.
  Future<List<FoodItem>> getRecentlyEatenFoods({int mealLimit = 8}) async {
    try {
      final snapshot = await _mealLogsCollection
          .orderBy('timestamp', descending: true)
          .limit(mealLimit)
          .get();

      final List<FoodItem> recentItems = [];
      final Set<String> seenNames = {};

      for (var doc in snapshot.docs) {
        final meal = MealEntry.fromFirestore(doc);
        for (var item in meal.items) {
          final key = item.name.trim().toLowerCase();
          if (!seenNames.contains(key)) {
            seenNames.add(key);
            recentItems.add(item);
          }
        }
      }
      return recentItems;
    } catch (e) {
      return [];
    }
  }

  /// Fetches water history logs for a range of dates.
  Future<List<WaterLog>> getHistoryWater(int daysBack) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final cutoffDate = todayStart.subtract(Duration(days: daysBack - 1));
    final snapshot = await _waterLogsCollection
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
        .get();

    final list = snapshot.docs
        .map((doc) => WaterLog.fromFirestore(doc))
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  List<FoodItem>? _cachedCompositionFoods;

  /// Query the Cloud Firestore collection `food_composition_tables` for local food composition items.
  Future<List<FoodItem>> searchLocalFoodComposition(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      if (_cachedCompositionFoods == null) {
        final snapshot = await _firestore
            .collection('food_composition_tables')
            .limit(100)
            .get();

        _cachedCompositionFoods = snapshot.docs.map((doc) {
          final data = doc.data();
          return FoodItem(
            name: data['foodName'] as String? ?? data['name'] as String? ?? '',
            quantity: data['quantity'] as String? ?? '100g',
            calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
            protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
            carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
            fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
          );
        }).where((item) => item.name.isNotEmpty).toList();
      }

      final queryText = query.trim().toLowerCase();
      final matches = _cachedCompositionFoods!.where((item) {
        final nameLower = item.name.toLowerCase();
        return nameLower.contains(queryText);
      }).toList();

      if (matches.isNotEmpty) {
        return matches;
      }

      final snapshot = await _firestore
          .collection('food_composition_tables')
          .where('searchName', isGreaterThanOrEqualTo: queryText)
          .where('searchName', isLessThanOrEqualTo: '$queryText\uf8ff')
          .limit(15)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FoodItem(
          name: data['foodName'] as String? ?? data['name'] as String? ?? '',
          quantity: data['quantity'] as String? ?? '100g',
          calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
          protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
          carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
          fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
