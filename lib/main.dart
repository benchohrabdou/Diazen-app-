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
        primarySwatch: Colors.blue,
        fontFamily: 'SfProDisplay',
      ),
      home: const Loginpage(),
    );
  }
}
