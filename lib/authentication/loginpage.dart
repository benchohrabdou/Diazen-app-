import 'package:diazen/authentication/forgotpass_screen1.dart';
import 'package:diazen/authentication/signuppage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diazen/screens/mainscreen.dart';
import 'package:diazen/authentication/social_auth_service.dart';
import 'package:diazen/authentication/doctor_signin_screen.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final _formsigninkey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final SocialAuthService _socialAuthService = SocialAuthService();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberPassword = false;
  bool isObscure = true;
  Color emailBorderColor = Colors.grey;
  Color passwordBorderColor = Colors.grey;
  double emailBorderWidth = 1.0;
  double passwordBorderWidth = 1.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmailPassword();
    _checkIfUserIsLoggedIn();
  }

  void _loadUserEmailPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberPassword = prefs.getBool('rememberPassword') ?? false;
      if (rememberPassword) {
        emailController.text = prefs.getString('email') ?? '';
        passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  void _saveUserEmailPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberPassword) {
      await prefs.setBool('rememberPassword', true);
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
    } else {
      await prefs.setBool('rememberPassword', false);
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  void _checkIfUserIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn');
    if (isLoggedIn != null && isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  void _signIn() async {
    if (_formsigninkey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        if (userCredential.user!.emailVerified) {
          _saveUserEmailPassword();

          // Mark user as logged in
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          // Navigate to the main app screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your email'),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Error occurred'),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height to calculate proportions
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF4A7BF7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Top section with welcome text and image - fixed height
                SizedBox(
                  height: screenHeight * 0.25, // Fixed proportion of screen
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontFamily: 'SfProDisplay',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            'assets/images/loginpageimage.png',
                            fit: BoxFit.contain,
                            width: 180,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form section - takes remaining space
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                        child: Form(
                          key: _formsigninkey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Email field
                              TextFormField(
                                controller: emailController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please enter your email';
                                  }
                                  return null;
                                },
                                onTap: () {
                                  setState(() {
                                    emailBorderColor = const Color(0xFF4A7BF7);
                                    emailBorderWidth = 2.0;
                                    passwordBorderColor = Colors.grey;
                                    passwordBorderWidth = 1.0;
                                  });
                                },
                                onFieldSubmitted: (_) {
                                  setState(() {
                                    emailBorderColor = Colors.grey;
                                    emailBorderWidth = 1.0;
                                  });
                                },
                                decoration: InputDecoration(
                                  label: const Text('email'),
                                  hintText: 'Enter your email',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: emailBorderColor,
                                      width: emailBorderWidth,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4A7BF7),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Password field
                              TextFormField(
                                controller: passwordController,
                                obscureText: isObscure,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please enter your password';
                                  }
                                  return null;
                                },
                                onTap: () {
                                  setState(() {
                                    passwordBorderColor =
                                        const Color(0xFF4A7BF7);
                                    passwordBorderWidth = 2.0;
                                    emailBorderColor = Colors.grey;
                                    emailBorderWidth = 1.0;
                                  });
                                },
                                onFieldSubmitted: (_) {
                                  setState(() {
                                    passwordBorderColor = Colors.grey;
                                    passwordBorderWidth = 1.0;
                                  });
                                },
                                decoration: InputDecoration(
                                  label: const Text('password'),
                                  hintText: 'Enter your password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: passwordBorderColor,
                                      width: passwordBorderWidth,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4A7BF7),
                                      width: 2.0,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isObscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isObscure = !isObscure;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Remember me and Forgot password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Checkbox(
                                          value: rememberPassword,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              rememberPassword = value!;
                                            });
                                          },
                                          activeColor: const Color(0xFF4A7BF7),
                                        ),
                                      ),
                                      const Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontFamily: 'SfProDisplay',
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (e) =>
                                              const ForgotpassScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Forget password?',
                                      style: TextStyle(
                                        fontFamily: 'SfProDisplay',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // Sign in button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
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
                                        'Sign in',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'SfProDisplay',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 15),

                              // Sign in as a doctor button
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DoctorSigninScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Sign in as a doctor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'SfProDisplay',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Or sign up with divider
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
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      'Or sign up with',
                                      style: TextStyle(
                                        fontFamily: 'SfProDisplay',
                                        color: Colors.black45,
                                        fontSize: 14,
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
                              const SizedBox(height: 15),

                              // Social login buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialButton(
                                    'assets/images/googlelogo.png',
                                    () => _socialAuthService
                                        .signInWithGoogle(context),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildSocialButton(
                                    'assets/images/facebooklogo.png',
                                    () => _socialAuthService
                                        .signInWithFacebook(context),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildSocialButton(
                                    'assets/images/appleicon.png',
                                    () {/* Apple sign in */},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // Don't have an account
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Don\'t have an account? ',
                                    style: TextStyle(
                                      color: Colors.black45,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (e) => const Signuppage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Sign up',
                                      style: TextStyle(
                                        fontFamily: 'SfProDisplay',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A7BF7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper method to create social login buttons
  Widget _buildSocialButton(String imagePath, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(8),
        backgroundColor: Colors.white,
      ),
      child: Image.asset(imagePath, height: 28),
    );
  }
}
