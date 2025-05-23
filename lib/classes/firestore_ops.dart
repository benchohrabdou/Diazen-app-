import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'utilisateur.dart';
import 'medecin.dart';
import 'injection.dart';
import 'activite.dart';
import 'ingredient.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a document to a collection
  Future<void> addDocument(String collectionPath, Map<String, dynamic> data) {
    return _db.collection(collectionPath).add(data);
  }

  // Get a document by ID
  Future<DocumentSnapshot> getDocument(String collectionPath, String docId) {
    return _db.collection(collectionPath).doc(docId).get();
  }

  // Update a document by ID
  Future<void> updateDocument(
      String collectionPath, String docId, Map<String, dynamic> data) {
    return _db.collection(collectionPath).doc(docId).update(data);
  }

  // Delete a document by ID
  Future<void> deleteDocument(String collectionPath, String docId) {
    return _db.collection(collectionPath).doc(docId).delete();
  }

  // Stream documents from a collection
  Stream<QuerySnapshot> streamCollection(String collectionPath) {
    return _db.collection(collectionPath).snapshots();
  }

  // Add a patient
  Future<void> addPatient(Utilisateur utilisateur) {
    return _db
        .collection('users')
        .doc(utilisateur.id)
        .set(utilisateur.toJson());
  }

  // Add a doctor
  Future<void> addDoctor(Medecin medecin) {
    return _db.collection('doctors').doc(medecin.id).set(medecin.toJson());
  }

  // Add a meal - FIXED VERSION
  Future<void> addMeal(String idRepas, String nomRepas,
      List<Map<String, dynamic>> ingredients, String userId) {
    // Calculate total carbs correctly by summing up the totalCarbs of each ingredient
    double totalGlucides = 0.0;
    for (var ingredient in ingredients) {
      // Use totalCarbs instead of glucidesPer100g
      totalGlucides += (ingredient['totalCarbs'] ?? 0.0);
    }

    Map<String, dynamic> mealData = {
      'idRepas': idRepas,
      'name': nomRepas, // Add name field for consistency
      'nomRepas': nomRepas,
      'ingredients': ingredients,
      'totalGlucides': totalGlucides, // Now correctly calculated
      'totalCarbs': totalGlucides, // Add totalCarbs field for consistency
      'userId': userId, // Add userId to associate meal with user
      'timestamp': DateTime.now().toIso8601String(), // Add timestamp
    };

    return _db.collection('meals').doc(idRepas).set(mealData);
  }

  // Utility function to fix existing meals in the database
  Future<int> fixExistingMeals(String userId) async {
    try {
      // Get all meals for the current user
      final QuerySnapshot mealsSnapshot = await _db
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .get();

      int fixedCount = 0;

      // Check each meal and fix if needed
      for (var doc in mealsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if totalGlucides needs to be recalculated
        if (data.containsKey('ingredients') && data['ingredients'] is List) {
          final ingredients = data['ingredients'] as List;

          // Calculate correct total carbs from ingredients
          double correctTotalCarbs = 0.0;
          for (var ingredient in ingredients) {
            if (ingredient is Map && ingredient.containsKey('totalCarbs')) {
              correctTotalCarbs += (ingredient['totalCarbs'] as num).toDouble();
            }
          }

          // Check if current totalGlucides is incorrect
          double currentTotalGlucides = (data['totalGlucides'] is num)
              ? (data['totalGlucides'] as num).toDouble()
              : 0.0;

          // If the values are different, update the document
          if ((correctTotalCarbs - currentTotalGlucides).abs() > 0.01) {
            await _db.collection('meals').doc(doc.id).update({
              'totalGlucides': correctTotalCarbs,
              'totalCarbs': correctTotalCarbs,
              'name': data['nomRepas'], // Ensure name field exists
            });

            fixedCount++;
          }
        }
      }

      return fixedCount;
    } catch (e) {
      print('Error fixing meals: $e');
      return 0;
    }
  }

  // Add an injection
  Future<void> addInjection(Injection injection, BuildContext context) {
    return _db.collection('injections').add(injection.toJson());
  }

  // Add an activity
  Future<void> addActivity(Activite activite) {
    return _db.collection('activities').add(activite.toJson());
  }

  // Add an ingredient
  Future<void> addIngredient(Ingredient ingredient) {
    return _db.collection('ingredients').add(ingredient.toJson());
  }
}
