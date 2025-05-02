// features/auth/presentation/student_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../provider/auth_provider.dart' as custom_auth;
import '../provider/user_provider.dart';
import '../../student/presentation/student_home_screen.dart';
import 'login_screen.dart';

class StudentVerificationScreen extends StatefulWidget {
  const StudentVerificationScreen({Key? key}) : super(key: key);

  @override
  State<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _matricController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // School logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Verification text
                    Text(
                      "Student Verification",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Please enter your matriculation number to complete registration",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Matric number input field
                    TextFormField(
                      controller: _matricController,
                      decoration: InputDecoration(
                        labelText: 'Matriculation Number',
                        hintText: 'e.g. CSC/2022/001',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your matriculation number';
                        }
                        return null;
                      },
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyMatricNumber,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Back to login option
                    TextButton(
                      onPressed: () {
                        _signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Cancel and return to login",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyMatricNumber() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = "User session expired. Please log in again.";
          });
          return;
        }

        final userEmail = currentUser.email;
        final authProvider =
            Provider.of<custom_auth.AuthProvider>(context, listen: false);

        // Call the verification method
        final result = await authProvider.verifyMatricNumber(
          matricNumber: _matricController.text.trim(),
          userId: currentUser.uid,
          email: userEmail!,
        );

        if (result == null) {
          // Verification successful
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          await userProvider
              .loadUserData(); // Reload user data with matric number

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification successful!')),
            );

            // Navigate to student home screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen()),
            );
          }
        } else {
          // Verification failed
          setState(() {
            _isLoading = false;
            _errorMessage = result;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = "An error occurred: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
