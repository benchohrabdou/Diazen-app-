import 'package:diazen/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:diazen/authentication/loginpage.dart';
import 'package:diazen/screens/mainscreen.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter(); // Ajoute cette ligne pour initialiser Hive

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _primaryColor = Color(0xFF4A7BF7);
  static const _textColor = Colors.black87;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diazen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          primary: _primaryColor,
        ),
        fontFamily: 'SfProDisplay',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _textColor),
          bodyMedium: TextStyle(color: _textColor),
          titleLarge: TextStyle(color: _primaryColor),
          headlineLarge: TextStyle(color: _primaryColor),
          headlineMedium: TextStyle(color: _primaryColor),
        ),
        useMaterial3: true,
      ),
      home: const Loginpage(),
    );
  }
}