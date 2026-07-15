import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/Nutrition/food_item.dart';

class GeminiService {
  GeminiService._();

  static final GeminiService instance = GeminiService._();

  List<String> get _apiKeys => [
        dotenv.env['GEMINI_API_KEY_1'] ?? '',
        dotenv.env['GEMINI_API_KEY_2'] ?? '',
        dotenv.env['GEMINI_API_KEY_3'] ?? '',
        dotenv.env['GEMINI_API_KEY_4'] ?? '',
        dotenv.env['GEMINI_API_KEY_5'] ?? '',
      ].where((key) => key.trim().isNotEmpty).toList();

  int _currentKeyIndex = 0;

  final Map<String, String> _workoutExplanationCache = {};

  Future<String> _postRequest(Map<String, dynamic> body) async {
    final keys = _apiKeys;
    if (keys.isEmpty) {
      throw Exception('No Gemini API keys configured in the .env file.');
    }
    int attempts = 0;
    List<String> errors = [];
    while (attempts < keys.length) {
      final apiKey = keys[_currentKeyIndex % keys.length];
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );
        
        final request = await client.postUrl(url);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
        
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();
        
        if (response.statusCode == 200) {
          return responseBody;
        } else {
          final err = 'Key $_currentKeyIndex Status ${response.statusCode}: $responseBody';
          print(err);
          errors.add(err);
          _rotateKey();
          attempts++;
        }
      } catch (e) {
        final err = 'Key $_currentKeyIndex Exception: $e';
        print(err);
        errors.add(err);
        _rotateKey();
        attempts++;
      }
    }
    throw Exception('All Gemini keys failed:\n' + errors.join('\n'));
  }

  void _rotateKey() {
    final keys = _apiKeys;
    if (keys.isNotEmpty) {
      _currentKeyIndex = (_currentKeyIndex + 1) % keys.length;
    }
  }

  /// Search for food items matching a query and return nutritional estimations.
  Future<List<FoodItem>> searchFood(String query) async {
    final prompt = '''
You are a professional nutrition database and dietitian assistant.
Analyze the user's food search query: "$query".
If the query matches or is similar to a real food item, provide its estimated nutritional profile per typical serving size.
If the query specifies a quantity (e.g., "100g chicken", "2 chapatis", "1 bowl paneer"), calculate the values based on that amount.
Return a JSON array of up to 3 candidate food items, ordered by relevance.

Each object in the JSON array MUST have the following structure:
{
  "name": "Specific Food Name (e.g. Chicken Breast, Grilled)",
  "quantity": "Serving size/Quantity (e.g. 100g, 1 piece, 1 bowl)",
  "calories": 165.0,
  "protein": 31.0,
  "carbs": 0.0,
  "fat": 3.6
}
''';

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json"
      }
    };

    try {
      final responseText = await _postRequest(body);
      final jsonResponse = jsonDecode(responseText);
      final contentText = jsonResponse['candidates'][0]['content']['parts'][0]['text'] as String;
      final List<dynamic> list = jsonDecode(contentText);
      return list.map((item) => FoodItem.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      // Fallback in case of parsing errors or total failure
      return [
        FoodItem(
          name: query,
          quantity: "1 serving",
          calories: 150,
          protein: 5,
          carbs: 20,
          fat: 5,
        )
      ];
    }
  }

  /// Analyze food item(s) from an uploaded image. Returns a list with a special
  /// 'NOT_FOOD' item if image doesn't contain food.
  Future<List<FoodItem>> analyzeFoodImage(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    final prompt = '''
Look at this image carefully.

If this image contains food, a meal, a drink, or any edible item, identify every distinct food item visible and estimate its nutritional information.

Return a JSON array where each element has:
{"name": "Food Name", "quantity": "estimated portion", "calories": 0.0, "protein": 0.0, "carbs": 0.0, "fat": 0.0}

Only if the image clearly does NOT contain any food, drink, or edible item at all (for example: a shoe, a car, a person without food, a landscape), return exactly:
[{"name": "NOT_FOOD", "quantity": "0", "calories": 0, "protein": 0, "carbs": 0, "fat": 0}]

When in doubt, treat the image as food and attempt identification.
''';

    final body = {
      "contents": [
        {
          "parts": [
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Image
              }
            },
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json"
      }
    };

    try {
      final responseText = await _postRequest(body);
      final jsonResponse = jsonDecode(responseText);
      final contentText = jsonResponse['candidates'][0]['content']['parts'][0]['text'] as String;

      // Handle case where response might be a JSON object with a wrapping key
      final decoded = jsonDecode(contentText);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        // Some models wrap in an object like {"foods": [...]} or {"items": [...]}
        final firstListValue = decoded.values.firstWhere(
          (v) => v is List,
          orElse: () => [decoded],
        );
        list = firstListValue is List ? firstListValue : [decoded];
      } else {
        return [];
      }

      return list.map((item) => FoodItem.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      // Print error for debugging
      print('analyzeFoodImage error: $e');
      return [];
    }
  }

  /// Rewrites rule-based "why this workout" facts into a warm, natural
