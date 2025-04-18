import 'personne.dart';

class Utilisateur extends Personne {
  int diabType;
  double _ratioInsulineGlucide;
  double _sensitiviteInsuline;
  double _poids;
  double _taille;

  double glycemie = 0.0; // Attribute to store glycemia value

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

  Map<String, dynamic> demanderCalcul({
    required double glucides,
    required int quantiteRepas,
    required double caloriesBurned,
    required double glycemieCible,
  }) {
    return {
      'glycemie': glycemie,
      'glucides': glucides,
      'quantiteRepas': quantiteRepas,
      'caloriesBurned': caloriesBurned,
      'glycemieCible': glycemieCible,
      'ratioInsulineGlucide': _ratioInsulineGlucide,
      'sensitiviteInsuline': _sensitiviteInsuline,
    };
  }

  double saisirGlycemie(double newGlycemie) {
    glycemie = newGlycemie;
    print('Glycemie updated to $glycemie mg/dL');
    return glycemie;
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

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      dateNaissance: DateTime.parse(json['dateNaissance']),
      email: json['email'],
      tel: json['tel'],
      diabType: json['diabType'],
      ratioInsulineGlucide: json['ratioInsulineGlucide'],
      sensitiviteInsuline: json['sensitiviteInsuline'],
      poids: json['poids'],
      taille: json['taille'],
    );
  }
}
