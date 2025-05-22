import 'package:flutter/material.dart';

class DoseResultScreen extends StatelessWidget {
  final double dose;

  const DoseResultScreen({super.key, required this.dose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Dose Result',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF4A7BF7),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 32, left: 24, right: 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: Card(
            color: const Color(0xFF4A7BF7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Recommended Insulin Dose',
                    style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${dose.toStringAsFixed(1)} U',
                    style: const TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
