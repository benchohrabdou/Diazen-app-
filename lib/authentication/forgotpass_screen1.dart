import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:diazen/authentication/verificateemailscreen.dart'; // Removed as per new flow
// import 'package:mailer/mailer.dart'; // Removed as per new flow
// import 'package:mailer/smtp_server.dart'; // Removed as per new flow

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
  bool _isLoading = false;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Removed as per new flow

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

  // Removed custom OTP generation and sending logic
  /*
  String _generateOTP() {
    // Generate a 5-digit OTP
    return (10000 + (DateTime.now().millisecondsSinceEpoch % 90000)).toString();
  }

  Future<void> _sendOTP(String email, String otp) async {
    // Store OTP in Firestore with expiration
    await _firestore.collection('password_resets').doc(email).set({
      'otp': otp,
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt': FieldValue.serverTimestamp(),
    });

    // Create email message
    final message = Message()
      ..from = Address('abdoubench236@gmail.com')
      ..recipients.add(email)
      ..subject = 'Diazen Password Reset OTP'
      ..html = '''
        <h1>Password Reset OTP</h1>
        <p>Your OTP for password reset is: <strong>$otp</strong></p>
        <p>This OTP will expire in 5 minutes.</p>
        <p>If you didn't request this, please ignore this email.</p>
      ''';

    try {
      // Send email using Gmail SMTP
      final smtpServer = gmail('abdoubench236@gmail.com', 'nrpywckaskmofvcl');
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } catch (e) {
      print('Error sending email: $e');
      throw Exception('Failed to send OTP email');
    }
  }
  */

  void _onResetPressed() async {
    setState(() {
      _buttonScale = 0.95;
      _isLoading = true;
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
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Send password reset email using Firebase Authentication
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );

      // Optionally navigate the user to an info screen telling them to check email
      // For now, we'll stay on this screen.
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address';
          break;
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                  _borderColor =
                      hasFocus ? const Color(0xFF4A7BF7) : Colors.transparent;
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
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
                  onPressed: _isLoading ? null : _onResetPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTyping
                        ? const Color(0xFF4A7BF7)
                        : const Color(0xFF92A3FD),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isTyping ? 4 : 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
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
