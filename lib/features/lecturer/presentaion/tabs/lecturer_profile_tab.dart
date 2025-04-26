import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LecturerProfileTab extends StatefulWidget {
  const LecturerProfileTab({super.key});

  @override
  State<LecturerProfileTab> createState() => _LecturerProfileTabState();
}

class _LecturerProfileTabState extends State<LecturerProfileTab> {
  final auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("profile"),
        actions: [
          IconButton(
            onPressed: () {
              auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}
