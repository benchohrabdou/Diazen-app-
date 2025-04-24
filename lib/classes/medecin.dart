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

  factory Medecin.fromJson(Map<String, dynamic> json) {
    return Medecin(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      dateNaissance: DateTime.parse(json['dateNaissance']),
      email: json['email'],
      tel: json['tel'],
      matriculePro: json['matriculePro'],
    );
  }
}
