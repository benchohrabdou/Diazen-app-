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

  void sinscrire() {}

  void seConnecter() {}

  void gererCompte() {}
}
