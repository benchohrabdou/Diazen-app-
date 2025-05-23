import 'package:flutter/material.dart';
import 'package:diazen/screens/add_plate_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealDetailScreen extends StatelessWidget {
  final Map<String, dynamic> meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          meal['name'],
          style: const TextStyle(
            color: Color(0xFF4A7BF7),
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A7BF7)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4A7BF7)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPlateScreen(
                    editMode: true,
                    mealId: meal['id'],
                    initialName: meal['name'],
                    initialIngredients:
                        List<Map<String, dynamic>>.from(meal['ingredients']),
                  ),
                ),
              ).then((_) => Navigator.pop(
                  context, true)); // Indicate a potential change on back
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Carbs: ${(meal['totalCarbs'] as double).toStringAsFixed(1)}g',
              style: const TextStyle(
                fontFamily: 'SfProDisplay',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ingredients:',
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (meal['ingredients'] as List).length,
              itemBuilder: (context, index) {
                final ingredient = meal['ingredients'][index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 20, color: Color(0xFF4A7BF7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ingredient['name']}',
                              style: const TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Quantity: ${ingredient['quantity'] ?? 'N/A'}g',
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(ingredient['totalCarbs'] as num).toStringAsFixed(1)}g carbs',
                        style: const TextStyle(
                          fontFamily: 'SfProDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A7BF7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
