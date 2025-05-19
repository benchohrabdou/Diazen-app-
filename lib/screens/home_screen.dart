import 'package:flutter/material.dart';
import 'package:diazen/screens/calculate_dose_screen.dart';
import 'package:diazen/screens/log_glucose_screen.dart';
import 'package:diazen/screens/settings_screen.dart';
import 'package:diazen/screens/custom_card.dart';
import 'package:diazen/screens/add_plate_screen.dart';
import 'package:diazen/screens/history_sreen.dart';
import 'package:diazen/classes/firestore_ops.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _userName = '';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check shared preferences first for cached name
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('userName');

      if (cachedName != null && cachedName.isNotEmpty) {
        setState(() {
          _userName = cachedName;
          _isLoading = false;
        });
      }

      // Still fetch from Firestore to update cache
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc =
            await _firestoreService.getDocument('users', currentUser.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final name = userData['prenom'] ?? '';

          // Update cache
          await prefs.setString('userName', name);

          setState(() {
            _userName = name;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'User data not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Hello,",
                          style: TextStyle(
                              fontFamily: 'SfProDisplay',
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 120,
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4A7BF7),
                                  ),
                                ),
                              )
                            : Text(
                                _userName.isEmpty ? "User" : _userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SfProDisplay',
                                    color: Color(0xFF4A7BF7),
                                    fontSize: 24),
                              ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Color(0xFF4A7BF7),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Last operations container
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A7BF7), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Last Operations',
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildOperationItem(
                                  icon: Icons.monitor_heart,
                                  label: 'Glucose',
                                  value: '120 mg/dL',
                                ),
                                _buildOperationItem(
                                  icon: Icons.medical_services,
                                  label: 'Injection',
                                  value: '8 units',
                                ),
                                _buildOperationItem(
                                  icon: Icons.restaurant,
                                  label: 'Last Meal',
                                  value: '2h ago',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    CustomCard(
                      text: 'Calculate dose insulin',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CalculateDoseScreen()),
                        );
                      },
                    ),
                    CustomCard(
                      text: 'Log glucose',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LogGlucoseScreen()),
                        );
                      },
                    ),
                    CustomCard(
                      text: 'Add meal',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddPlateScreen()),
                        );
                      },
                    ),
                    CustomCard(
                      text: 'Check history',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HistorySreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF4A7BF7),
                        child: Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your AI Assistant",
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A7BF7),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "How can I help you today?",
                              style: TextStyle(
                                fontFamily: 'SfProDisplay',
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF4A7BF7),
                        ),
                        onPressed: () {
                          // TODO: Add navigation to assistant screen
                        },
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'SfProDisplay',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
