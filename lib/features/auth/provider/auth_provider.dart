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
    required String matricNumber,
  }) async {
    try {
      if (password != confirmPassword) return "Passwords do not match";

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        role: role,
        matricNumber: matricNumber,
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
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
