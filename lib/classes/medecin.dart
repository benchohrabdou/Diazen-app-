import 'personne.dart';

class Medecin extends Personne {
  String _matriculePro;

  Medecin({
    required String id,
    required String nom,
    required String prenom,
    required DateTime dateNaissance,
    required String email,
    required String tel,
    required String matriculePro,
  })  : _matriculePro = matriculePro,
        super(
          id: id,
          nom: nom,
          prenom: prenom,
          dateNaissance: dateNaissance,
          email: email,
          tel: tel,
        );

  void gererFacteurs() {
    // Implementation of gererFacteurs method
  }

  void consulterRapport() {
    // Implementation of consulterRapport method
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['matriculePro'] = _matriculePro;
    return map;
  }
}
