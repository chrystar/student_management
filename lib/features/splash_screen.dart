// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/provider/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserData();

    final role = userProvider.user?.role;

    if (role == 'Student') {
      Navigator.pushReplacementNamed(context, '/student-home');
    } else if (role == 'Lecturer') {
      Navigator.pushReplacementNamed(context, '/lecturer-home');
    } else if (role == 'Admin') {
      Navigator.pushReplacementNamed(context, '/admin-home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
