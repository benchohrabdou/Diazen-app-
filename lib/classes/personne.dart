class Personne {
  String id;
  String nom;
  String prenom;
  DateTime _dateNaissance;
  String _email;
  String _tel;

  Personne({
    required this.id,
    required this.nom,
    required this.prenom,
    required DateTime dateNaissance,
    required String email,
    required String tel,
  })  : _dateNaissance = dateNaissance,
        _email = email,
        _tel = tel;

  void sinscrire() {
    // Implementation of sinscrire method
  }

  void seConnecter() {
    // Implementation of seConnecter method
  }

  void gererCompte() {
    // Implementation of gererCompte method
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'dateNaissance': _dateNaissance.toIso8601String(),
      'email': _email,
      'tel': _tel,
    };
  }
}
