import 'package:flutter/material.dart';

class CalculateDoseScreen extends StatefulWidget {
  const CalculateDoseScreen({super.key});

  @override
  State<CalculateDoseScreen> createState() => _CalculateDoseScreenState();
}

class _CalculateDoseScreenState extends State<CalculateDoseScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('calculate dose screen'),),
    );
  }
}