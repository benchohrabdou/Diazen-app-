import 'package:diazen/authentication/auth_state_service.dart';
import 'package:diazen/authentication/loginpage.dart';
import 'package:diazen/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final authStateService = AuthStateService();
  final isLoggedIn = await authStateService.isUserLoggedIn();

  runApp(
    MaterialApp(
      title: 'Diazen',
      home: isLoggedIn
          ? HomeScreen()
          : Loginpage(), // ou votre écran de connexion
    ),
  );
}
