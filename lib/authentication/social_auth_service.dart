import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diazen/authentication/medical_info_form.dart';
import 'package:diazen/screens/mainscreen.dart';

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign In
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Handle successful sign-in
      await _handleSuccessfulSignIn(context, userCredential);

      return userCredential;
    } catch (e) {
      _showErrorMessage(
          context, 'Failed to sign in with Google: ${e.toString()}');
      return null;
    }
  }

  // Facebook Sign In
  Future<UserCredential?> signInWithFacebook(BuildContext context) async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: [
          'email',
          'public_profile'
        ], // Ensure these permissions are configured
      );

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed: ${result.message}');
      }

      // Create a credential from the access token
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString, // Use tokenString instead of token
      );

      // Sign in with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Handle successful sign-in
      await _handleSuccessfulSignIn(context, userCredential);

      return userCredential;
    } catch (e) {
      _showErrorMessage(
          context, 'Failed to sign in with Facebook: ${e.toString()}');
      return null;
    }
  }

  // Handle successful sign-in for both methods
  Future<void> _handleSuccessfulSignIn(
      BuildContext context, UserCredential userCredential) async {
    if (userCredential.user != null) {
      final user = userCredential.user!;

      // Mark user as logged in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Get user info
      String firstName = '';
      String lastName = '';
      String email = user.email ?? '';

      // Try to get display name parts
      if (user.displayName != null) {
        final nameParts = user.displayName!.split(' ');
        firstName = nameParts.isNotEmpty ? nameParts.first : '';
        lastName = nameParts.length > 1 ? nameParts.last : '';
      }

      // For Facebook, try to get additional data
      if (userCredential.credential?.providerId == 'facebook.com') {
        final userData = await FacebookAuth.instance.getUserData();
        firstName = userData['first_name'] ?? firstName;
        lastName = userData['last_name'] ?? lastName;
      }

      // Navigate based on whether user is new
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MedicalInfoForm(
              userId: user.uid,
              email: email,
              firstName: firstName,
              lastName: lastName,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
    }
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
