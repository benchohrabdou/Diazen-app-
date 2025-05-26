import 'package:diazen/authentication/loginpage.dart';
import 'package:diazen/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:diazen/screens/calculate_dose_screen.dart';
import 'package:diazen/screens/log_glucose_screen.dart';
import 'package:diazen/screens/settings_screen.dart';
import 'package:diazen/screens/custom_card.dart';
import 'package:diazen/screens/add_plate_screen.dart';
import 'package:diazen/screens/saved_meals_screen.dart';
import 'package:diazen/screens/history_screen.dart';
import 'package:diazen/screens/activity_screen.dart';
import 'package:diazen/classes/firestore_ops.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = '';
  bool _isLoading = true;
  String _errorMessage = '';

  // Last operations
  String _lastGlucose = 'N/A';
  String _lastInjection = 'N/A';
  String _lastMeal = 'N/A';
  String _lastMealTime = 'N/A';

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
        });
      }

      // Still fetch from Firestore to update cache
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc =
            await _firestoreService.getDocument('users', currentUser.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          print('User document found: ' + userData.toString());
          final name = userData['prenom'] ?? '';

          // Update cache
          await prefs.setString('userName', name);

          // Get last operations
          final lastOperations =
              userData['lastOperations'] as Map<String, dynamic>? ?? {};
          print('Last operations data: ' + lastOperations.toString());

          // Get glucose values from both injection and glucose log
          DateTime? lastGlucoseTime;
          String? lastGlucoseValue;

          // Check glucose log
          if (lastOperations.containsKey('glucose')) {
            final glucoseData =
                lastOperations['glucose'] as Map<String, dynamic>? ?? {};
            if (glucoseData.containsKey('timestamp')) {
              try {
                final timestamp = DateTime.parse(glucoseData['timestamp']);
                lastGlucoseTime = timestamp;
                lastGlucoseValue = glucoseData['value']?.toString();
                print(
                    'Found glucose log: $lastGlucoseValue at $lastGlucoseTime');
              } catch (e) {
                print('Error parsing glucose timestamp: $e');
              }
            }
          }

          // Check injection glucose
          if (lastOperations.containsKey('injection')) {
            final injectionData =
                lastOperations['injection'] as Map<String, dynamic>? ?? {};
            if (injectionData.containsKey('timestamp')) {
              try {
                final timestamp = DateTime.parse(injectionData['timestamp']);
                // Only update if this is more recent than the glucose log
                if (lastGlucoseTime == null ||
                    timestamp.isAfter(lastGlucoseTime)) {
                  lastGlucoseTime = timestamp;
                  lastGlucoseValue = injectionData['glucoseValue']?.toString();
                  print(
                      'Found injection glucose: $lastGlucoseValue at $lastGlucoseTime');
                }
              } catch (e) {
                print('Error parsing injection timestamp: $e');
              }
            }
          }

          // Set the most recent glucose value
          _lastGlucose = lastGlucoseValue ?? 'N/A';
          print('Final glucose value to display: $_lastGlucose');

          // Get injection
          if (lastOperations.containsKey('injection')) {
            final injectionData =
                lastOperations['injection'] as Map<String, dynamic>? ?? {};
            _lastInjection = injectionData['value']?.toString() ?? 'N/A';
            print('Loaded last injection: $_lastInjection');
          }

          // Get meal
          if (lastOperations.containsKey('meal')) {
            final mealData =
                lastOperations['meal'] as Map<String, dynamic>? ?? {};
            _lastMeal = mealData['value']?.toString() ?? 'N/A';
            print('Loaded last meal: $_lastMeal');

            // Format time
            if (mealData.containsKey('timestamp')) {
              try {
                final timestamp = DateTime.parse(mealData['timestamp']);
                final now = DateTime.now();
                final difference = now.difference(timestamp);

                if (difference.inMinutes < 60) {
                  _lastMealTime = '${difference.inMinutes}m ago';
                } else if (difference.inHours < 24) {
                  _lastMealTime = '${difference.inHours}h ago';
                } else {
                  _lastMealTime = '${difference.inDays}d ago';
                }
                print('Loaded last meal time: $_lastMealTime');
              } catch (e) {
                print('Error parsing last meal timestamp: $e');
                _lastMealTime = 'Invalid Time';
              }
            } else {
              _lastMealTime = 'N/A';
              print('Last meal timestamp missing.');
            }
          } else {
            print('Last meal data missing.');
            _lastMeal = 'N/A';
            _lastMealTime = 'N/A';
          }

          setState(() {
            _userName = name;
            print('Home screen state updated with user name.');
          });
        } else {
          setState(() {
            _errorMessage = 'User data not found';
            print('User data document not found.');
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No user logged in';
          print('No user logged in.');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        print('Error loading user data: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
        print('Finished loading user data. isLoading set to false.');
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    // Clear the isLoggedIn flag from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const Loginpage()),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFF4A7BF7),
            fontFamily: 'SfProDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Do you really want to log out?',
          style: TextStyle(
            fontFamily: 'SfProDisplay',
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: 'SfProDisplay',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut();
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFF4A7BF7),
                fontFamily: 'SfProDisplay',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicalDisclaimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange[700]), // Warning icon
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Important Medical Information',
                style: TextStyle(
                  color: Colors.orange[700], // Warning color
                  fontFamily: 'SfProDisplay',
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow
                      .ellipsis, // Prevent overflow with ellipsis if needed
                ),
                maxLines: 2, // Allow title to wrap if necessary
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'This application is a tool to help you manage your diabetes, but it is NOT a substitute for professional medical advice, diagnosis, or treatment.',
                style: TextStyle(fontFamily: 'SfProDisplay', fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                'Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
                style: TextStyle(fontFamily: 'SfProDisplay', fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                'Never disregard professional medical advice or delay in seeking it because of something you have read or calculated using this app.',
                style: TextStyle(fontFamily: 'SfProDisplay', fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                'Information provided by this app is for informational purposes only and is not intended to replace consultation with a qualified healthcare professional.',
                style: TextStyle(fontFamily: 'SfProDisplay', fontSize: 14),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF4A7BF7),
                fontFamily: 'SfProDisplay',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
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
                    // Settings Button
                    IconButton(
                      icon:
                          const Icon(Icons.settings, color: Color(0xFF4A7BF7)),
                      onPressed: () {
                        // Show a simple menu or directly the disclaimer for testing
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20.0)),
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          builder: (BuildContext context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  // Optional: Add a drag handle
                                  Container(
                                    height: 4,
                                    width: 40,
                                    margin: const EdgeInsets.only(
                                        top: 10, bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.warning_amber_rounded,
                                        color: Colors.orange[700]),
                                    title: const Text('Medical Disclaimer',
                                        style: TextStyle(
                                            fontFamily: 'SfProDisplay')),
                                    onTap: () {
                                      Navigator.pop(
                                          context); // Close the bottom sheet
                                      _showMedicalDisclaimer(); // Show the disclaimer dialog
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.person,
                                        color: Color(0xFF4A7BF7)),
                                    title: const Text('Edit Personal Data',
                                        style: TextStyle(
                                            fontFamily: 'SfProDisplay')),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const EditProfileScreen()),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.logout,
                                        color: Colors.redAccent),
                                    title: const Text('Logout',
                                        style: TextStyle(
                                            fontFamily: 'SfProDisplay')),
                                    onTap: () {
                                      Navigator.pop(
                                          context); // Close the bottom sheet
                                      _showLogoutDialog(); // Show the logout dialog
                                    },
                                  ),
                                  // Add other settings options here later
                                ],
                              ),
                            );
                          },
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
                        color: const Color(0xFF4A7BF7),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.25),
                              Colors.black.withOpacity(0.1),
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
                                  value: _lastGlucose,
                                ),
                                _buildOperationItem(
                                  icon: Icons.medical_services,
                                  label: 'Injection',
                                  value: _lastInjection,
                                ),
                                _buildOperationItem(
                                  icon: Icons.restaurant,
                                  label: 'Last Meal',
                                  value: _lastMealTime,
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
                child: SizedBox(
                  height: 340,
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      CustomCard(
                        text: 'Calculate dose insulin',
                        icon: Icons.medication_liquid,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CalculateDoseScreen()),
                          ).then((_) => _loadUserData());
                        },
                      ),
                      CustomCard(
                        text: 'Log glucose',
                        icon: Icons.bloodtype,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LogGlucoseScreen()),
                          ).then((_) => _loadUserData());
                        },
                      ),
                      CustomCard(
                        text: 'Add meal',
                        icon: Icons.restaurant_menu,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddPlateScreen()),
                          ).then((_) => _loadUserData());
                        },
                      ),
                      CustomCard(
                        text: 'Add activity',
                        icon: Icons.directions_run,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ActivityScreen()),
                          );
                        },
                      ),
                    ],
                  ),
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
                                color: Colors.black87,
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
                      ),
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
    String displayValue = value;
    if (label == 'Glucose' && value != 'N/A') {
      // Ensure glucose is displayed as a string, handling potential non-string values
      displayValue = value.toString();
    } else if (label == 'Injection' && value != 'N/A') {
      // Convert injection value to integer
      final double? injectionDouble = double.tryParse(value);
      if (injectionDouble != null) {
        displayValue = injectionDouble.round().toString();
      } else {
        displayValue = 'N/A';
      }
    }

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
          displayValue,
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
