import 'package:flutter/material.dart';
import 'package:student_management/features/lecturer/presentaion/tabs/lecturer_home_tab.dart';
import 'package:student_management/features/lecturer/presentaion/tabs/lecturer_registrations_tab.dart';
import 'package:student_management/features/lecturer/presentaion/tabs/news_feed.dart';
import 'package:student_management/features/admin/presentation/news/manage_news_screen.dart';
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
    LecturerNewsFeed(),
    ManageNewsScreen(), // Added direct access to create/manage news
    LecturerProfileTab(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        activeIcon: Icon(Icons.dashboard_rounded),
        label: "Dashboard"),
    BottomNavigationBarItem(
        icon: Icon(Icons.newspaper_rounded),
        activeIcon: Icon(Icons.newspaper_rounded),
        label: "News Feed"),
    BottomNavigationBarItem(
        icon: Icon(Icons.post_add_rounded),
        activeIcon: Icon(Icons.post_add_rounded),
        label: "Manage News"),
    BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            items: _items,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: Theme.of(context).colorScheme.primary,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            showUnselectedLabels: true,
            unselectedItemColor: Colors.grey.shade500,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            iconSize: 26,
          ),
        ),
      ),
    );
  }
}
