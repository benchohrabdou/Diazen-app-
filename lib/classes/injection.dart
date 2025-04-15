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

  void calculerDose() {}

  void couvre() {}

  void reduit() {}

  void injecte() {}
}
