// features/auth/provider/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
    String? level,
    String? department,
  }) async {
    try {
      // Password validation
      if (password != confirmPassword) {
        return 'Passwords do not match';
      }

      // Create user in Firebase Auth - no matric validation at registration
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // If user created successfully, add user data to Firestore
      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;

        // Add user data to users collection without matric number
        await _firestore.collection('users').doc(userId).set({
          'name': name.trim(),
          'email': email.trim(),
          'role': role,
          'matricNumber': null, // Will be set during verification
          'level': role == 'Student' ? level : null,
          'department': role == 'Student' ? department : null,
          'isVerified': false, // Track verification status
          'createdAt': FieldValue.serverTimestamp(),
        });

        return null; // Registration successful
      }

      return 'Failed to create account';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'The email address is already in use';
      } else if (e.code == 'weak-password') {
        return 'The password is too weak';
      } else if (e.code == 'invalid-email') {
        return 'The email address is not valid';
      }
      return 'Registration error: ${e.message}';
    } catch (e) {
      return 'An error occurred: ${e.toString()}';
    }
  }

  // Add a method to verify matric number after registration
  Future<String?> verifyMatricNumber({
    required String matricNumber,
    required String userId,
    required String email,
  }) async {
    try {
      // Check if matric number exists in valid_matric_numbers collection
      final validMatricQuery = await _firestore
          .collection('valid_matric_numbers')
          .where('matricNumber', isEqualTo: matricNumber.trim().toUpperCase())
          .get();

      if (validMatricQuery.docs.isEmpty) {
        return 'Invalid matric number. Please contact administration.';
      }

      final matricData = validMatricQuery.docs.first.data();
      final isUsed = matricData['isUsed'] ?? false;

      if (isUsed) {
        return 'This matric number is already in use by another account.';
      }

      // Update the matric number in user's document and mark as used
      await _firestore.collection('users').doc(userId).update({
        'matricNumber': matricNumber.trim().toUpperCase(),
        'isVerified': true,
      });

      // Mark the matric number as used in valid_matric_numbers collection
      await _firestore
          .collection('valid_matric_numbers')
          .doc(validMatricQuery.docs.first.id)
          .update({
        'isUsed': true,
        'userId': userId,
        'userEmail': email,
      });

      return null; // Verification successful
    } catch (e) {
      return 'Verification failed: ${e.toString()}';
    }
  }

  Future<String?> loginWithMatric({
    required String matricNumber,
    required String password,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('matricNumber', isEqualTo: matricNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return "Matric number not found";

      final email = snapshot.docs.first['email'];
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}
