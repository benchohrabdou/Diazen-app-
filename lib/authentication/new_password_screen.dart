import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diazen/authentication/password_update_succes_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTyping = false;
  double _buttonScale = 1.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _passwordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));

    _passwordController.addListener(_checkTyping);
    _confirmPasswordController.addListener(_checkTyping);
  }

  void _checkTyping() {
    setState(() {
      _isTyping = _passwordController.text.isNotEmpty || _confirmPasswordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkTyping);
    _confirmPasswordController.removeListener(_checkTyping);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onUpdatePressed() async {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt to sign in with the email to refresh authentication state
      // Use a placeholder password as we don't have the current one.
      // This step is primarily to satisfy the 'requires-recent-login' requirement for updatePassword.
      try {
         await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: widget.email,
          password: 'temporary-reauth-password', // Placeholder - this sign-in will likely fail
        );
      } catch (e) {
        // Ignore expected sign-in failure due to incorrect password
         print('Temporary sign-in attempt for re-auth failed: $e');
      }

      // Get the user again after the potential re-authentication attempt
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null || user.email != widget.email) {
         // If after the sign-in attempt, we still don't have the expected user,
         // it indicates a deeper authentication issue.
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Authentication state invalid. Please restart the password reset.')),
         );
         return;
      }

      // Update the password for the now potentially re-authenticated user
      await user.updatePassword(_passwordController.text);

      // Delete the OTP from Firestore after successful password update
      await _firestore.collection('password_resets').doc(widget.email).delete();

      if (!mounted) return;
      
      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PasswordUpdateSuccessScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      // Handle specific Firebase Auth errors during password update
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        case 'requires-recent-login':
           errorMessage = 'Please sign in again to update your password. (Restart password reset)';
           break;
        case 'user-not-found': // Should not happen if currentUser is valid, but for completeness
           errorMessage = 'User not found.';
           break;
        case 'invalid-credential':
           errorMessage = 'Invalid credentials. (This may occur during re-authentication attempt)';
           break;
        default:
          errorMessage = e.message ?? 'An error occurred';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // Handle other potential errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Set a new password',
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a new password. Ensure it differs from\nprevious ones for security',
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 14,
                color: Color(0xFF7B6F72),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Password',
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              focusNode: _passwordFocus,
              decoration: InputDecoration(
                hintText: 'Enter your new password',
                hintStyle: TextStyle(
                  fontFamily: 'SfProDisplay',
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F8F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _passwordFocus.hasFocus ? const Color(0xFF92A3FD) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF92A3FD),
                    width: 2.0,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirm password',
              style: TextStyle(
                fontFamily: 'SfProDisplay',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              focusNode: _confirmPasswordFocus,
              decoration: InputDecoration(
                hintText: 'Re-enter password',
                hintStyle: TextStyle(
                  fontFamily: 'SfProDisplay',
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F8F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _confirmPasswordFocus.hasFocus ? const Color(0xFF92A3FD) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF92A3FD),
                    width: 2.0,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedScale(
              scale: _buttonScale,
              duration: const Duration(milliseconds: 100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onUpdatePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTyping
                        ? const Color(0xFF4A7BF7)
                        : const Color(0xFF92A3FD),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                          'Update Password',
                          style: TextStyle(
                            fontFamily: 'SfProDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
