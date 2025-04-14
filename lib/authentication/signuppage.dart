import 'package:diazen/authentication/loginpage.dart';
import 'package:flutter/material.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});
  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  final _formsignupkey = GlobalKey<FormState>();
  bool agreePersonalData = true;

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
                    fontWeight: FontWeight.bold
                  ),
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
                      )
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formsignupkey,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please enter your first name';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                    label: const Text('First Name'),
                                    hintText: 'Enter your first name',
                                    hintStyle: const TextStyle(
                                      backgroundColor:
                                          Color.fromARGB(255, 187, 186, 186),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )),
                              ),
                              const SizedBox(height: 25),
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please enter your family name';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                    label: const Text('Family Name'),
                                    hintText: 'Enter your family name',
                                    hintStyle: const TextStyle(
                                        backgroundColor:
                                            Color.fromARGB(255, 187, 186, 186),
                                        color: Color.fromARGB(255, 108, 108, 108)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )),
                              ),
                              const SizedBox(height: 25),
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please enter your email';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                    label: const Text('Email'),
                                    hintText: 'Enter your email',
                                    hintStyle: const TextStyle(
                                        backgroundColor:
                                            Color.fromARGB(255, 187, 186, 186),
                                        color: Color.fromARGB(255, 108, 108, 108)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )),
                              ),
                              const SizedBox(height: 25),
                              TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please enter password';
                                  }
                                  return null;
                                },
                                obscureText: true,
                                decoration: InputDecoration(
                                    label: const Text('Password'),
                                    hintText: 'Enter password',
                                    hintStyle: const TextStyle(
                                        backgroundColor:
                                            Color.fromARGB(255, 187, 186, 186),
                                        color: Color.fromARGB(255, 108, 108, 108)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )),
                              ),
                              const SizedBox(
                                height: 25,
                              ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formsignupkey.currentState!.validate() &&
                                        agreePersonalData) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Processing Data'),
                                        ),
                                      );
                                    } else if (!agreePersonalData) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please agree to the processing of personal data')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A7BF7),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Sign up',style: TextStyle(
                                    color:Colors.white,
                                    fontFamily: 'SfProDisplay',
                                    fontWeight: FontWeight.bold
                                  ),),
                                ),
                              const SizedBox(height:30),
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
                            const SizedBox(
                              height: 30.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: (){},
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(10),
                                      backgroundColor: Colors.white, 
                                    ),
                                  child: 
                                    Image.asset('assets/images/googlelogo.png',
                                    height:30),
                                  ),
                                  const SizedBox(width:10),
                                  ElevatedButton(
                                    onPressed: (){},
                                    style:  ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(10),
                                      backgroundColor: Colors.white,
                                    ),
                                    child: Image.asset('assets/images/facebooklogo.png',
                                    height:30)),
                                    const SizedBox(width: 10,),
                                    ElevatedButton(
                                    onPressed: (){},
                                    style:  ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(10),
                                      backgroundColor: Colors.white,
                                    ),
                                    child: Image.asset('assets/images/appleicon.png',
                                    height:30)),
                            ],
                          ),
                          const SizedBox(height:30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: Colors.black45,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (e) => const Loginpage(),
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
                          const SizedBox(height:20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height:50),
        ],
      ),
    );
  }
}
