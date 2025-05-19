import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(19.0),
        child: GNav(
          selectedIndex: selectedIndex,
          onTabChange: onTabChange,
          backgroundColor: Colors.white,
          rippleColor: const Color(0xFF4A7BF7),
          hoverColor: const Color(0xFF4A7BF7).withOpacity(0.1),
          gap: 8,
          activeColor: Colors.white,
          color: Colors.white,
          iconSize: 24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          duration: const Duration(milliseconds: 400),
          tabBackgroundColor: const Color(0xFF4A7BF7),
          tabs: [
            GButton(
              icon: Icons.circle,
              leading: Image.asset(
                'assets/icons/home icon.png',
                width: 24,
                height: 24,
              ),
              text: "Home",
              textStyle: const TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            GButton(
              icon: Icons.circle,
              leading: Image.asset(
                'assets/icons/restaurant.png',
                width: 24,
                height: 24,
              ),
              text: 'Meals',
              textStyle: const TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            GButton(
              icon: Icons.circle,
              iconColor: Colors.transparent,
              leading: Image.asset(
                'assets/icons/exercise.png',
                width: 24,
                height: 24,
              ),
              text: 'Activity',
              textStyle: const TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            GButton(
              icon: Icons.circle,
              iconColor: Colors.transparent,
              leading: Image.asset(
                'assets/icons/journal.png',
                width: 24,
                height: 24,
              ),
              textStyle: const TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              text: 'Track',
            ),
          ],
        ),
      ),
    );
  }
}
