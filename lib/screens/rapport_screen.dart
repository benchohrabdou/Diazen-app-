import 'package:flutter/material.dart';

class RapportScreen extends StatefulWidget {
  final String patientId;  // Ajouter la variable patientId

  const RapportScreen({super.key, required this.patientId});  // rendre patientId obligatoire

  @override
  State<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends State<RapportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Report',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Color(0xFF4A7BF7),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Text(
            'Rapport du patient ID: ${widget.patientId}',
            style: const TextStyle(
              fontFamily: 'SfProDisplay',
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
