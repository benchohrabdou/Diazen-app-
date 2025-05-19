import 'dart:convert';
import 'package:http/http.dart' as http;

class ActivityApiService {
  // API Ninjas - Calories Burned API with your provided key
  static const String apiKey = 'f5d5/ze7MD0gJKqP1OEthg==k4lqw6qODeob6i6o';
  static const String baseUrl = 'https://api.api-ninjas.com/v1/caloriesburned';

  // Fetch calories burned for an activity with retry logic
  Future<List<Map<String, dynamic>>> getCaloriesBurned(
      String activity, double weightKg,
      {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl?activity=$activity'),
          headers: {
            'X-Api-Key': apiKey,
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);

          // Convert the response to a list of activities with calorie information
          return data.map<Map<String, dynamic>>((item) {
            // Calculate calories based on user's weight (API returns calories per lb)
            double weightLbs = weightKg * 2.20462; // Convert kg to lbs
            double caloriesPerHour = item['calories_per_hour'] *
                (weightLbs / 160); // Adjust for weight

            return {
              'name': item['name'],
              'caloriesPerHour': caloriesPerHour,
              'caloriesPer30Min': caloriesPerHour / 2,
              'met': item['met'], // Metabolic Equivalent of Task
              'duration': 30, // Default duration in minutes
            };
          }).toList();
        } else {
          attempts++;
          if (attempts >= maxRetries) {
            throw Exception(
                'Failed to load activity data: ${response.statusCode}');
          }
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw Exception('Error fetching calories data: $e');
        }
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    throw Exception('Failed after $maxRetries attempts');
  }

  // Get a list of common activities
  Future<List<String>> getCommonActivities() async {
    // This is a predefined list since the API doesn't provide a list of activities
    return [
      'running',
      'walking',
      'cycling',
      'swimming',
      'weight lifting',
      'yoga',
      'dancing',
      'basketball',
      'soccer',
      'tennis',
      'hiking',
      'cleaning',
      'gardening',
      'cooking',
      'shopping'
    ];
  }
}
