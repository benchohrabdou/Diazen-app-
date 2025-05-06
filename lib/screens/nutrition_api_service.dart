import 'dart:convert';
import 'package:http/http.dart' as http;

class NutritionApiService {
  // USDA FoodData Central API with your provided key
  static const String apiKey = 'hQYP1XW3wilXeIcwcONXnskV7NPKAmHWQvmVOIuc';
  static const String baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  // Search for food items
  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/foods/search?api_key=$apiKey&query=$query&dataType=Foundation,SR%20Legacy,Survey%20(FNDDS)&pageSize=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = data['foods'] as List;

        return foods.map<Map<String, dynamic>>((food) {
          // Find carbohydrates nutrient
          final nutrients = food['foodNutrients'] as List;
          double carbs = 0.0;
          double calories = 0.0;
          double protein = 0.0;
          double fat = 0.0;

          for (var nutrient in nutrients) {
            final nutrientId = nutrient['nutrientId'];
            final value = nutrient['value'] ?? 0.0;

            // Nutrient IDs for USDA database
            if (nutrientId == 1005) {
              // Carbohydrates
              carbs = value.toDouble();
            } else if (nutrientId == 1008) {
              // Energy/Calories
              calories = value.toDouble();
            } else if (nutrientId == 1003) {
              // Protein
              protein = value.toDouble();
            } else if (nutrientId == 1004) {
              // Fat
              fat = value.toDouble();
            }
          }

          return {
            'name': food['description'],
            'carbs': carbs,
            'calories': calories,
            'protein': protein,
            'fat': fat,
            'foodId': food['fdcId'].toString(),
          };
        }).toList();
      } else {
        throw Exception('Failed to load food data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching for food: $e');
    }
  }
}
