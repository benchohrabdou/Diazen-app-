import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diazen/screens/add_plate_screen.dart';
import 'package:diazen/screens/meal_detail_screen.dart';

class SavedMealsScreen extends StatefulWidget {
  const SavedMealsScreen({super.key});

  @override
  State<SavedMealsScreen> createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends State<SavedMealsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _meals = [];
  List<Map<String, dynamic>> _filteredMeals = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMeals();
    _searchController.addListener(_filterMeals);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMeals() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMeals = _meals.where((meal) {
        final mealName = meal['name'].toLowerCase();
        return mealName.contains(query);
      }).toList();
    });
  }

  Future<void> _loadMeals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final QuerySnapshot mealsSnapshot = await _firestore
            .collection('meals')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        List<Map<String, dynamic>> meals = [];
        for (var doc in mealsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          meals.add({
            'id': doc.id,
            'name': data['name'] ?? data['nomRepas'] ?? 'Unnamed Meal',
            'totalCarbs': data['totalCarbs'] ?? data['totalGlucides'] ?? 0.0,
            'ingredients': data['ingredients'] ?? [],
          });
        }

        print('Loaded ${meals.length} meals'); // Debug print
        setState(() {
          _meals = meals;
          _filteredMeals = meals;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading meals: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMeal(String mealId) async {
    try {
      await _firestore.collection('meals').doc(mealId).delete();
      await _loadMeals(); // Reload meals after deletion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(String mealId, String mealName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Meal',
          style: TextStyle(
            color: Color(0xFF4A7BF7),
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$mealName"?',
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'SfProDisplay',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMeal(mealId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'SfProDisplay',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Saved Meals',
          style: TextStyle(
            color: Color(0xFF4A7BF7),
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4A7BF7)),
            onPressed: _loadMeals,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search meals by name...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4A7BF7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              style: const TextStyle(
                fontFamily: 'SfProDisplay',
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7BF7)),
                    ),
                  )
                : _filteredMeals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.restaurant,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No saved meals found',
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredMeals.length,
                        itemBuilder: (context, index) {
                          final meal = _filteredMeals[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MealDetailScreen(meal: meal),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _loadMeals();
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => _showDeleteConfirmation(
                                        meal['id'],
                                        meal['name'],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.restaurant,
                                          size: 28,
                                          color: Color(0xFF4A7BF7),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          meal['name'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'SfProDisplay',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A7BF7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(meal['totalCarbs'] as double).toStringAsFixed(1)}g carbs',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'SfProDisplay',
                                            color: Color(0xFF4A7BF7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 