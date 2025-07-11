// features/auth/provider/user_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  UserModel? get user => _user;  Future<void> loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        // User not logged in
        print("No user is currently logged in");
        return;
      }
      
      // Before attempting to fetch user data, check if user is still authenticated
      try {
        // This will re-authenticate or throw an error if the token is expired
        await currentUser.getIdToken(true);
      } catch (e) {
        print("Token refresh failed, user may be logged out: $e");
        await _auth.signOut(); // Force sign out if token refresh fails
        return;
      }
      
      print("Attempting to fetch user data for: ${currentUser.uid}");
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get()
            .timeout(const Duration(seconds: 10));
        
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          print("User data fetched successfully: ${data['name']}");
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
        } else {
          print("User document doesn't exist or is empty");
        }
      } catch (e) {
        print("Firestore fetch error: $e");
        if (e.toString().contains('permission-denied')) {
          print("Permission denied error - check Firestore rules");
        }
        rethrow;
      }
    } catch (e) {
      print("Error loading user data: $e");
      // Re-throw to allow splash screen to handle the error
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
