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
      final snapshot = await _firestore.collection('users').doc(currentUser.uid).get();
      _user = UserModel.fromMap(snapshot.data()!);
      notifyListeners();
    }
  }

  void logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
