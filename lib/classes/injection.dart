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

  void calculerDose() {
    // Implementation of calculerDose method
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
