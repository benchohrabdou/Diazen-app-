import 'package:flutter/material.dart';
import 'package:diazen/classes/firestore_ops.dart';
import 'package:diazen/screens/nutrition_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class AddPlateScreen extends StatefulWidget {
  const AddPlateScreen({super.key});

  @override
  State<AddPlateScreen> createState() => _AddPlateScreenState();
}

class _AddPlateScreenState extends State<AddPlateScreen> {
  final TextEditingController _platenamecontroller = TextEditingController();
  final TextEditingController _ingredientcontroler = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final NutritionApiService _nutritionApiService = NutritionApiService();

  List<Map<String, dynamic>> _ingredients = [];
  double _quantity = 100; // Default quantity in grams
  bool _isSearching = false;
  bool _isSaving = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _searchResults = [];

  double get _totalCarbs {
    return _ingredients.fold(
        0, (sum, ingredient) => sum + (ingredient['totalCarbs'] ?? 0));
  }

  void _searchIngredient(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final results = await _nutritionApiService.searchFood(query);

      if (results.isNotEmpty) {
        setState(() {
          _searchResults = results;
        });
      } else {
        setState(() {
          _searchResults = [];
          _errorMessage = 'No results found for "$query"';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching for food: $e';
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectIngredient(Map<String, dynamic> food) {
    setState(() {
      _ingredients.add({
        'name': food['name'],
        'carbs': food['carbs'],
        'quantity': _quantity,
        'foodId': food['foodId'],
        'calories': food['calories'],
        'totalCarbs': (food['carbs'] * _quantity) /
            100, // Calculate total carbs based on quantity
      });

      _ingredientcontroler.clear();
      _searchResults = [];
      _quantity = 100; // Reset quantity
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${food['name']} (${_quantity}g)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _savePlate() async {
    final plateName = _platenamecontroller.text.trim();

    if (plateName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plate name')),
      );
      return;
    }

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final uuid = Uuid();
      final mealId = uuid.v4();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Add userId to meal data
      List<Map<String, dynamic>> ingredientsData = _ingredients
          .map((ingredient) => {
                'name': ingredient['name'],
                'glucidesPer100g': ingredient['carbs'],
                'quantity': ingredient['quantity'],
                'totalCarbs': ingredient['totalCarbs'],
              })
          .toList();

      // Save to Firestore with user association
      await _firestoreService.addMeal(
          mealId, plateName, ingredientsData, userId);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal "$plateName" saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      setState(() {
        _platenamecontroller.clear();
        _ingredients = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving meal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 25, left: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Text(
                  'Create Your Plate',
                  style: TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A7BF7),
                    fontSize: 25,
                  ),
                )
              ]),
              const SizedBox(height: 20),
              const Text('Plate name',
                  style: TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontSize: 18,
                    color: Colors.black,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: _platenamecontroller,
                decoration: InputDecoration(
                  hintText: 'Enter plate name',
                  hintStyle: const TextStyle(
                    fontFamily: 'SfProDisplay',
                  ),
                  filled: true,
                  fillColor: Colors.grey[300],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text('Search and add ingredients:',
                  style: TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontSize: 18,
                    color: Colors.black,
                  )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7BF7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Ingredient TextField
                        Expanded(
                          child: TextField(
                            controller: _ingredientcontroler,
                            decoration: InputDecoration(
                              hintText: 'Search ingredient',
                              hintStyle: const TextStyle(
                                fontFamily: 'SfProDisplay',
                              ),
                              filled: true,
                              fillColor: Colors.grey[300],
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF4A7BF7),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () => _searchIngredient(
                                          _ingredientcontroler.text),
                                    ),
                            ),
                            onChanged: (value) {
                              if (value.length > 2) {
                                _searchIngredient(value);
                              } else if (value.isEmpty) {
                                setState(() {
                                  _searchResults = [];
                                });
                              }
                            },
                            onSubmitted: (value) => _searchIngredient(value),
                          ),
                        ),
                      ],
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final food = _searchResults[index];
                            return ListTile(
                              title: Text(food['name']),
                              subtitle: Text(
                                  'Carbs: ${food['carbs'].toStringAsFixed(1)}g per 100g'),
                              onTap: () => _selectIngredient(food),
                            );
                          },
                        ),
                      ),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Quantity (g): ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (_quantity > 10) {
                                            _quantity -= 10;
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Text(
                                      _quantity.toStringAsFixed(0),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _quantity += 10;
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Added Ingredients
              if (_ingredients.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Added Ingredients:',
                      style: TextStyle(
                        fontFamily: 'SfProDisplay',
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ...List.generate(_ingredients.length, (index) {
                            final ingredient = _ingredients[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${ingredient['name']} (${ingredient['quantity']}g)',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    '${ingredient['totalCarbs'].toStringAsFixed(1)}g carbs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _removeIngredient(index),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Carbohydrates:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${_totalCarbs.toStringAsFixed(1)}g',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF4A7BF7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 25),

              // Plate Preview
              if (_platenamecontroller.text.isNotEmpty ||
                  _ingredients.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plate Preview:',
                      style: TextStyle(
                        fontFamily: 'SfProDisplay',
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A7BF7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _platenamecontroller.text.isEmpty
                                ? 'Unnamed Plate'
                                : _platenamecontroller.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_ingredients.isNotEmpty) ...[
                            const Text(
                              'Ingredients:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ..._ingredients.map((ingredient) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${ingredient['name']} (${ingredient['quantity']}g)',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${ingredient['totalCarbs'].toStringAsFixed(1)}g carbs',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const Divider(color: Colors.white54),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Carbohydrates:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_totalCarbs.toStringAsFixed(1)}g',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePlate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7BF7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Plate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SfProDisplay',
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
