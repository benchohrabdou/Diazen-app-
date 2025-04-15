class Ingredient {
  double quantite100g;

  Ingredient({
    required this.quantite100g,
  });

  Map<String, dynamic> toJson() {
    return {
      'quantite100g': quantite100g,
    };
  }
}
