import 'package:flutter/material.dart';
import 'package:student_management/features/lecturer/presentaion/tabs/lecturer_create_course.dart';
import 'package:student_management/features/lecturer/presentaion/tabs/lecturer_new_tab.dart';
import 'tabs/lecturer_home_tab.dart';
import 'tabs/lecturer_broadcast_tab.dart';
import 'tabs/lecturer_profile_tab.dart';

class LecturerHomeScreen extends StatefulWidget {
  const LecturerHomeScreen({super.key});

  @override
  State<LecturerHomeScreen> createState() => _LecturerHomeScreenState();
}

class _LecturerHomeScreenState extends State<LecturerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    LecturerHomeTab(),
    LecturerBroadcastTab(),
    LecturerCreateCourseTab(),
    LecturerNewTab(),
    LecturerProfileTab(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.campaign), label: "Broadcast"),
    BottomNavigationBarItem(icon: Icon(Icons.book), label: "Create Course"),
    BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: "News"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _items,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
