import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login_screen.dart';
import 'screens/student/student_home.dart';
import 'screens/counselor/counselor_home.dart';
import 'screens/common/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedRole = prefs.getString('role');
  final savedName = prefs.getString('name') ?? 'User';

  runApp(
    MyApp(
      initialRole: savedRole,
      initialName: savedName,
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initialRole;
  final String initialName;

  const MyApp({
    super.key,
    this.initialRole,
    required this.initialName,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCMS - Code & Cry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          primary: const Color(0xFF4A90E2),
          secondary: const Color(0xFF50C878),
          background: const Color(0xFFF8FAFC),
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: _decideInitialScreen(initialRole, initialName),
    );
  }

  Widget _decideInitialScreen(String? role, String name) {
    if (role == null) return const LoginScreen();

    if (role == 'student') {
      return StudentHomeScreen(userName: name);
    } else if (role == 'counselor') {
      return CounselorHomeScreen(userName: name);
    }

    return const LoginScreen();
  }
}