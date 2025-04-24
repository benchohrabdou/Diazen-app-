import 'package:flutter/material.dart';

class HistorySreen extends StatefulWidget {
  const HistorySreen({super.key});

  @override
  State<HistorySreen> createState() => _HistorySreenState();
}

class _HistorySreenState extends State<HistorySreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('History page')),
    );
  }
}