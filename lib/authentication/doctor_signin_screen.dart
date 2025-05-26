import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diazen/screens/doctor_home_screen.dart';

class DoctorSigninScreen extends StatefulWidget {
  const DoctorSigninScreen({Key? key}) : super(key: key);

  @override
  State<DoctorSigninScreen> createState() => _DoctorSigninScreenState();
}

class _DoctorSigninScreenState extends State<DoctorSigninScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyDoctor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final doctorId = _idController.text.trim();

      final query = await FirebaseFirestore.instance
          .collection('doctors')
          .where('id', isEqualTo: doctorId)
          .get();
      if (!mounted) return;
      if (query.docs.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = "Doctor ID not found.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotIdDialog() async {
    final TextEditingController matriculeController = TextEditingController();
    String? error;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Forgot ID?',
                style: TextStyle(
                  fontFamily: 'SfProDisplay',
                  color: Color(0xFF4A7BF7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: matriculeController,
                    decoration: const InputDecoration(
                      labelText: 'Medical License Number',
                      labelStyle: TextStyle(fontFamily: 'SfProDisplay'),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(
                          color: Colors.red, fontFamily: 'SfProDisplay'),
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      color: Colors.grey,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final matricule = matriculeController.text.trim();
                    if (matricule.isEmpty) {
                      setState(() =>
                          error = "Please enter your Medical License Number.");
                      return;
                    }
                    final query = await FirebaseFirestore.instance
                        .collection('doctors')
                        .where('matriculePro', isEqualTo: matricule)
                        .get();

                    if (query.docs.isNotEmpty) {
                      final docId = query.docs.first.id;
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text(
                            'Your Doctor ID',
                            style: TextStyle(
                              fontFamily: 'SfProDisplay',
                              color: Color(0xFF4A7BF7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Your ID is: $docId',
                            style: const TextStyle(fontFamily: 'SfProDisplay'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'OK',
                                style: TextStyle(fontFamily: 'SfProDisplay'),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      setState(() => error =
                          "No doctor found with this Medical License Number.");
                    }
                  },
                  child: const Text(
                    'Find ID',
                    style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      color: Color(0xFF4A7BF7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Doctor Login',
                    style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A7BF7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please enter your doctor ID that was sent to your email',
                    style: TextStyle(
                      fontFamily: 'SfProDisplay',
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: 'Doctor ID',
                      hintText: 'Enter your doctor ID',
                      prefixIcon:
                          const Icon(Icons.badge, color: Color(0xFF4A7BF7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF4A7BF7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xFF4A7BF7), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your doctor ID';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'SfProDisplay',
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotIdDialog,
                      child: const Text(
                        "Forgot ID?",
                        style: TextStyle(
                          fontFamily: 'SfProDisplay',
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyDoctor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A7BF7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
