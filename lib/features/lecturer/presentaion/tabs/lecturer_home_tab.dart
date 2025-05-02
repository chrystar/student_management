import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/user_provider.dart';

class LecturerHomeTab extends StatefulWidget {
  const LecturerHomeTab({super.key});

  @override
  State<LecturerHomeTab> createState() => _LecturerHomeTabState();
}

class _LecturerHomeTabState extends State<LecturerHomeTab> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3E64FF),
          ),
        ),
      );
    }

    // Debug: Print user information
    print("Debug: User ID: ${user.uid}");
    print("Debug: User Name: ${user.name}");
    print("Debug: User Role: ${user.role}");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3E64FF),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${user.name}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/lecturer-profile');
              },
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF3E64FF)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
