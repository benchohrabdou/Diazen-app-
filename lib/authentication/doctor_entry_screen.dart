import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diazen/screens/doctor_home_screen.dart';
import 'doctor_signin_screen.dart';

class DoctorEntryScreen extends StatelessWidget {
  const DoctorEntryScreen({super.key});

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDoctorLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!
            ? const DoctorHomeScreen()
            : const DoctorSigninScreen();
      },
    );
  }
}
