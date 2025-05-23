import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:diazen/authentication/loginpage.dart';
import 'package:diazen/screens/mainscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diazen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4A7BF7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A7BF7),
          primary: const Color(0xFF4A7BF7),
        ),
        fontFamily: 'SfProDisplay',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Color(0xFF4A7BF7)),
          headlineLarge: TextStyle(color: Color(0xFF4A7BF7)),
          headlineMedium: TextStyle(color: Color(0xFF4A7BF7)),
        ),
      ),
      home: const Loginpage(),
    );
  }
}