/// explanation. The FACTS themselves are decided entirely by
/// RecommendationService (rule-based, safety-relevant) - this only
/// rephrases them. Falls back to the original bullets, joined as plain
/// sentences, if the API fails for any reason - matching the fallback
/// pattern used elsewhere in this class.
Future<String> explainWorkout({
  required String workoutTitle,
  required List<String> ruleBasedBullets,
}) async {
  final cacheKey = '$workoutTitle|${ruleBasedBullets.join('|')}';
  final cached = _workoutExplanationCache[cacheKey];
  if (cached != null) return cached;

  final prompt = '''
You are a friendly, encouraging fitness coach inside the Fitza app.
Rewrite the following facts about today's recommended workout as a warm,
natural 2-3 sentence explanation for the user.

STRICT RULES:
- Do NOT add any new facts, numbers, claims, or medical advice beyond what is listed below.
- Do NOT invent statistics or health claims.
- Keep it encouraging but not over-the-top.
- Return ONLY the explanation text - no preamble, no markdown, no quotes.

Workout: $workoutTitle
Facts:
${ruleBasedBullets.map((b) => '- $b').join('\n')}
''';

  final body = {
    "contents": [
      {
        "parts": [
          {"text": prompt}
        ]
      }
    ],
  };

  try {
    final responseText = await _postRequest(body);
    final jsonResponse = jsonDecode(responseText);
    final contentText =
        jsonResponse['candidates'][0]['content']['parts'][0]['text'] as String;
    final explanation = contentText.trim();
    _workoutExplanationCache[cacheKey] = explanation;
    return explanation;
  } catch (e) {
    // Fallback: just present the rule-based facts as plain sentences -
    // still informative, just less conversational.
    return ruleBasedBullets.join(' ');
  }
}

  /// Generates 4 personalized food recommendations.
  Future<Map<String, dynamic>> getFoodRecommendations({
    required double remainingCalories,
    required double remainingProtein,
    required double remainingCarbs,
    required double remainingFat,
    required int mealsRemaining,
    required String goal,
    required String dietaryPreference,
  }) async {
    final prompt = '''
You are an expert AI Nutrition Coach. Suggest 4 distinct food/meal recommendations tailored specifically to the user's remaining nutritional targets and preferences:
- Remaining Calories: $remainingCalories kcal
- Remaining Protein: ${remainingProtein}g
- Remaining Carbohydrates: ${remainingCarbs}g
- Remaining Fats: ${remainingFat}g
- Meals remaining today: $mealsRemaining
- Goal: $goal
- Dietary Preference: $dietaryPreference

DIETARY CONSTRAINT: The user's food preference is '$dietaryPreference'. You MUST strictly respect this preference.
- If 'Vegetarian', the recommendation and ALL its ingredients/items MUST be completely vegetarian (no chicken, meat, beef, pork, fish, seafood, or eggs).
- If 'Vegan', the recommendation and ALL its ingredients/items MUST be completely plant-based (no meat, fish, dairy, milk, butter, cheese, paneer, eggs, or any animal products).
- If 'Non-vegetarian' or 'High protein', you may suggest non-vegetarian or vegetarian options.

Suggest exactly one meal/snack recommendation for each of the following 4 categories:
1. "highProtein" - Focuses on helping them hit their protein targets.
2. "balancedMeal" - Balanced ratio of protein, carbs, and fats.
3. "lowCalorie" - Nutrient-dense but low in calories to stay under their limit.
4. "healthySnack" - Light snack to bridge the gap.

For each category, provide a structured JSON response with these keys:
- "mealName": name of the suggested food/meal
- "estimatedCalories": total estimated calories (double)
- "shortDescription": a brief 1-sentence description
- "whyThisRecommendation": a personalized explanation using the user's specific remaining macros. Include exactly why it fits (e.g. "Since you have only $remainingCalories calories left and still need ${remainingProtein}g of protein, this high-protein option gives you 35g of protein with only 300 calories.")
- "items": a JSON array of food items that compose the meal. Each item has: "name", "quantity", "calories", "protein", "carbs", "fat".

Return the full output as a single JSON object containing these 4 category keys: "highProtein", "balancedMeal", "lowCalorie", and "healthySnack".
''';

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json"
      }
    };

    try {
      final responseText = await _postRequest(body);
      final jsonResponse = jsonDecode(responseText);
      final contentText = jsonResponse['candidates'][0]['content']['parts'][0]['text'] as String;
      return jsonDecode(contentText) as Map<String, dynamic>;
    } catch (e) {
      // Fallback empty recommendations in case of failure, respecting dietary preferences
      final lowerPref = dietaryPreference.toLowerCase();
      final bool isVegan = lowerPref == 'vegan';
      final bool isVeg = isVegan || lowerPref == 'vegetarian';

      if (isVegan) {
        return {
          "highProtein": {
            "mealName": "Tofu Quinoa Salad",
            "estimatedCalories": 360.0,
            "shortDescription": "Pan-seared organic tofu on a bed of fresh mixed greens and cooked quinoa.",
            "whyThisRecommendation": "Provides a clean, plant-based high-protein option with minimal calories.",
            "items": [
              {"name": "Organic Firm Tofu", "quantity": "150g", "calories": 140.0, "protein": 15.0, "carbs": 3.0, "fat": 8.0},
              {"name": "Cooked Quinoa", "quantity": "0.5 cup", "calories": 110.0, "protein": 4.0, "carbs": 20.0, "fat": 1.8},
              {"name": "Mixed Greens & Cucumber", "quantity": "1 bowl", "calories": 50.0, "protein": 2.0, "carbs": 8.0, "fat": 0.5},
              {"name": "Olive Oil Dressing", "quantity": "1 tsp", "calories": 60.0, "protein": 0.0, "carbs": 0.0, "fat": 7.0}
            ]
          },
          "balancedMeal": {
            "mealName": "Tempeh Rice Bowl",
            "estimatedCalories": 430.0,
            "shortDescription": "Sautéed tempeh served with brown rice and mixed stir-fried vegetables.",
            "whyThisRecommendation": "A completely vegan, balanced mix of protein, fats, and complex carbohydrates.",
            "items": [
              {"name": "Brown Rice", "quantity": "1 cup", "calories": 215.0, "protein": 5.0, "carbs": 45.0, "fat": 1.6},
              {"name": "Sautéed Tempeh", "quantity": "100g", "calories": 165.0, "protein": 18.0, "carbs": 9.0, "fat": 9.0},
              {"name": "Stir-fried Veggies", "quantity": "1 cup", "calories": 50.0, "protein": 2.0, "carbs": 8.0, "fat": 0.5}
            ]
          },
          "lowCalorie": {
            "mealName": "Mixed Vegetable Soup",
            "estimatedCalories": 150.0,
            "shortDescription": "Warm, comforting clear soup packed with fiber and vitamins.",
            "whyThisRecommendation": "Extremely low-calorie yet voluminous and satisfying.",
            "items": [
              {"name": "Vegetable Clear Broth", "quantity": "2 cups", "calories": 40.0, "protein": 1.0, "carbs": 5.0, "fat": 0.0},
              {"name": "Chopped Vegetables (Carrots, Beans, Broccoli)", "quantity": "1.5 cups", "calories": 110.0, "protein": 4.0, "carbs": 20.0, "fat": 0.5}
            ]
          },
          "healthySnack": {
            "mealName": "Mixed Fruit Bowl with Chia Seeds",
            "estimatedCalories": 160.0,
            "shortDescription": "Fresh seasonal fruits sprinkled with hydrated organic chia seeds.",
            "whyThisRecommendation": "A quick, nutrient-dense vegan snack providing healthy omega-3 fats.",
            "items": [
              {"name": "Mixed Seasonal Fruits", "quantity": "1.5 cups", "calories": 100.0, "protein": 1.5, "carbs": 25.0, "fat": 0.5},
              {"name": "Chia Seeds", "quantity": "1 tbsp", "calories": 60.0, "protein": 2.0, "carbs": 5.0, "fat": 4.0}
            ]
          }
        };
      } else if (isVeg) {
        return {
          "highProtein": {
            "mealName": "Paneer Tikka Salad",
            "estimatedCalories": 360.0,
            "shortDescription": "Grilled marinated paneer cubes on a bed of fresh garden salad.",
            "whyThisRecommendation": "Provides a delicious vegetarian high-protein option with moderate calories.",
            "items": [
              {"name": "Grilled Paneer", "quantity": "120g", "calories": 250.0, "protein": 18.0, "carbs": 4.0, "fat": 18.0},
              {"name": "Mixed Greens & Cucumber", "quantity": "1 bowl", "calories": 50.0, "protein": 2.0, "carbs": 8.0, "fat": 0.5},
              {"name": "Yogurt Dressing", "quantity": "2 tbsp", "calories": 60.0, "protein": 2.0, "carbs": 4.0, "fat": 4.0}
            ]
          },
          "balancedMeal": {
            "mealName": "Paneer Tofu Quinoa Bowl",
            "estimatedCalories": 420.0,
            "shortDescription": "Sautéed paneer/tofu with quinoa and colorful roasted vegetables.",
            "whyThisRecommendation": "A balanced mix of protein, fats, and complex carbohydrates.",
            "items": [
              {"name": "Cooked Quinoa", "quantity": "1 cup", "calories": 220.0, "protein": 8.0, "carbs": 39.0, "fat": 3.6},
              {"name": "Paneer / Tofu", "quantity": "100g", "calories": 150.0, "protein": 14.0, "carbs": 3.0, "fat": 10.0},
              {"name": "Steamed Veggies", "quantity": "1 cup", "calories": 50.0, "protein": 2.0, "carbs": 8.0, "fat": 0.5}
            ]
          },
          "lowCalorie": {
            "mealName": "Mixed Vegetable Soup",
            "estimatedCalories": 150.0,
            "shortDescription": "Warm, comforting clear soup packed with fiber and vitamins.",
            "whyThisRecommendation": "Extremely low-calorie yet voluminous and satisfying.",
            "items": [
              {"name": "Vegetable Clear Broth", "quantity": "2 cups", "calories": 40.0, "protein": 1.0, "carbs": 5.0, "fat": 0.0},
              {"name": "Chopped Vegetables (Carrots, Beans, Broccoli)", "quantity": "1.5 cups", "calories": 110.0, "protein": 4.0, "carbs": 20.0, "fat": 0.5}
            ]
          },
          "healthySnack": {
            "mealName": "Greek Yogurt with Almonds",
            "estimatedCalories": 180.0,
            "shortDescription": "Creamy low-fat Greek yogurt topped with crunchy sliced almonds.",
            "whyThisRecommendation": "A quick snack providing probiotic support and healthy fats.",
            "items": [
              {"name": "Plain Greek Yogurt", "quantity": "150g", "calories": 120.0, "protein": 15.0, "carbs": 6.0, "fat": 2.0},
              {"name": "Almonds", "quantity": "10 pieces", "calories": 60.0, "protein": 2.0, "carbs": 2.0, "fat": 5.0}
            ]
          }
        };
      } else {
        return {
          "highProtein": {
            "mealName": "Grilled Chicken Salad",
            "estimatedCalories": 350.0,
            "shortDescription": "Lean grilled chicken breast on a bed of fresh mixed greens.",
            "whyThisRecommendation": "Provides high protein with minimal calories to help hit your protein goals.",
            "items": [
              {"name": "Grilled Chicken Breast", "quantity": "150g", "calories": 240.0, "protein": 35.0, "carbs": 0.0, "fat": 4.0},
              {"name": "Mixed Greens & Cucumber", "quantity": "1 bowl", "calories": 50.0, "protein": 2.0, "carbs": 8.0, "fat": 0.5},
              {"name": "Olive Oil Dressing", "quantity": "1 tsp", "calories": 60.0, "protein": 0.0, "carbs": 0.0, "fat": 7.0}
            ]
          },
          "balancedMeal": {
            "mealName": "Paneer Tofu Quinoa Bowl",
            "estimatedCalories": 420.0,
            "shortDescription": "Sautéed paneer/tofu with quinoa and colorful roasted vegetables.",
            "whyThisRecommendation": "A balanced mix of protein, fats, and complex carbohydrates.",
            "items": [
              {"name": "Cooked Quinoa", "quantity": "1 cup", "calories": 220.0, "protein": 8.0, "carbs": 39.0, "fat": 3.6},
              {"name": "Paneer / Tofu", "quantity": "100g", "calories": 150.0, "protein": 14.0, "carbs": 3.0, "fat": 10.0},
              {"name": "Steamed Veggies", "quantity": "1 cup", "calories": 50.0, "protein": 2.0, "carbs": 8.0, "fat": 0.5}
            ]
          },
          "lowCalorie": {
            "mealName": "Mixed Vegetable Soup",
            "estimatedCalories": 150.0,
            "shortDescription": "Warm, comforting clear soup packed with fiber and vitamins.",
            "whyThisRecommendation": "Extremely low-calorie yet voluminous and satisfying.",
            "items": [
              {"name": "Vegetable Clear Broth", "quantity": "2 cups", "calories": 40.0, "protein": 1.0, "carbs": 5.0, "fat": 0.0},
              {"name": "Chopped Vegetables (Carrots, Beans, Broccoli)", "quantity": "1.5 cups", "calories": 110.0, "protein": 4.0, "carbs": 20.0, "fat": 0.5}
            ]
          },
          "healthySnack": {
            "mealName": "Greek Yogurt with Almonds",
            "estimatedCalories": 180.0,
            "shortDescription": "Creamy low-fat Greek yogurt topped with crunchy sliced almonds.",
            "whyThisRecommendation": "A quick snack providing probiotic support and healthy fats.",
            "items": [
              {"name": "Plain Greek Yogurt", "quantity": "150g", "calories": 120.0, "protein": 15.0, "carbs": 6.0, "fat": 2.0},
              {"name": "Almonds", "quantity": "10 pieces", "calories": 60.0, "protein": 2.0, "carbs": 2.0, "fat": 5.0}
            ]
          }
        };
      }
    }
  }
}
