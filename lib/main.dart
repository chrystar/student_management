import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/features/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_management/firebase_options.dart';
import 'features/admin/presentation/admin_home_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/registration_screen.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/auth/provider/user_provider.dart';
import 'features/lecturer/presentaion/lecturer_home_screen.dart';
import 'features/student/presentation/student_home_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return  MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/student-home': (context) => const StudentHomeScreen(),
          '/lecturer-home': (context) => const LecturerHomeScreen(),
          '/admin-home': (context) => const AdminHomeScreen(),
        },
      ),
    );
  }
}


