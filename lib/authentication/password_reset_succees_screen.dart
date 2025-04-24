import 'package:flutter/material.dart';
import 'package:diazen/authentication/new_password_screen.dart';

class PasswordResetSucceesScreen extends StatefulWidget {
  const PasswordResetSucceesScreen({super.key});

  @override
  State<PasswordResetSucceesScreen> createState() => _PasswordResetSucceesScreenState();
}

class _PasswordResetSucceesScreenState extends State<PasswordResetSucceesScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Password reset',
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your password have been succesfully reset.\nClick confirm to set a new password',
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  fontSize: 14,
                  color: Color(0xFF7B6F72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewPasswordScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7BF7),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 