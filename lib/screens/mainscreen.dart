import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import 'home_screen.dart';
import 'add_plate_screen.dart';
import 'activity_screen.dart'; // Make sure this file defines 'ActivityScreen' class
import 'history_sreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AddPlateScreen(),
    const ActivityScreen(), // Make sure 'ActivityScreen' is defined in 'activity_screen.dart'
    const HistorySreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
