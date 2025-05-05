import 'package:flutter/material.dart';

class AddPlateScreen extends StatefulWidget {
  const AddPlateScreen({super.key});

  @override
  State<AddPlateScreen> createState() => _AddPlateScreenState();
}

class _AddPlateScreenState extends State<AddPlateScreen> {
  final TextEditingController _platenamecontroller = TextEditingController();
  final TextEditingController _ingredientcontroler = TextEditingController();
  List<String> _ingredients = [];
  int _quantity = 1;

  void _addIngredient() {
    final text = _ingredientcontroler.text.trim();
    if (text.isNotEmpty && _quantity > 0) {
      setState(() {
        _ingredients.add('$text (x$_quantity)');
        _ingredientcontroler.clear();
        _quantity = 1;
      });

      // Afficher un SnackBar pour indiquer que l'ingrédient a été ajouté
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingredient added'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      // Si l'ingrédient est vide, ne pas ajouter
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid ingredient'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 25, left: 25),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // plate name textfield
                            Text(
                              'Create Your Plate',
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A7BF7),
                                fontSize: 25,
                              ),
                            )
                          ]),
                      const SizedBox(height: 20),
                      const Text('Plate name',
                          style: TextStyle(
                            fontFamily: 'SfProDisplay',
                            fontSize: 18,
                            color: Colors.black,
                          )),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _platenamecontroller,
                        decoration: InputDecoration(
                          hintText: 'enter plate name',
                          hintStyle: const TextStyle(
                            fontFamily: 'SfProDisplay',
                          ),
                          filled: true,
                          fillColor: Colors.grey[300],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text('Add ingredients:',
                          style: TextStyle(
                            fontFamily: 'SfProDisplay',
                            fontSize: 18,
                            color: Colors.black,
                          )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7BF7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // ingredient TextField
                            Expanded(
                              child: TextField(
                                controller: _ingredientcontroler,
                                decoration: InputDecoration(
                                  hintText: 'Add ingredient',
                                  hintStyle: TextStyle(
                                    fontFamily: 'SfProDisplay',
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[300],
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // minus
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  if (_quantity > 1) {
                                    _quantity--;
                                  }
                                });
                              },
                              icon: Image.asset(
                                'assets/icons/minus.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // quantité affichée (par exemple "1")
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // add ingredient
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                              icon: Image.asset(
                                'assets/icons/add.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Information about your plate :',
                        style:
                            TextStyle(fontFamily: 'SfProDisplay', fontSize: 18),
                      ),
                      Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Card(
                              color: const Color(0xFF4A7BF7),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Plate name
                                    Text(
                                      _platenamecontroller.text,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Ingredients list
                                    const Text(
                                      'Ingredients:',
                                      style: TextStyle(
                                        fontFamily: 'SfProDisplay',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ..._ingredients.map((ingredient) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check,
                                                  color: Color(0xFF4A7BF7),
                                                  size: 18),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  ingredient,
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          )),
                          const SizedBox(height:145),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final plateName = _platenamecontroller.text.trim();
                            if (plateName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please enter a plate name')),
                              );
                              return;
                            }
                            print(
                                'Ingredients: $_ingredients'); // Vérifiez ce qui est dans la liste
                            if (_ingredients.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please add at least one ingredient')),
                              );
                              return;
                            }
                            // Si tout est bon, vous pouvez soumettre l'info à l'API ou procéder à d'autres étapes.
                            // L'appel API vient ici.
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF4A7BF7), 
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add Plate',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'SfProDisplay'),
                          ),
                        ),
                      ),
                    ]))));
  }
}
