// splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_management/core/theme/app_theme.dart';
import 'auth/provider/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    
    // Delay navigation slightly to allow widget to fully initialize
    Future.delayed(const Duration(milliseconds: 100), () {
      _navigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }  void _navigate() async {
    if (!mounted) return;
    
    // Wait for animation to complete first
    await Future.delayed(const Duration(milliseconds: 2500));

    // Check if widget is still mounted after the delay
    if (!mounted) return;
    
    // Add a safety timer that will force navigation after a timeout
    // This ensures the user isn't stuck on the splash screen
    bool hasNavigated = false;
    Timer? forceNavTimer;
    
    forceNavTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !hasNavigated) {
        print("Force navigating to login due to timeout");
        hasNavigated = true;
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Try to get current Firebase user
      final currentUser = FirebaseAuth.instance.currentUser;
      print("Current Firebase user: ${currentUser?.uid ?? 'None'}");
      
      // Add timeout to prevent hanging indefinitely
      await userProvider.loadUserData().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          print("Loading user data timed out");
          throw Exception("Timeout loading user data");
        },
      );

      // Cancel force navigation timer if we successfully loaded data
      if (forceNavTimer != null) {
        forceNavTimer.cancel();
      }
      
      if (!mounted) return;
      if (hasNavigated) return;  // Skip if we already force-navigated
      
      final role = userProvider.user?.role;
      print("User role detected: $role");
      
      hasNavigated = true;
      if (role == 'Student') {
        Navigator.pushReplacementNamed(context, '/student-home');
      } else if (role == 'Lecturer') {
        Navigator.pushReplacementNamed(context, '/lecturer-home');
      } else if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/admin-home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print("Error in navigation: $e");
      
      // Cancel force navigation timer if we're handling an error
      if (forceNavTimer != null) {
        forceNavTimer.cancel();
      }
      
      if (mounted && !hasNavigated) {
        hasNavigated = true;
        print("Navigating to login due to error");
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and branding
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 70,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App name
              FadeTransition(
                opacity: _fadeAnimation,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      FadeAnimatedText(
                        'EduManage',
                        duration: const Duration(milliseconds: 2000),
                      ),
                    ],
                    isRepeatingAnimation: false,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Smart Student Management',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
