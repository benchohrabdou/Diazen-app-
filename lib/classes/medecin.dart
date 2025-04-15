import 'personne.dart';

class Medecin extends Personne {
  String _matriculePro;

  Medecin({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.dateNaissance,
    required super.email,
    required super.tel,
    required String matriculePro,
  }) : _matriculePro = matriculePro;

  void gererFacteurs() {}

  void consulterRapport() {}
}
