import 'package:flutter/material.dart';

class Injection {
  TimeOfDay tempsInject;
  int glycemie;
  double quantiteGlu;

  Injection({
    required this.tempsInject,
    required this.glycemie,
    required this.quantiteGlu,
  });

  double calculerDose(Map<String, dynamic> inputs) {
    double glycemie = inputs['glycemie'];
    double glucides = inputs['glucides'];
    int quantiteRepas = inputs['quantiteRepas'];
    double caloriesBurned = inputs['caloriesBurned'];
    double glycemieCible = inputs['glycemieCible'];
    double ratioInsulineGlucide = inputs['ratioInsulineGlucide'];
    double sensitiviteInsuline = inputs['sensitiviteInsuline'];

    // Calculate basal insulin dose
    double basalInsulin = glucides / ratioInsulineGlucide;

    // Calculate bolus insulin dose
    double bolusInsulin = (glycemie - glycemieCible) / sensitiviteInsuline;

    // Adjust for physical activity (calories burned)
    double activityAdjustment = caloriesBurned /
        100; // Assuming 100 calories burned reduces 1 unit of insulin

    // Sum basal and bolus insulin doses
    double totalInsulinDose = basalInsulin + bolusInsulin - activityAdjustment;

    print('Basal Insulin: $basalInsulin units');
    print('Bolus Insulin: $bolusInsulin units');
    print('Activity Adjustment: $activityAdjustment units');
    print('Total Insulin Dose: $totalInsulinDose units');

    return totalInsulinDose;
  }

  void couvre() {
    // Implementation of couvre method
  }

  void reduit() {
    // Implementation of reduit method
  }

  void injecte() {
    // Implementation of injecte method
  }

  Map<String, dynamic> toJson(BuildContext context) {
    return {
      'tempsInject': tempsInject.format(context),
      'glycemie': glycemie,
      'quantiteGlu': quantiteGlu,
    };
  }

  factory Injection.fromJson(Map<String, dynamic> json, BuildContext context) {
    return Injection(
      tempsInject: TimeOfDay(
        hour: int.parse(json['tempsInject'].split(":")[0]),
        minute: int.parse(json['tempsInject'].split(":")[1]),
      ),
      glycemie: json['glycemie'],
      quantiteGlu: json['quantiteGlu'],
    );
  }
}
