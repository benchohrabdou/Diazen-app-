import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diazen/authentication/verificateemailscreen.dart';

class ForgotpassScreen extends StatefulWidget {
  const ForgotpassScreen({super.key});

  @override
  State<ForgotpassScreen> createState() => _ForgotpassScreenState();
}

class _ForgotpassScreenState extends State<ForgotpassScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isTyping = false;
  Color _borderColor = Colors.transparent;
  double _borderWidth = 0;
  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isTyping = _emailController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onTextChanged);
    _emailController.dispose();
    super.dispose();
  }

  void _onResetPressed() async {
    setState(() {
      _buttonScale = 0.95;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _buttonScale = 1.0;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificateemailScreen(email: email),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Forget your password',
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enter your email to reset the password',
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your Email',
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _borderColor = hasFocus ? const Color(0xFF4A7BF7) : Colors.transparent;
                  _borderWidth = hasFocus ? 2 : 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _borderColor,
                    width: _borderWidth,
                  ),
                ),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontFamily: 'SfProDisplay',
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedScale(
              scale: _buttonScale,
              duration: const Duration(milliseconds: 100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: _onResetPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTyping ? const Color(0xFF4A7BF7) : const Color(0xFF92A3FD),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isTyping ? 4 : 2,
                  ),
                  child: const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
