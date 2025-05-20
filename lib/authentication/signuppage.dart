import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diazen/authentication/medical_info_form.dart';
import 'package:diazen/authentication/social_auth_service.dart';
import 'package:diazen/authentication/loginpage.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  final _formsignupkey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final SocialAuthService _socialAuthService = SocialAuthService();
  bool _isLoading = false;
  bool _emailSent = false;
  Timer? _verificationTimer;
  String? _userId;
  String? _userEmail;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  bool agreePersonalData = true;

  @override
  void dispose() {
    _verificationTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formsignupkey.currentState!.validate() && agreePersonalData) {
      setState(() {
        _isLoading = true;
        _emailSent = false;
      });

      try {
        // Create user with email and password
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Send email verification
        await userCredential.user!.sendEmailVerification();

        setState(() {
          _isLoading = false;
          _emailSent = true;
          _userId = userCredential.user!.uid;
          _userEmail = userCredential.user!.email;
        });

        // Show verification email sent message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Verification email sent. Please check your inbox and verify your email.'),
            duration: Duration(seconds: 5),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An error occurred';

        switch (e.code) {
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account already exists for this email.';
            break;
          case 'invalid-email':
            errorMessage = 'Please enter a valid email address.';
            break;
          default:
            errorMessage = e.message ?? 'An error occurred';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isLoading = false;
        });
      }
    } else if (!agreePersonalData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the processing of personal data'),
        ),
      );
    }
  }

  void _checkEmailVerification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in again to refresh the user
      await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      User? user = _auth.currentUser;
      await user?.reload();

      if (user != null && user.emailVerified) {
        // Email is verified, proceed to medical info form
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MedicalInfoForm(
              userId: user.uid,
              email: user.email!,
              firstName: firstNameController.text,
              lastName: lastNameController.text,
            ),
          ),
        );
      } else {
        // Email is not verified
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email before proceeding.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Verification email resent. Please check your inbox.'),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        // Try to sign in again
        await _auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        user = _auth.currentUser;
        if (user != null) {
          await user.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Verification email resent. Please check your inbox.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF4A7BF7),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Get started",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontFamily: 'SfProDisplay',
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    height: 120,
                    width: 100,
                    child: Image.asset(
                      'assets/images/signupimge2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        )),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 60),
                        child: _emailSent
                            ? _buildVerificationUI()
                            : _buildSignUpForm(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _formsignupkey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextFormField(
            controller: firstNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
            decoration: InputDecoration(
                label: const Text('First Name'),
                hintText: 'Enter your first name',
                hintStyle: const TextStyle(
                  backgroundColor: Color.fromARGB(255, 187, 186, 186),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                )),
          ),
          const SizedBox(height: 25),
          TextFormField(
            controller: lastNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your family name';
              }
              return null;
            },
            decoration: InputDecoration(
                label: const Text('Family Name'),
                hintText: 'Enter your family name',
                hintStyle: const TextStyle(
                    backgroundColor: Color.fromARGB(255, 187, 186, 186),
                    color: Color.fromARGB(255, 108, 108, 108)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                )),
          ),
          const SizedBox(height: 25),
          TextFormField(
            controller: emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
            decoration: InputDecoration(
                label: const Text('Email'),
                hintText: 'Enter your email',
                hintStyle: const TextStyle(
                    backgroundColor: Color.fromARGB(255, 187, 186, 186),
                    color: Color.fromARGB(255, 108, 108, 108)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                )),
          ),
          const SizedBox(height: 25),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            decoration: InputDecoration(
                label: const Text('Password'),
                hintText: 'Enter password',
                hintStyle: const TextStyle(
                    backgroundColor: Color.fromARGB(255, 187, 186, 186),
                    color: Color.fromARGB(255, 108, 108, 108)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                )),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7BF7),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
                : const Text('Sign up',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'SfProDisplay',
                        fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  thickness: 0.7,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
                child: Text(
                  ' Or sign up with',
                  style: TextStyle(
                    color: Colors.black45,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  thickness: 0.7,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _socialAuthService.signInWithGoogle(context),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(10),
                  backgroundColor: Colors.white,
                ),
                child: Image.asset('assets/images/googlelogo.png', height: 30),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _socialAuthService.signInWithFacebook(context),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(10),
                  backgroundColor: Colors.white,
                ),
                child:
                    Image.asset('assets/images/facebooklogo.png', height: 30),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Apple sign in - not implemented yet
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(10),
                  backgroundColor: Colors.white,
                ),
                child: Image.asset('assets/images/appleicon.png', height: 30),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: Colors.black45),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Loginpage(),
                    ),
                  );
                },
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A7BF7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVerificationUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.email_outlined,
          size: 80,
          color: Color(0xFF4A7BF7),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verify your email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A7BF7),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a verification email to ${emailController.text}. Please check your inbox and verify your email address.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isLoading ? null : _checkEmailVerification,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A7BF7),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                  'I\'ve verified my email',
                  style: TextStyle(
                    fontFamily: 'SfProDisplay',
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _resendVerificationEmail,
          child: const Text(
            'Resend verification email',
            style: TextStyle(
              color: Color(0xFF4A7BF7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: const Text(
            'Go back',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
