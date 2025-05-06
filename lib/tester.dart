import 'package:diazen/classes/activite.dart';
import 'package:diazen/classes/firestore_ops.dart';
import 'package:diazen/classes/ingredient.dart';
import 'package:diazen/classes/injection.dart';
import 'package:diazen/classes/medecin.dart';
import 'package:diazen/classes/utilisateur.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class TesterPage extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  TesterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Collections Tester'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                Utilisateur patient = Utilisateur(
                  id: 'user1',
                  nom: 'Doe',
                  prenom: 'John',
                  dateNaissance: DateTime.now(),
                  email: 'john.doe@example.com',
                  tel: '123456789',
                  diabType: 1,
                  ratioInsulineGlucide: 1.0,
                  sensitiviteInsuline: 1.0,
                  poids: 70.0,
                  taille: 175.0,
                );
                await _firestoreService.addPatient(patient);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Patient added')));
              },
              child: const Text('Create User Collection'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                Medecin doctor = Medecin(
                  id: 'doctor1',
                  nom: 'Smith',
                  prenom: 'Alice',
                  dateNaissance: DateTime(1980, 5, 15),
                  email: 'alice.smith@example.com',
                  tel: '987654321',
                  matriculePro: 'DOC12345',
                );
                await _firestoreService.addDoctor(doctor);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Doctor added')));
              },
              child: const Text('Create Doctors Collection'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                List<Map<String, dynamic>> ingredients = [
                  {'name': 'Rice', 'glucidesPer100g': 28.0},
                  {'name': 'Chicken', 'glucidesPer100g': 0.0},
                  {'name': 'Broccoli', 'glucidesPer100g': 7.0},
                ];
                // await _firestoreService.addMeal('meal1', 'Lunch', ingredients);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Meal added')));
              },
              child: const Text('Create Meals Collection'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                Injection injection = Injection(
                  tempsInject: TimeOfDay.now(),
                  glycemie: 120,
                  quantiteGlu: 15.5,
                );
                await _firestoreService.addInjection(injection, context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Injection added')));
              },
              child: const Text('Create Injections Collection'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                Activite activity = Activite(
                  nom: 'Running',
                  cal30mn: 300.0,
                  typeAct: 'Cardio',
                );
                await _firestoreService.addActivity(activity);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity added')));
              },
              child: const Text('Create Activities Collection'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                Ingredient ingredient = Ingredient(quantite100g: 30.0);
                await _firestoreService.addIngredient(ingredient);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingredient added')));
              },
              child: const Text('Create Ingredients Collection'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: TesterPage(),
  ));
}
