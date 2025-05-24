import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diazen/authentication/medical_info_form.dart';
import 'package:diazen/authentication/social_auth_service.dart';
import 'package:diazen/authentication/loginpage.dart';
import 'package:diazen/screens/mainscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool isObscure = true;
   // Ajoutez ces variables pour gérer les bordures
  Color passwordBorderColor = Colors.grey;
  double passwordBorderWidth = 1.0;
  Color emailBorderColor = Colors.grey;
  double emailBorderWidth = 1.0;
  Color firstNameBorderColor = Colors.grey;
  double firstNameBorderWidth = 1.0;
  Color lastNameBorderColor = Colors.grey;
  double lastNameBorderWidth = 1.0;

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
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        await userCredential.user!.sendEmailVerification();

        setState(() {
          _isLoading = false;
          _emailSent = true;
          _userId = userCredential.user!.uid;
          _userEmail = userCredential.user!.email;
        });

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
      await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      User? user = _auth.currentUser;
      await user?.reload();

      if (user != null && user.emailVerified) {
        if (!mounted) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MedicalInfoForm(
              userId: user.uid,
              email: user.email!,
              firstName: firstNameController.text,
              lastName: lastNameController.text,
              onComplete: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
            ),
          ),
        );
      } else {
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
      body: SafeArea(
        child: Stack(
          children: [
            // White container with form
            Positioned.fill(
              top: 120, // Adjust this value to control overlap
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: _emailSent
                      ? _buildVerificationUI()
                      : _buildSignUpForm(),
                ),
              ),
            ),
            
            // Title and image section
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    "Get started",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontFamily: 'SfProDisplay',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(left: 0),
                      height: 100, // Image height
                      child: Image.asset(
                        'assets/images/signupimge2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            onTap: () {
              setState(() {
                firstNameBorderColor = const Color(0xFF4A7BF7);
                firstNameBorderWidth = 2.0;

                // Réinitialiser les autres bordures
                emailBorderColor = Colors.grey;
                emailBorderWidth = 1.0;
                passwordBorderColor = Colors.grey;
                passwordBorderWidth = 1.0;
                lastNameBorderColor = Colors.grey;
                lastNameBorderWidth = 1.0;
              });
            },
            onFieldSubmitted: (_) {
              setState(() {
                firstNameBorderColor = Colors.grey;
                firstNameBorderWidth = 1.0;
              });
            },
            decoration: InputDecoration(
              labelText: 'First Name',
              hintText: 'Enter your first name',
              hintStyle: const TextStyle(
                color: Color(0xFF6C6C6C),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: firstNameBorderColor,
                  width: firstNameBorderWidth,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF4A7BF7),
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),

                    const SizedBox(height: 20),
                    TextFormField(
            controller: lastNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your family name';
              }
              return null;
            },
            onTap: () {
              setState(() {
                lastNameBorderColor = const Color(0xFF4A7BF7);
                lastNameBorderWidth = 2.0;
                // Réinitialiser les autres bordures
                emailBorderColor = Colors.grey;
                emailBorderWidth = 1.0;
                passwordBorderColor = Colors.grey;
                passwordBorderWidth = 1.0;
                firstNameBorderColor = Colors.grey;
                firstNameBorderWidth = 1.0;
              });
            },
            onFieldSubmitted: (_) {
              setState(() {
                lastNameBorderColor = Colors.grey;
                lastNameBorderWidth = 1.0;
              });
            },
            decoration: InputDecoration(
              labelText: 'Family Name',
              hintText: 'Enter your family name',
              hintStyle: const TextStyle(
                color: Color.fromARGB(255, 108, 108, 108),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: lastNameBorderColor,
                  width: lastNameBorderWidth,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF4A7BF7),
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
                    const SizedBox(height: 20),
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
            onTap: () {
              setState(() {
                emailBorderColor = const Color(0xFF4A7BF7);
                emailBorderWidth = 2.0;
                // Réinitialiser les autres bordures
                passwordBorderColor = Colors.grey;
                passwordBorderWidth = 1.0;
                firstNameBorderColor = Colors.grey;
                firstNameBorderWidth = 1.0;
                lastNameBorderColor = Colors.grey;
                lastNameBorderWidth = 1.0;
              });
            },
            onFieldSubmitted: (_) {
              setState(() {
                emailBorderColor = Colors.grey;
                emailBorderWidth = 1.0;
              });
            },
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              hintStyle: const TextStyle(
                color: Color.fromARGB(255, 108, 108, 108),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: emailBorderColor,
                  width: emailBorderWidth,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF4A7BF7),
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
                    const SizedBox(height: 20),
                    TextFormField(
            controller: passwordController,
            obscureText: isObscure,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onTap: () {
              setState(() {
                passwordBorderColor = const Color(0xFF4A7BF7);
                passwordBorderWidth = 2.0;
                // Réinitialiser les autres bordures si nécessaire
                emailBorderColor = Colors.grey;
                emailBorderWidth = 1.0;
                firstNameBorderColor = Colors.grey;
                firstNameBorderWidth = 1.0;
                lastNameBorderColor = Colors.grey;
                lastNameBorderWidth = 1.0;
              });
            },
            onFieldSubmitted: (_) {
              setState(() {
                passwordBorderColor = Colors.grey;
                passwordBorderWidth = 1.0;
              });
            },
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter password',
              hintStyle: const TextStyle(
                color: Color.fromARGB(255, 108, 108, 108),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: passwordBorderColor,
                  width: passwordBorderWidth,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF4A7BF7),
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    isObscure = !isObscure;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                : const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'SfProDisplay',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
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
              /*ElevatedButton(
                onPressed: () {
                  // Apple sign in
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(10),
                  backgroundColor: Colors.white,
                ),
                child: Image.asset('assets/images/appleicon.png', height: 30),
              ),*/
            ],
          ),
          const SizedBox(height: 20),
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