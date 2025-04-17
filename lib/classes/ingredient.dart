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

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      quantite100g: json['quantite100g'],
    );
  }
}
