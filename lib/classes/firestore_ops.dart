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

  // Add a meal
  Future<void> addMeal(
      String idRepas, String nomRepas, List<Map<String, dynamic>> ingredients) {
    double totalGlucides = 0.0;
    for (var ingredient in ingredients) {
      totalGlucides += ingredient['glucidesPer100g'];
    }

    Map<String, dynamic> mealData = {
      'idRepas': idRepas,
      'nomRepas': nomRepas,
      'ingredients': ingredients,
      'totalGlucides': totalGlucides,
    };

    return _db.collection('meals').doc(idRepas).set(mealData);
  }

  // Add an injection
  Future<void> addInjection(Injection injection, BuildContext context) {
    return _db.collection('injections').add(injection.toJson(context));
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
