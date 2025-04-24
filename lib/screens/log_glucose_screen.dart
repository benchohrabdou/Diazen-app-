import 'package:flutter/material.dart';

class LogGlucoseScreen extends StatefulWidget {
  const LogGlucoseScreen({super.key});

  @override
  State<LogGlucoseScreen> createState() => _LogGlucoseScreenState();
}

class _LogGlucoseScreenState extends State<LogGlucoseScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Welcome to log glucose screen')),
    );
  }
}