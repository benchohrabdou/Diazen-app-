class Activite {
  String nom;
  double cal30mn;
  String typeAct;

  Activite({
    required this.nom,
    required this.cal30mn,
    required this.typeAct,
  });

  void calculerReduction() {
    // Implementation of calculerReduction method
  }

  void calTotal() {
    // Implementation of calTotal method
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'cal30mn': cal30mn,
      'typeAct': typeAct,
    };
  }
}
