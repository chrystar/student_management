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
    String? lecturerId,
  }) async {
    try {
      // Password validation
      if (password != confirmPassword) {
        return 'Passwords do not match';
      }

      // Lecturer ID validation for lecturer role
      if (role == 'Lecturer') {
        if (lecturerId == null || lecturerId.isEmpty) {
          return 'Lecturer ID is required';
        }

        // Verify lecturer ID
        final lecturerIdVerification =
            await verifyLecturerId(lecturerId, email);
        if (lecturerIdVerification != null) {
          return lecturerIdVerification;
        }
      }

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // If user created successfully, add user data to Firestore
      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;

        // Add user data to users collection
        await _firestore.collection('users').doc(userId).set({
          'name': name.trim(),
          'email': email.trim(),
          'role': role,
          'matricNumber': null, // Will be set during verification for students
          'level': role == 'Student' ? level : null,
          'department': role == 'Student'
              ? department
              : (role == 'Lecturer'
                  ? await getLecturerDepartment(lecturerId!)
                  : null),
          'isVerified': role == 'Lecturer'
              ? true
              : false, // Lecturers are verified by ID, students need matric verification
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Mark lecturer ID as used if registration was successful
        if (role == 'Lecturer' && lecturerId != null) {
          await markLecturerIdAsUsed(lecturerId, userId);
        }

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

  // Verify lecturer ID against Firestore
  Future<String?> verifyLecturerId(String lecturerId, String email) async {
    try {
      final lecturerIdQuery = await _firestore
          .collection('lecturer_ids')
          .where('id', isEqualTo: lecturerId.trim())
          .get();

      if (lecturerIdQuery.docs.isEmpty) {
        return 'Invalid lecturer ID. Please contact administration.';
      }

      final lecturerData = lecturerIdQuery.docs.first.data();

      // Check if ID is already used
      if (lecturerData['isUsed'] == true) {
        return 'This lecturer ID has already been used.';
      }

      // Check if ID is expired
      final validUntil = lecturerData['validUntil'] as Timestamp?;
      if (validUntil != null && validUntil.toDate().isBefore(DateTime.now())) {
        return 'This lecturer ID has expired. Please contact administration for a new ID.';
      }

      // Check if ID was intended for this email (optional validation)
      final intendedEmail = lecturerData['email'] as String?;
      if (intendedEmail != null &&
          intendedEmail.isNotEmpty &&
          intendedEmail.toLowerCase() != email.toLowerCase()) {
        return 'This lecturer ID was not issued for this email address.';
      }

      return null; // Verification successful
    } catch (e) {
      return 'Lecturer ID verification failed: ${e.toString()}';
    }
  }

  // Mark lecturer ID as used after successful registration
  Future<void> markLecturerIdAsUsed(String lecturerId, String userId) async {
    try {
      final lecturerIdQuery = await _firestore
          .collection('lecturer_ids')
          .where('id', isEqualTo: lecturerId.trim())
          .get();

      if (lecturerIdQuery.docs.isNotEmpty) {
        await _firestore
            .collection('lecturer_ids')
            .doc(lecturerIdQuery.docs.first.id)
            .update({
          'isUsed': true,
          'userId': userId,
          'usedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Failed to mark lecturer ID as used: ${e.toString()}');
    }
  }

  // Get department from lecturer ID record
  Future<String?> getLecturerDepartment(String lecturerId) async {
    try {
      final lecturerIdQuery = await _firestore
          .collection('lecturer_ids')
          .where('id', isEqualTo: lecturerId.trim())
          .get();

      if (lecturerIdQuery.docs.isNotEmpty) {
        return lecturerIdQuery.docs.first.data()['department'] as String?;
      }
      return null;
    } catch (e) {
      print('Failed to get lecturer department: ${e.toString()}');
      return null;
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

      // Update the matric number in user's document and mark as verified
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
      // First, check if matric number exists in valid_matric_numbers collection
      final validMatricQuery = await _firestore
          .collection('valid_matric_numbers')
          .where('matricNumber', isEqualTo: matricNumber.trim().toUpperCase())
          .get();

      if (validMatricQuery.docs.isEmpty) {
        return "Invalid matric number. Please contact administration.";
      }

      final matricData = validMatricQuery.docs.first.data();
      final isUsed = matricData['isUsed'] ?? false;
      
      if (!isUsed) {
        return "Matric number not yet verified. Please complete registration first.";
      }

      // Get the associated email from the matric number document
      final userEmail = matricData['userEmail'] as String?;
      
      if (userEmail == null) {
        return "No email associated with this matric number. Please contact support.";
      }

      // Use the email to sign in
      await _auth.signInWithEmailAndPassword(
        email: userEmail,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Login failed: ${e.toString()}";
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
