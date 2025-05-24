import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diazen/classes/injection.dart';
import 'package:diazen/screens/activity_screen.dart';
import 'package:diazen/screens/add_plate_screen.dart';
import 'package:diazen/screens/dose_result_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CalculateDoseScreen extends StatefulWidget {
  const CalculateDoseScreen({super.key});

  @override
  State<CalculateDoseScreen> createState() => _CalculateDoseScreenState();
}

class _CalculateDoseScreenState extends State<CalculateDoseScreen> {
  final TextEditingController glucoseController = TextEditingController();
  final TextEditingController mealController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool unplannedActivity = false;
  bool plannedActivity = false;
  bool _isSaving = false;
  bool _isLoadingMeals = false;
  bool _isLoadingActivity = false;

  // Activity intensity selections
  String unplannedActivityIntensity = 'none';
  String plannedActivityIntensity = 'none';

  // User parameters - in a real app, these would be fetched from user settings
  final double targetGlucose = 100; // Target blood glucose level in mg/dL
  final double isf =
      50; // Insulin Sensitivity Factor: 1 unit lowers glucose by 50 mg/dL
  final double icr = 10; // Insulin-to-Carb Ratio: 1 unit per 10g of carbs

  // Meals list for dropdown
  List<Map<String, dynamic>> _mealsList = [];
  Map<String, dynamic>? _selectedMeal;

  // State variable for meal quantity
  double _mealQuantity = 1.0; // Default quantity

  // Activity reduction factors
  double unplannedActivityReductionFactor = 0.0;
  double plannedActivityReductionFactor = 0.0;

  // Add variables to store selected activity calories and duration
  double selectedUnplannedActivityCalories = 0.0;
  int selectedUnplannedActivityDuration = 30;
  double selectedPlannedActivityCalories = 0.0;
  int selectedPlannedActivityDuration = 30;
  double lastUnplannedReductionUnits = 0.0;
  double lastUnplannedReductionPercent = 0.0;
  double lastPlannedReductionUnits = 0.0;
  double lastPlannedReductionPercent = 0.0;

  // Add variables to store calculated activity calories for display on result screen
  double _calculatedUnplannedActivityCalories = 0.0;
  double _calculatedPlannedActivityCalories = 0.0;

  @override
  void initState() {
    super.initState();
    // Reset all values when screen initializes
    _resetScreen();
    _loadUserMeals();
  }

  // Add this method to reset the screen state
  void _resetScreen() {
    setState(() {
      unplannedActivity = false;
      plannedActivity = false;
      unplannedActivityIntensity = 'none';
      plannedActivityIntensity = 'none';
      _selectedMeal = null;
      glucoseController.clear();
      mealController.clear();
      _mealQuantity = 1.0; // Reset meal quantity
      _isSaving = false;
      _isLoadingMeals = false;
      unplannedActivityReductionFactor = 0.0;
      plannedActivityReductionFactor = 0.0;
      selectedUnplannedActivityCalories = 0.0;
      selectedUnplannedActivityDuration = 30;
      selectedPlannedActivityCalories = 0.0;
      selectedPlannedActivityDuration = 30;
      lastUnplannedReductionUnits = 0.0;
      lastUnplannedReductionPercent = 0.0;
      lastPlannedReductionUnits = 0.0;
      lastPlannedReductionPercent = 0.0;
      _calculatedUnplannedActivityCalories = 0.0;
      _calculatedPlannedActivityCalories = 0.0;
    });
  }

