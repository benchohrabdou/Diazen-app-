import 'personne.dart';

class Utilisateur extends Personne {
  int diabType;
  double _ratioInsulineGlucide;
  double _sensitiviteInsuline;
  double _poids;
  double _taille;

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

  void demanderCalcul() {}

  void saisirGlycemie() {}

  void ajouterRepas() {}

  void visionnerHist() {}
}
