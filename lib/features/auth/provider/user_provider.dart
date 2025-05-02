// features/auth/provider/user_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  UserModel? get user => _user;

  Future<void> loadUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final snapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        _user = UserModel(
          uid: currentUser.uid,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? 'Student',
          matricNumber: data['matricNumber'] ?? '',
          level: data['level'],
          department: data['department'] ?? '',
        );
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