  // Override didChangeDependencies to reset when screen becomes active
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset the screen every time it becomes active
    _resetScreen();
    _loadUserMeals();
  }

  // Get activity reduction factor based on intensity
  double getActivityReductionFactor(String intensity) {
    switch (intensity) {
      case 'light':
        return 0.10; // 10%
      case 'moderate':
        return 0.20; // 20%
      case 'vigorous':
        return 0.30; // 30%
      case 'intense':
        return 0.40; // 40%
      default:
        return 0.0; // No activity
    }
  }

  // Load user meals from Firestore
  Future<void> _loadUserMeals() async {
    setState(() {
      _isLoadingMeals = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Query meals collection for this user
        final QuerySnapshot mealsSnapshot =
            await _firestore.collection('meals').get();

        List<Map<String, dynamic>> meals = [];

        for (var doc in mealsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Check if this meal belongs to the current user
          final String? userId = data['userId'] as String?;
          if (userId != null && userId != currentUser.uid) {
            continue; // Skip meals that belong to other users
          }

          // Get meal name
          String mealName = '';
          if (data.containsKey('name')) {
            mealName = data['name'] as String;
          } else if (data.containsKey('nomRepas')) {
            mealName = data['nomRepas'] as String;
          }

          if (mealName.isEmpty) {
            continue; // Skip meals without a name
          }

          // Calculate total carbs - PRIORITIZE totalCarbs over totalGlucides
          double totalCarbs = 0;

          // First try totalCarbs field
          if (data.containsKey('totalCarbs')) {
            totalCarbs = (data['totalCarbs'] is num)
                ? (data['totalCarbs'] as num).toDouble()
                : double.tryParse(data['totalCarbs'].toString()) ?? 0;
          }
          // If no totalCarbs, then try totalGlucides
          else if (data.containsKey('totalGlucides')) {
            totalCarbs = (data['totalGlucides'] is num)
                ? (data['totalGlucides'] as num).toDouble()
                : double.tryParse(data['totalGlucides'].toString()) ?? 0;
          }

          // If totalCarbs is still 0 or suspiciously low, calculate from glucidesPer100g and quantity
          if (totalCarbs < 1 &&
              data.containsKey('glucidesPer100g') &&
              data.containsKey('quantity')) {
            double glucidesPer100g = (data['glucidesPer100g'] is num)
                ? (data['glucidesPer100g'] as num).toDouble()
                : double.tryParse(data['glucidesPer100g'].toString()) ?? 0;

            double quantity = (data['quantity'] is num)
                ? (data['quantity'] as num).toDouble()
                : double.tryParse(data['quantity'].toString()) ?? 0;

            // Calculate total carbs based on glucidesPer100g and quantity
            totalCarbs = (glucidesPer100g * quantity) / 100;
            print(
                'Calculated totalCarbs from glucidesPer100g: $totalCarbs (${glucidesPer100g}g per 100g × ${quantity}g ÷ 100)');
          }

          // If totalCarbs is still 0, check if totalGlucides and glucidesPer100g are the same
          // This indicates a potential error where totalGlucides wasn't calculated correctly
          if (totalCarbs < 1 &&
              data.containsKey('totalGlucides') &&
              data.containsKey('glucidesPer100g') &&
              data['totalGlucides'] == data['glucidesPer100g']) {
            // This is likely an error - recalculate using quantity
            if (data.containsKey('quantity')) {
              double glucidesPer100g = (data['glucidesPer100g'] is num)
                  ? (data['glucidesPer100g'] as num).toDouble()
                  : double.tryParse(data['glucidesPer100g'].toString()) ?? 0;

              double quantity = (data['quantity'] is num)
                  ? (data['quantity'] as num).toDouble()
                  : double.tryParse(data['quantity'].toString()) ?? 0;

              // Calculate total carbs based on glucidesPer100g and quantity
              totalCarbs = (glucidesPer100g * quantity) / 100;
              print(
                  'Fixed incorrect totalGlucides: $totalCarbs (${glucidesPer100g}g per 100g × ${quantity}g ÷ 100)');
            }
          }

          // If no total carbs found, try to calculate from ingredients
          if (totalCarbs == 0 &&
              data['ingredients'] != null &&
              data['ingredients'] is List) {
            for (var ingredient in data['ingredients']) {
              if (ingredient is Map && ingredient.containsKey('totalCarbs')) {
                totalCarbs += (ingredient['totalCarbs'] as num).toDouble();
              }
            }
          }

          meals.add({
            'id': doc.id,
            'name': mealName,
            'carbs': totalCarbs,
          });

          print('Loaded meal: $mealName with ${totalCarbs}g carbs');
        }

        setState(() {
          _mealsList = meals;
          _isLoadingMeals = false;
        });

        print('Loaded ${meals.length} meals');
      }
    } catch (e) {
      print('Error loading meals: $e');
      setState(() {
        _isLoadingMeals = false;
      });
    }
  }

  // Helper to get reduction percent from calories
  double getReductionPercentFromCalories(double totalCalories) {
    if (totalCalories <= 50) return 5;
    if (totalCalories <= 100) return 10;
    if (totalCalories <= 150) return 15;
    if (totalCalories <= 200) return 20;
    if (totalCalories <= 250) return 25;
    if (totalCalories <= 300) return 30;
    if (totalCalories <= 400) return 35;
    if (totalCalories <= 500) return 40;
    if (totalCalories <= 600) return 50;
    return 60;
  }

  // Calculate insulin dose using functional insulin therapy method
  double calculateDose(double glucose, double carbs) {
    // Calculate meal dose using the provided carbohydrate amount (which is already adjusted by quantity)
    double mealDose = carbs / icr;
    print('Meal dose: $mealDose units (${carbs}g / $icr)');

    // 2. Calculate correction dose
    double correctionDose = (glucose - targetGlucose) / isf;
    print(
        'Correction dose: $correctionDose units ((${glucose} - ${targetGlucose}) / $isf)');

    // 3. Calculate total dose before activity adjustments
    double totalDose = mealDose + correctionDose;
    print('Total dose before activity adjustment: $totalDose units');

    // 4. Apply activity reductions if applicable
    double totalActivityReduction = 0.0;
    lastUnplannedReductionUnits = 0.0;
    lastUnplannedReductionPercent = 0.0;
    lastPlannedReductionUnits = 0.0;
    lastPlannedReductionPercent = 0.0;

    // Use the new table for reduction percent
    double reductionPercent = 0.0;
    double totalCalories = 0.0;
    if (unplannedActivity) {
      totalCalories = selectedUnplannedActivityCalories *
          (selectedUnplannedActivityDuration / 30.0);
      double intensityFactor = 1.0;
      switch (unplannedActivityIntensity) {
        case 'light':
          intensityFactor = 0.8;
          break;
        case 'moderate':
          intensityFactor = 1.0;
          break;
        case 'vigorous':
          intensityFactor = 1.2;
          break;
        case 'intense':
          intensityFactor = 1.4;
          break;
        default:
          intensityFactor = 1.0;
      }
      totalCalories *= intensityFactor;
      reductionPercent = getReductionPercentFromCalories(totalCalories);
      lastUnplannedReductionPercent = reductionPercent;
      lastUnplannedReductionUnits = totalDose * (reductionPercent / 100.0);
      totalActivityReduction += lastUnplannedReductionUnits;
      print(
          'Unplanned activity: ${totalCalories.toStringAsFixed(0)} kcal, reduction: $reductionPercent%');
    }
    if (plannedActivity) {
      totalCalories = selectedPlannedActivityCalories *
          (selectedPlannedActivityDuration / 30.0);
      double intensityFactor = 1.0;
      switch (plannedActivityIntensity) {
        case 'light':
          intensityFactor = 0.8;
          break;
        case 'moderate':
          intensityFactor = 1.0;
          break;
        case 'vigorous':
          intensityFactor = 1.2;
          break;
        case 'intense':
          intensityFactor = 1.4;
          break;
        default:
          intensityFactor = 1.0;
      }
      totalCalories *= intensityFactor;
      reductionPercent = getReductionPercentFromCalories(totalCalories);
      lastPlannedReductionPercent = reductionPercent;
      lastPlannedReductionUnits = totalDose * (reductionPercent / 100.0);
      totalActivityReduction += lastPlannedReductionUnits;
      print(
          'Planned activity: ${totalCalories.toStringAsFixed(0)} kcal, reduction: $reductionPercent%');
    }

    totalDose = totalDose - totalActivityReduction;
    print('Final calculated dose: $totalDose units');
    return totalDose.clamp(0, double.infinity);
  }

  Future<Map<String, dynamic>> getMealData(String mealName) async {
    // First check if it's in our loaded meals list
    for (var meal in _mealsList) {
      if (meal['name'].toString().toLowerCase() == mealName.toLowerCase()) {
        return meal;
      }
    }

    // If not found in the list, try to find in Firestore directly
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // First try to find by exact name
        QuerySnapshot mealSnapshot = await _firestore
            .collection('meals')
            .where('name', isEqualTo: mealName)
            .limit(1)
            .get();

        // If not found, try with nomRepas field
        if (mealSnapshot.docs.isEmpty) {
          mealSnapshot = await _firestore
              .collection('meals')
              .where('nomRepas', isEqualTo: mealName)
              .limit(1)
              .get();
        }

        if (mealSnapshot.docs.isNotEmpty) {
          final data = mealSnapshot.docs.first.data() as Map<String, dynamic>;

          // Get meal name
          String foundMealName = '';
          if (data.containsKey('name')) {
            foundMealName = data['name'] as String;
          } else if (data.containsKey('nomRepas')) {
            foundMealName = data['nomRepas'] as String;
          }

          // Calculate total carbs - PRIORITIZE totalCarbs over totalGlucides
          double totalCarbs = 0;

          // First try totalCarbs field
          if (data.containsKey('totalCarbs')) {
            totalCarbs = (data['totalCarbs'] is num)
                ? (data['totalCarbs'] as num).toDouble()
                : double.tryParse(data['totalCarbs'].toString()) ?? 0;
          }
          // If no totalCarbs, then try totalGlucides
          else if (data.containsKey('totalGlucides')) {
            totalCarbs = (data['totalGlucides'] is num)
                ? (data['totalGlucides'] as num).toDouble()
                : double.tryParse(data['totalGlucides'].toString()) ?? 0;
          }

          // If totalCarbs is still 0 or suspiciously low, calculate from glucidesPer100g and quantity
          if (totalCarbs < 1 &&
              data.containsKey('glucidesPer100g') &&
              data.containsKey('quantity')) {
            double glucidesPer100g = (data['glucidesPer100g'] is num)
                ? (data['glucidesPer100g'] as num).toDouble()
                : double.tryParse(data['glucidesPer100g'].toString()) ?? 0;

            double quantity = (data['quantity'] is num)
                ? (data['quantity'] as num).toDouble()
                : double.tryParse(data['quantity'].toString()) ?? 0;

            // Calculate total carbs based on glucidesPer100g and quantity
            totalCarbs = (glucidesPer100g * quantity) / 100;
            print(
                'Calculated totalCarbs from glucidesPer100g: $totalCarbs (${glucidesPer100g}g per 100g × ${quantity}g ÷ 100)');
          }

          // If totalCarbs is still 0, check if totalGlucides and glucidesPer100g are the same
          // This indicates a potential error where totalGlucides wasn't calculated correctly
          if (totalCarbs < 1 &&
              data.containsKey('totalGlucides') &&
              data.containsKey('glucidesPer100g') &&
              data['totalGlucides'] == data['glucidesPer100g']) {
            // This is likely an error - recalculate using quantity
            if (data.containsKey('quantity')) {
              double glucidesPer100g = (data['glucidesPer100g'] is num)
                  ? (data['glucidesPer100g'] as num).toDouble()
                  : double.tryParse(data['glucidesPer100g'].toString()) ?? 0;

              double quantity = (data['quantity'] is num)
                  ? (data['quantity'] as num).toDouble()
                  : double.tryParse(data['quantity'].toString()) ?? 0;

              // Calculate total carbs based on glucidesPer100g and quantity
              totalCarbs = (glucidesPer100g * quantity) / 100;
              print(
                  'Fixed incorrect totalGlucides: $totalCarbs (${glucidesPer100g}g per 100g × ${quantity}g ÷ 100)');
            }
          }

          // If no total carbs found, try to calculate from ingredients
          if (totalCarbs == 0 &&
              data['ingredients'] != null &&
              data['ingredients'] is List) {
            for (var ingredient in data['ingredients']) {
              if (ingredient is Map && ingredient.containsKey('totalCarbs')) {
                totalCarbs += (ingredient['totalCarbs'] as num).toDouble();
              }
            }
          }

          return {
            'id': mealSnapshot.docs.first.id,
            'name': foundMealName,
            'carbs': totalCarbs,
          };
        }
      }
    } catch (e) {
      print('Error fetching meal from Firestore: $e');
    }

    // If still not found, return empty data
    return {'id': '', 'name': mealName, 'carbs': 0.0};
  }

  Future<bool> checkIfMealExists(String name) async {
    if (name.isEmpty) return false;

    // First check in our loaded meals list
    for (var meal in _mealsList) {
      if (meal['name'].toString().toLowerCase() == name.toLowerCase()) {
        return true;
      }
    }

    // If not found in the list, try to find in Firestore directly
    final mealData = await getMealData(name);
    return (mealData['carbs'] as double) > 0;
  }

  void _showMealSelectionDialog() async {
    if (_mealsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No meals found. Please add a meal first.",
            style: TextStyle(fontFamily: 'SfProDisplay'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedMeal = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Select Meal",
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A7BF7),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7BF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddPlateScreen()),
                    ).then((_) {
                      _loadUserMeals();
                      Navigator.pop(context); // Close the dialog
                    });
                  },
                  child: const Text(
                    "Add New Meal",
                    style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Text(
                "Recent Meals",
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A7BF7),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _mealsList.length,
                  itemBuilder: (context, index) {
                    final meal = _mealsList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          meal['name'],
                          style: const TextStyle(
                            fontFamily: 'SfProDisplay',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${(meal['carbs'] as double).toStringAsFixed(1)}g carbs',
                          style: const TextStyle(
                            fontFamily: 'SfProDisplay',
                            color: Colors.grey,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF4A7BF7),
                          size: 16,
                        ),
                        onTap: () => Navigator.pop(context, meal),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                color: Color(0xFF4A7BF7),
              ),
            ),
          ),
        ],
      ),
    );

    if (selectedMeal != null) {
      setState(() {
        _selectedMeal = selectedMeal;
        mealController.text = selectedMeal['name'];
      });
    }
  }

  Future<void> _checkRecentActivity({bool isPlanned = false}) async {
    setState(() {
      _isLoadingActivity = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('Checking for activities for user: ${currentUser.uid}');

        // Get the most recent activity
        final QuerySnapshot activitySnapshot = await _firestore
            .collection('activities')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        print('Found ${activitySnapshot.docs.length} activities');

        if (activitySnapshot.docs.isNotEmpty) {
          final latestActivity =
              activitySnapshot.docs.first.data() as Map<String, dynamic>;
          print('Latest activity data: $latestActivity');

          // Extract calories with multiple possible field names
          double calories = 0.0;
          if (latestActivity.containsKey('cal30mn')) {
            calories =
                double.tryParse(latestActivity['cal30mn'].toString()) ?? 0.0;
            print('Found calories in cal30mn field: $calories');
          } else if (latestActivity.containsKey('calories')) {
            calories =
                double.tryParse(latestActivity['calories'].toString()) ?? 0.0;
            print('Found calories in calories field: $calories');
          } else if (latestActivity.containsKey('caloriesPer30Min')) {
            calories = double.tryParse(
                    latestActivity['caloriesPer30Min'].toString()) ??
                0.0;
            print('Found calories in caloriesPer30Min field: $calories');
          }

          // Extract duration
          int duration = 30;
          if (latestActivity.containsKey('duration')) {
            duration =
                int.tryParse(latestActivity['duration'].toString()) ?? 30;
            print('Found duration: $duration');
          }

          // Calculate reduction based on calories with more varied percentages
          double reduction = 0.0;
          if (calories > 0) {
            // More granular calorie-based reduction
            if (calories < 30) {
              reduction = 0.05; // 5%
            } else if (calories < 60) {
              reduction = 0.10; // 10%
            } else if (calories < 90) {
              reduction = 0.15; // 15%
            } else if (calories < 120) {
              reduction = 0.20; // 20%
            } else if (calories < 150) {
              reduction = 0.25; // 25%
            } else if (calories < 200) {
              reduction = 0.30; // 30%
            } else if (calories < 250) {
              reduction = 0.35; // 35%
            } else {
              reduction = 0.40; // 40%
            }

            // Add duration bonus for longer activities
            if (duration > 45) {
              reduction += 0.05; // +5% for longer activities
            }
          } else {
            // If no calories, try to use activity name/type
            String activityName =
                latestActivity['nom']?.toString().toLowerCase() ?? '';
            print('No calories found, using activity name: $activityName');

            if (activityName.contains('walk') ||
                activityName.contains('light')) {
              reduction = 0.10; // 10%
            } else if (activityName.contains('jog') ||
                activityName.contains('moderate')) {
              reduction = 0.20; // 20%
            } else if (activityName.contains('run') ||
                activityName.contains('vigorous')) {
              reduction = 0.30; // 30%
            } else if (activityName.contains('sprint') ||
                activityName.contains('intense')) {
              reduction = 0.40; // 40%
            } else {
              reduction = 0.15; // Default 15% for unknown activities
            }
          }

          print('Final reduction: ${(reduction * 100).toStringAsFixed(0)}%');

          setState(() {
            if (isPlanned) {
              plannedActivityReductionFactor = reduction;
            } else {
              unplannedActivityReductionFactor = reduction;
            }
          });
        } else {
          print('No activities found');
          // Don't set any reduction if no activities found
          setState(() {
            if (isPlanned) {
              plannedActivityReductionFactor = 0.0;
            } else {
              unplannedActivityReductionFactor = 0.0;
            }
          });
        }
      }
    } catch (e) {
      print('Error checking recent activity: $e');
      // On error, don't set any reduction
      setState(() {
        if (isPlanned) {
          plannedActivityReductionFactor = 0.0;
        } else {
          unplannedActivityReductionFactor = 0.0;
        }
      });
    } finally {
      setState(() {
        _isLoadingActivity = false;
      });
    }
  }

  // Replace the _handleUnplannedActivity method
  void _handleUnplannedActivity() async {
    print('Starting unplanned activity selection');
    final User? currentUser = _auth.currentUser;
    print('Current user: [32m${currentUser?.uid}[0m');

    final selectedActivity = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Select Activity",
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A7BF7),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7BF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivityScreen()),
                    ).then((_) {
                      Navigator.pop(context); // Close dialog
                    });
                  },
                  child: const Text(
                    "Add New Activity",
                    style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Text(
                "Recent Activities",
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A7BF7),
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<QuerySnapshot>(
                future: _firestore
                    .collection('activities')
                    .where('userId', isEqualTo: currentUser?.uid)
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .get(),
                builder: (context, snapshot) {
                  // Debug prints
                  if (snapshot.hasError) {
                    print('Activity query error: \\${snapshot.error}');
                  }
                  if (snapshot.hasData) {
                    print(
                        'Activity query found \\${snapshot.data!.docs.length} docs');
                    for (var doc in snapshot.data!.docs) {
                      print('Activity doc: \\${doc.data()}');
                    }
                  }
                  // Fallback: if error or no data, try to show all activities
                  if ((snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.docs.isEmpty)) {
                    return FutureBuilder<QuerySnapshot>(
                      future: _firestore.collection('activities').get(),
                      builder: (context, fallbackSnapshot) {
                        if (fallbackSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4A7BF7),
                            ),
                          );
                        }
                        if (!fallbackSnapshot.hasData ||
                            fallbackSnapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "No recent activities found",
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: fallbackSnapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = fallbackSnapshot.data!.docs[index];
                            final activity = doc.data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  activity['nom'] ?? 'Unknown Activity',
                                  style: const TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${activity['cal30mn']?.toString() ?? '0'} calories/30min - ${activity['duration'] ?? 30} minutes',
                                  style: const TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFF4A7BF7),
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.pop(context, {
                                    ...activity,
                                    'id': doc.id,
                                  });
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  // Normal display
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final activity = doc.data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            activity['nom'] ?? 'Unknown Activity',
                            style: const TextStyle(
                              fontFamily: 'SfProDisplay',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${activity['cal30mn']?.toString() ?? '0'} calories/30min - ${activity['duration'] ?? 30} minutes',
                            style: const TextStyle(
                              fontFamily: 'SfProDisplay',
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF4A7BF7),
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context, {
                              ...activity,
                              'id': doc.id,
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                color: Color(0xFF4A7BF7),
              ),
            ),
          ),
        ],
      ),
    );

    if (selectedActivity != null) {
      setState(() {
        double calories = (selectedActivity['cal30mn'] is num)
            ? (selectedActivity['cal30mn'] as num).toDouble()
            : double.tryParse(selectedActivity['cal30mn'].toString()) ?? 0.0;
        int duration = (selectedActivity['duration'] is num)
            ? (selectedActivity['duration'] as num).toInt()
            : int.tryParse(selectedActivity['duration'].toString()) ?? 30;
        selectedUnplannedActivityCalories = calories;
        selectedUnplannedActivityDuration = duration;
      });
    }
  }

  // Replace the _handlePlannedActivity method
  void _handlePlannedActivity() async {
    print('Starting planned activity selection');
    final User? currentUser = _auth.currentUser;
    print('Current user: [32m${currentUser?.uid}[0m');

    final selectedActivity = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Select Activity",
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A7BF7),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7BF7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivityScreen()),
                    ).then((_) {
                      Navigator.pop(context); // Close dialog
                    });
                  },
                  child: const Text(
                    "Add New Activity",
                    style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Text(
                "Recent Activities",
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A7BF7),
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<QuerySnapshot>(
                future: _firestore
                    .collection('activities')
                    .where('userId', isEqualTo: currentUser?.uid)
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .get(),
                builder: (context, snapshot) {
                  // Debug prints
                  if (snapshot.hasError) {
                    print('Activity query error: \\${snapshot.error}');
                  }
                  if (snapshot.hasData) {
                    print(
                        'Activity query found \\${snapshot.data!.docs.length} docs');
                    for (var doc in snapshot.data!.docs) {
                      print('Activity doc: \\${doc.data()}');
                    }
                  }
                  // Fallback: if error or no data, try to show all activities
                  if ((snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.docs.isEmpty)) {
                    return FutureBuilder<QuerySnapshot>(
                      future: _firestore.collection('activities').get(),
                      builder: (context, fallbackSnapshot) {
                        if (fallbackSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4A7BF7),
                            ),
                          );
                        }
                        if (!fallbackSnapshot.hasData ||
                            fallbackSnapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "No recent activities found",
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: fallbackSnapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = fallbackSnapshot.data!.docs[index];
                            final activity = doc.data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  activity['nom'] ?? 'Unknown Activity',
                                  style: const TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${activity['cal30mn']?.toString() ?? '0'} calories/30min - ${activity['duration'] ?? 30} minutes',
                                  style: const TextStyle(
                                    fontFamily: 'SfProDisplay',
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFF4A7BF7),
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.pop(context, {
                                    ...activity,
                                    'id': doc.id,
                                  });
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  // Normal display
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final activity = doc.data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            activity['nom'] ?? 'Unknown Activity',
                            style: const TextStyle(
                              fontFamily: 'SfProDisplay',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${activity['cal30mn']?.toString() ?? '0'} calories/30min - ${activity['duration'] ?? 30} minutes',
                            style: const TextStyle(
                              fontFamily: 'SfProDisplay',
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF4A7BF7),
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context, {
                              ...activity,
                              'id': doc.id,
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                color: Color(0xFF4A7BF7),
              ),
            ),
          ),
        ],
      ),
    );

    if (selectedActivity != null) {
      setState(() {
        double calories = (selectedActivity['cal30mn'] is num)
            ? (selectedActivity['cal30mn'] as num).toDouble()
            : double.tryParse(selectedActivity['cal30mn'].toString()) ?? 0.0;
        int duration = (selectedActivity['duration'] is num)
            ? (selectedActivity['duration'] as num).toInt()
            : int.tryParse(selectedActivity['duration'].toString()) ?? 30;
        selectedPlannedActivityCalories = calories;
        selectedPlannedActivityDuration = duration;
      });
    }
  }

  void _saveLog() async {
    final glucoseText = glucoseController.text.trim();
    final meal = mealController.text.trim();

    if (glucoseText.isEmpty || double.tryParse(glucoseText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid glucose value.",
            style: TextStyle(fontFamily: 'SfProDisplay'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (meal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a meal name.",
            style: TextStyle(fontFamily: 'SfProDisplay'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final glucose = double.parse(glucoseText);

    // If we have a selected meal, use that directly
    double carbs = 0;
    if (_selectedMeal != null) {
      carbs =
          _selectedMeal!['carbs'] as double; // Base carbs from selected meal
    } else {
      // Otherwise check if the meal exists
      final exists = await checkIfMealExists(meal);

      if (!exists) {
        // If meal doesn't exist, ask if they want to create it or enter carbs manually
        final manualCarbs = await showDialog<double>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            final TextEditingController carbsController =
                TextEditingController();
            return AlertDialog(
              title: Text(
                'Meal "$meal" not found',
                style: const TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Would you like to create this meal or enter carbs manually?',
                    style: TextStyle(fontFamily: 'SfProDisplay'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: carbsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      hintText: 'Enter carbohydrates in grams',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, null); // Cancel
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddPlateScreen()),
                    ).then((_) {
                      // Refresh meals when returning from add plate screen
                      _loadUserMeals();
                      Navigator.pop(context, null); // Close dialog
                    });
                  },
                  child: const Text('Create Meal'),
                ),
                TextButton(
                  onPressed: () {
                    final carbs = double.tryParse(carbsController.text);
                    if (carbs != null && carbs > 0) {
                      Navigator.pop(context, carbs);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid carb value'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Use Manual Carbs'),
                ),
              ],
            );
          },
        );

        if (manualCarbs == null) {
          setState(() => _isSaving = false);
          return;
        }

        carbs = manualCarbs;
      } else {
        // Get meal data
        final mealData = await getMealData(meal);
        carbs = mealData['carbs'] as double;
      }
    }

    // Calculate final carbs for the dose calculation and saving
    double adjustedCarbs = carbs * _mealQuantity;
    print(
        'Final carbohydrates for calculation: $adjustedCarbs g (Base: $carbs g * Quantity: $_mealQuantity)'); // Debug print

    // Calculate insulin dose
    final dose = calculateDose(
        glucose, adjustedCarbs); // Pass adjusted carbs to calculateDose

    // Calculate individual components for the breakdown
    final mealDose =
        adjustedCarbs / icr; // Use adjusted carbs for breakdown display
    final correctionDose = (glucose - targetGlucose) / isf;

    // Calculate total effective activity reduction
    double effectiveActivityReduction = 0.0;
    if (unplannedActivity) {
      effectiveActivityReduction += unplannedActivityReductionFactor;
    }
    if (plannedActivity) {
      effectiveActivityReduction += plannedActivityReductionFactor;
    }

    // Create Injection object
    final User? currentUser = _auth.currentUser;
    final now = DateTime.now();
    final timeOfDay = TimeOfDay.fromDateTime(now);

    final injection = Injection(
      tempsInject: timeOfDay,
      glycemie: glucose.round(),
      quantiteGlu: adjustedCarbs, // Save the calculated adjusted carbs
      doseInsuline: dose,
      mealName: meal,
      userId: currentUser?.uid,
      timestamp: now,
      activityReduction: effectiveActivityReduction,
    );

    // Save the calculation to Firestore
    try {
      if (currentUser != null) {
        // Save injection data
        await injection.saveToFirestore();
        print('Insulin dose saved successfully');

        // Update last operations in user document
        await _firestore.collection('users').doc(currentUser.uid).set(
            {
              'lastOperations': {
                'injection': {
                  'value': dose.toDouble(),
                  'timestamp': now.toIso8601String(),
                  'glucoseValue': glucose,
                },
                'meal': {
                  'value': meal,
                  'timestamp': now.toIso8601String(),
                }
              }
            },
            SetOptions(
                merge:
                    true)); // Use merge: true to avoid overwriting other fields
        print('User last operations updated successfully');
      }
    } catch (e) {
      print('Error saving insulin dose: $e');
    }

    // Round to nearest whole number for display
    final roundedDose = dose.round(); // Round to the nearest whole number

    // Navigate to result screen with calculation details
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoseResultScreen(
          dose: roundedDose.toDouble(),
          glucoseLevel: glucose,
          carbAmount: carbs,
          mealDose: mealDose,
          correctionDose: correctionDose,
          activityReduction: effectiveActivityReduction,
          activityReductionUnits: effectiveActivityReduction > 0
              ? (lastUnplannedReductionUnits + lastPlannedReductionUnits)
              : 0.0,
          activityReductionPercent:
              lastUnplannedReductionPercent + lastPlannedReductionPercent,
          mealName: meal,
          unplannedActivityCalories: _calculatedUnplannedActivityCalories,
          plannedActivityCalories: _calculatedPlannedActivityCalories,
          adjustedCarbAmount:
              adjustedCarbs, // Pass the adjusted carbs to the result screen
        ),
      ),
    );
    // Reset form when returning from result screen
    _resetScreen();
    if (result == true) {
      Navigator.pop(context, true); // Pop this screen and signal reload
    }
    setState(() => _isSaving = false);
  }

  Widget _buildLabel(String text, String iconPath) {
    return Row(
      children: [
        Image.asset(iconPath, width: 17, height: 17),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'SfProDisplay',
          color: Colors.black54,
        ),
        filled: true,
        fillColor: Colors.grey[300],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
      style: const TextStyle(fontFamily: 'SfProDisplay'),
    );
  }

  Widget _buildActivityIntensitySelector({
    required String title,
    required String currentValue,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A7BF7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              style: const TextStyle(
                fontFamily: 'SfProDisplay',
                color: Colors.black87,
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('No Activity')),
                DropdownMenuItem(value: 'light', child: Text('Light (10%)')),
                DropdownMenuItem(
                    value: 'moderate', child: Text('Moderate (20%)')),
                DropdownMenuItem(
                    value: 'vigorous', child: Text('Vigorous (30%)')),
                DropdownMenuItem(
                    value: 'intense', child: Text('Intense (40%)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Dose calculator',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Color(0xFF4A7BF7),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A7BF7)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    _buildLabel(
                        'Pre-meal glucose', 'assets/images/glucose.png'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: glucoseController,
                      hintText: 'Enter pre-meal blood sugar (mg/dL)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Image.asset('assets/images/activity.png',
                            height: 20, width: 20),
                        const SizedBox(width: 6),
                        const Text(
                          'Unplanned activity was done?',
                          style: TextStyle(
                            fontFamily: 'SfProDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: unplannedActivity,
                          onChanged: (value) {
                            setState(() {
                              unplannedActivity = value!;
                              if (value) {
                                _handleUnplannedActivity();
                              } else {
                                unplannedActivityReductionFactor = 0.0;
                              }
                            });
                          },
                          fillColor: MaterialStateProperty.all(
                              const Color(0xFF4A7BF7)),
                        ),
                        const Text('Yes',
                            style: TextStyle(fontFamily: 'SfProDisplay')),
                        const SizedBox(width: 110),
                        Radio<bool>(
                          value: false,
                          groupValue: unplannedActivity,
                          onChanged: (value) {
                            setState(() {
                              unplannedActivity = value!;
                              if (!value) {
                                unplannedActivityReductionFactor = 0.0;
                              }
                            });
                          },
                          fillColor: MaterialStateProperty.all(
                              const Color(0xFF4A7BF7)),
                        ),
                        const Text('No',
                            style: TextStyle(fontFamily: 'SfProDisplay')),
                      ],
                    ),
                    if (unplannedActivity && lastUnplannedReductionUnits > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                        child: Text(
                          'Activity reduction: ${lastUnplannedReductionUnits.toStringAsFixed(2)} units (${lastUnplannedReductionPercent.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontFamily: 'SfProDisplay',
                            color: Color(0xFF4A7BF7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildLabel(
                        'What did you eat', 'assets/images/context.png'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: mealController,
                      hintText: 'Select or enter meal name',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoadingMeals)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.list),
                            onPressed: _showMealSelectionDialog,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Meal Quantity Input with Step Buttons (Moved to correct position)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quantity of meal',
                            style: TextStyle(
                              fontFamily: 'SfProDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          color: Color(0xFF4A7BF7)),
                                      onPressed: () {
                                        setState(() {
                                          if (_mealQuantity > 0.0) {
                                            _mealQuantity = (_mealQuantity -
                                                    0.25)
                                                .clamp(0.0, double.infinity);
                                          } else {
                                            _mealQuantity = 0.0;
                                          }
                                        });
                                      },
                                    ),
                                    Text(
                                      _mealQuantity.toStringAsFixed(
                                          _mealQuantity == 0.0 ? 0 : 2),
                                      style: const TextStyle(
                                        fontFamily: 'SfProDisplay',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Color(0xFF4A7BF7)),
                                      onPressed: () {
                                        setState(() {
                                          _mealQuantity += 0.25;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A7BF7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.info_outline,
                                    color: Colors.white),
                                onPressed: _showBolChinoisInfo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Image.asset('assets/images/activity.png',
                            height: 20, width: 20),
                        const SizedBox(width: 6),
                        const Text(
                          'Planned activity to do?',
                          style: TextStyle(
                            fontFamily: 'SfProDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: plannedActivity,
                          onChanged: (value) {
                            setState(() {
                              plannedActivity = value!;
                              if (value) {
                                _handlePlannedActivity();
                              } else {
                                plannedActivityReductionFactor = 0.0;
                              }
                            });
                          },
                          fillColor: MaterialStateProperty.all(
                              const Color(0xFF4A7BF7)),
                        ),
                        const Text('Yes',
                            style: TextStyle(fontFamily: 'SfProDisplay')),
                        const SizedBox(width: 110),
                        Radio<bool>(
                          value: false,
                          groupValue: plannedActivity,
                          onChanged: (value) {
                            setState(() {
                              plannedActivity = value!;
                              if (!value) {
                                plannedActivityReductionFactor = 0.0;
                              }
                            });
                          },
                          fillColor: MaterialStateProperty.all(
                              const Color(0xFF4A7BF7)),
                        ),
                        const Text('No',
                            style: TextStyle(fontFamily: 'SfProDisplay')),
                      ],
                    ),
                    if (plannedActivity && lastPlannedReductionUnits > 0)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 16.0, bottom: 16.0),
                        child: Text(
                          'Activity reduction: ${lastPlannedReductionUnits.toStringAsFixed(2)} units (${lastPlannedReductionPercent.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontFamily: 'SfProDisplay',
                            color: Color(0xFF4A7BF7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLog,
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
                          'Calculate dose',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SfProDisplay',
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    glucoseController.dispose();
    mealController.dispose();
    super.dispose();
  }

  void _showBolChinoisInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'The Chinese Bowl Method',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A7BF7),
          ),
        ),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'The quantity of the meal helps estimate carbohydrate intake based on portion size. \n\n',
                style: TextStyle(fontFamily: 'SfProDisplay'),
              ),
              Text(
                '**The Chinese Bowl Method:**',
                style: TextStyle(
                    fontFamily: 'SfProDisplay', fontWeight: FontWeight.bold),
              ),
              Text(
                'This method uses a standard bowl size as a reference for portion estimation, especially for meals like rice, pasta, or cereals.\n\n',
                style: TextStyle(fontFamily: 'SfProDisplay'),
              ),
              Text(
                '**Examples:**\n',
                style: TextStyle(
                    fontFamily: 'SfProDisplay', fontWeight: FontWeight.bold),
              ),
              Text(
                '- For a standard slice of pizza, a quantity of 1 might be used.\n',
                style: TextStyle(fontFamily: 'SfProDisplay'),
              ),
              Text(
                '- For a large plate of pasta, a quantity of 1.5 or 2 might be used.\n',
                style: TextStyle(fontFamily: 'SfProDisplay'),
              ),
              Text(
                '- For a small side dish, a quantity of 0.5 might be appropriate.\n\n',
                style: TextStyle(fontFamily: 'SfProDisplay'),
              ),
              Text(
                'Adjust the quantity based on your usual portion sizes and how they compare to a standard serving.',
                style: TextStyle(fontFamily: 'SfProDisplay'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                color: Color(0xFF4A7BF7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
