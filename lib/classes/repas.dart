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

  void calcGlu() {
    // Implementation of calcGlu method
    // Example implementation:
    double totalGlucides = 0;
    for (var ingredient in ingredients) {
      totalGlucides += ingredient.quantite100g * quantite / 100;
    }
    print('Total glucides: $totalGlucides');
  }

  bool exist() {
    // Implementation of exist method
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'idRepas': idRepas,
      'nomRepas': nomRepas,
      'gluc100g': gluc100g,
      'quantite': quantite,
      'ingredients':
          ingredients.map((ingredient) => ingredient.toJson()).toList(),
    };
  }

  factory Repas.fromJson(Map<String, dynamic> json) {
    return Repas(
      idRepas: json['idRepas'],
      nomRepas: json['nomRepas'],
      gluc100g: json['gluc100g'],
      quantite: json['quantite'],
      ingredients: (json['ingredients'] as List)
          .map((item) => Ingredient.fromJson(item))
          .toList(),
    );
  }
}
