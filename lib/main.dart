import 'package:diazen/authentication/auth_state_service.dart';
import 'package:diazen/authentication/loginpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:diazen/screens/mainscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final authStateService = AuthStateService();
  final isLoggedIn = await authStateService.isUserLoggedIn();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diazen',
      home: isLoggedIn
          ? const MainScreen() // Changed from HomeScreen to MainScreen
          : const Loginpage(),
    ),
  );
}
