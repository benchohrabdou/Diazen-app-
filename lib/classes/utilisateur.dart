import 'personne.dart';

class Utilisateur extends Personne {
  int diabType;
  final double _ratioInsulineGlucide;
  final double _sensitiviteInsuline;
  final double _poids;
  final double _taille;

  Utilisateur({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.dateNaissance,
    required super.email,
    required super.tel,
    required this.diabType,
    required double ratioInsulineGlucide,
    required double sensitiviteInsuline,
    required double poids,
    required double taille,
  })  : _ratioInsulineGlucide = ratioInsulineGlucide,
        _sensitiviteInsuline = sensitiviteInsuline,
        _poids = poids,
        _taille = taille;

  void demanderCalcul() {
    // Implementation of demanderCalcul method
  }

  void saisirGlycemie() {
    // Implementation of saisirGlycemie method
  }

  void ajouterRepas() {
    // Implementation of ajouterRepas method
  }

  void visionnerHist() {
    // Implementation of visionnerHist method
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'diabType': diabType,
      'ratioInsulineGlucide': _ratioInsulineGlucide,
      'sensitiviteInsuline': _sensitiviteInsuline,
      'poids': _poids,
      'taille': _taille,
    });
    return map;
  }
}
