import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Injection {
  final TimeOfDay tempsInject;
  final int glycemie;
  final double quantiteGlu;
  final double doseInsuline;
  final String mealName;
  final String? userId;
  final DateTime timestamp;
  final double activityReduction;

  Injection({
    required this.tempsInject,
    required this.glycemie,
    required this.quantiteGlu,
    required this.doseInsuline,
    required this.mealName,
    this.userId,
    required this.timestamp,
    this.activityReduction = 0.0,
  });

  double calculerDose(Map<String, dynamic> inputs) {
    double glycemie = inputs['glycemie'] ?? 0.0;
    double glucides = inputs['glucides'] ?? 0.0;
    double glycemieCible = inputs['glycemieCible'] ?? 100.0;
    double ratioInsulineGlucide = inputs['ratioInsulineGlucide'] ?? 10.0;
    double sensitiviteInsuline = inputs['sensitiviteInsuline'] ?? 50.0;
    double activityFactor = inputs['activityFactor'] ?? 0.0;

    // 1. Calculate carbohydrate coverage
    double mealDose = glucides / ratioInsulineGlucide;
    print('Meal dose: $mealDose units (${glucides}g / $ratioInsulineGlucide)');

    // 2. Calculate correction dose
    double correctionDose = (glycemie - glycemieCible) / sensitiviteInsuline;
    print(
        'Correction dose: $correctionDose units ((${glycemie} - ${glycemieCible}) / $sensitiviteInsuline)');

    // 3. Apply activity reduction if applicable
    double totalDose = mealDose + correctionDose;
    print('Total dose before activity adjustment: $totalDose units');

    if (activityFactor > 0) {
      double reduction = totalDose * activityFactor;
      totalDose = totalDose - reduction;
      print('Activity reduction: $reduction units (${activityFactor * 100}%)');
    }

    print('Final calculated dose: $totalDose units');

    // 4. Ensure dose is not negative
    return totalDose.clamp(0, double.infinity);
  }

  Map<String, dynamic> toJson() {
    return {
      'tempsInject':
          '${tempsInject.hour.toString().padLeft(2, '0')}:${tempsInject.minute.toString().padLeft(2, '0')}',
      'glycemie': glycemie,
      'quantiteGlu': quantiteGlu,
      'doseInsuline': doseInsuline,
      'mealName': mealName,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'activityReduction': activityReduction,
    };
  }

  Future<void> saveToFirestore() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Add to Firestore using toJson method
      await firestore.collection('injections').add(toJson());
    } catch (e) {
      print('Error saving injection to Firestore: $e');
      throw e;
    }
  }

  static Injection fromJson(Map<String, dynamic> json) {
    // Parse time string to TimeOfDay
    final timeString = json['tempsInject'] as String;
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return Injection(
      tempsInject: TimeOfDay(hour: hour, minute: minute),
      glycemie: json['glycemie'] as int,
      quantiteGlu: (json['quantiteGlu'] as num).toDouble(),
      doseInsuline: (json['doseInsuline'] as num).toDouble(),
      mealName: json['mealName'] as String,
      userId: json['userId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      activityReduction: (json['activityReduction'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
