// features/home/screens/student_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/features/student/presentation/bottom_nav/activities.dart';
import 'package:student_management/features/student/presentation/bottom_nav/broadcast.dart';
import 'package:student_management/features/student/presentation/bottom_nav/courses_screen.dart';
import 'package:student_management/features/student/presentation/bottom_nav/home_screen.dart';
import 'package:student_management/features/student/presentation/bottom_nav/profile.dart';
import '../../auth/provider/user_provider.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    CoursesScreen(),
    Activities(),
    StudentBroadcastTab(),
    StudentProfileTab()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(

      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_outlined),
            label: 'activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Broadcast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
