import 'ingredient.dart';

class Repas {
  String idRepas;
  String nomRepas;
  double gluc100g;
  double quantite;
  List<Ingredient> ingredients;

  Repas({
    required this.idRepas,
    required this.nomRepas,
    required this.gluc100g,
    required this.quantite,
    required this.ingredients,
  });

  void calcGlu() {}

  bool exist() {
    return true;
  }
}
