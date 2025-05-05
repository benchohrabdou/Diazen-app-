import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStateService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is already logged in
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Mark user as logged in
  Future<void> setUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Clear login state on logout
  Future<void> logout() async {
    // Sign out from Firebase
    await _auth.signOut();

    // Clear the logged in preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}
