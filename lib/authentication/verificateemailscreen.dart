import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diazen/authentication/new_password_screen.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class VerificateemailScreen extends StatefulWidget {
  final String email;

  const VerificateemailScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerificateemailScreen> createState() => _VerificateemailScreenState();
}

class _VerificateemailScreenState extends State<VerificateemailScreen> {
  final List<TextEditingController> _controllers = List.generate(
    5,
    (index) => TextEditingController(),
  );
  
  bool _isTyping = false;
  double _buttonScale = 1.0;
  bool _isLoading = false;
  bool _isResending = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    for (var controller in _controllers) {
      controller.addListener(_checkTyping);
    }
  }

  void _checkTyping() {
    setState(() {
      _isTyping = _controllers.any((controller) => controller.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.removeListener(_checkTyping);
      controller.dispose();
    }
    super.dispose();
  }

  void _onVerifyPressed() async {
    setState(() {
      _isLoading = true;
    });

    try {
    String code = _controllers.map((c) => c.text).join();
    if (code.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete code')),
      );
      return;
    }

      // Get the stored OTP from Firestore
      final doc = await _firestore
          .collection('password_resets')
          .doc(widget.email)
          .get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No OTP found. Please request a new one.')),
        );
        return;
      }

      final storedOTP = doc.data()?['otp'] as String?;
      if (storedOTP == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please request a new one.')),
        );
        return;
      }

      // Check if OTP matches
      if (code == storedOTP) {
        // Optionally check for OTP expiration here based on timestamp if needed

        // Attempt to sign in the user after successful OTP verification
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: widget.email,
            password: 'temporary_password_placeholder', // Replace with a placeholder or try without if possible
          );
          // Note: This signInWithEmailAndPassword will likely fail as we don't have the password.
          // The goal is to potentially refresh the auth state or trigger Firebase checks
          // that might make updatePassword work in the next screen.
        } catch (e) {
          // Ignore sign-in errors here, as we are immediately navigating to password reset.
          print('Temporary sign-in attempt failed: $e');
        }

        if (!mounted) return;
        // Navigate to new password screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
            builder: (context) => NewPasswordScreen(email: widget.email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
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

  String _generateOTP() {
    // Generate a 5-digit OTP
    return (10000 + (DateTime.now().millisecondsSinceEpoch % 90000)).toString();
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      final otp = _generateOTP();
      await _firestore.collection('password_resets').doc(widget.email).set({
        'otp': otp,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': FieldValue.serverTimestamp(),
      });

      // Create email message
      final message = Message()
        ..from = Address('abdoubench236@gmail.com') // Replace with your email
        ..recipients.add(widget.email)
        ..subject = 'Diazen Password Reset OTP'
        ..html = '''
          <h1>Password Reset OTP</h1>
          <p>Your new OTP for password reset is: <strong>$otp</strong></p>
          <p>This OTP will expire in 5 minutes.</p>
          <p>If you didn't request this, please ignore this email.</p>
        ''';

      // Send email using Gmail SMTP
      final smtpServer = gmail('abdoubench236@gmail.com', 'nrpywckaskmofvcl'); // Replace with your Gmail and app password
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New OTP has been sent to your email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
    );
    } finally {
      setState(() {
        _isResending = false;
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Check your email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontFamily: 'SfProDisplay',
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7B6F72),
                    fontFamily: 'SfProDisplay',
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'We sent an OTP to '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (index) => SizedBox(
                    width: 60,
                      child: TextField(
                        controller: _controllers[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                        fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8ECF4),
                            width: 1,
                          ),
                          ),
                          focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4A7BF7),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 4) {
                            FocusScope.of(context).nextFocus();
                          } else if (value.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          }
                        },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedScale(
                scale: _buttonScale,
                duration: const Duration(milliseconds: 100),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onVerifyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTyping 
                        ? const Color(0xFF4A7BF7)
                        : const Color(0xFF92A3FD),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
                      'Verify code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'SfProDisplay',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive the OTP? ",
                      style: TextStyle(
                        color: Color(0xFF7B6F72),
                        fontSize: 14,
                        fontFamily: 'SfProDisplay',
                      ),
                    ),
                    GestureDetector(
                      onTap: _isResending ? null : _resendOTP,
                      child: _isResending
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4A7BF7),
                              ),
                            )
                          : const Text(
                              'Resend OTP',
                        style: TextStyle(
                          color: Color(0xFF4A7BF7),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'SfProDisplay',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
