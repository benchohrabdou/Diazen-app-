import 'package:diazen/authentication/forgotpass_screen1.dart';
import 'package:diazen/authentication/signuppage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diazen/screens/home_screen.dart';
import 'package:diazen/screens/mainscreen.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final _formsigninkey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberPassword = false;
  bool isObscure = true;
  Color emailBorderColor = Colors.grey;
  Color passwordBorderColor = Colors.grey;
  double emailBorderWidth = 1.0;
  double passwordBorderWidth = 1.0;


  @override
  void initState() {
    super.initState();
    _loadUserEmailPassword();
  }

//Load user email and password from shared preferences
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

  // Save user email and password to shared preferences
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

  void _signIn() async {
    if (_formsigninkey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        if (userCredential.user!.emailVerified) {
          _saveUserEmailPassword();
          // Navigate to the main app screen
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
      }
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontFamily: 'SfProDisplay',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      'assets/images/loginpageimage.png',
                      fit: BoxFit.contain,
                      width: 190,
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    )),
                child: SingleChildScrollView(
                  child: Form(
                      key: _formsigninkey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                    hintStyle: const TextStyle(),
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
                            const SizedBox(height: 20),
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
                      passwordBorderColor = const Color(0xFF4A7BF7);
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
                    hintStyle: const TextStyle(),
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
                        isObscure ? Icons.visibility_off : Icons.visibility,
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
                            const SizedBox(
                              height: 10.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                //Remember me
                                Row(
                                  children: [
                                    Checkbox(
                                      value: rememberPassword,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          rememberPassword = value!;
                                        });
                                      },
                                      activeColor: const Color(0xFF4A7BF7),
                                    ),
                                    const Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontFamily: 'SfProDisplay',
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                //Fogotpassword
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            ElevatedButton(
                              onPressed: () {
                                if (_formsigninkey.currentState!.validate()) {
                                  _signIn();
                                }
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MainScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A7BF7),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'SfProDisplay',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 25.0,
                            ),
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
                                      fontFamily: 'SfProDisplay',
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
                            const SizedBox(
                              height: 30.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(10),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: Image.asset(
                                      'assets/images/googlelogo.png',
                                      height: 30),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(10),
                                      backgroundColor: Colors.white,
                                    ),
                                    child: Image.asset(
                                        'assets/images/facebooklogo.png',
                                        height: 30)),
                                const SizedBox(
                                  width: 10,
                                ),
                                ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(10),
                                      backgroundColor: Colors.white,
                                    ),
                                    child: Image.asset(
                                        'assets/images/appleicon.png',
                                        height: 30)),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Don\'t have an account? ',
                                  style: TextStyle(
                                    color: Colors.black45,
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ),
              )),
        ],
      ),
    );
  }
}
