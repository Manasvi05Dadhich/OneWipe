import 'package:flutter/material.dart';
import 'screens/wipe_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/offline_screen.dart';
import 'screens/settings_screen.dart';
import '../widgets/responsive_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Helper so any widget can toggle the theme
  static void toggleTheme(BuildContext context) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.toggleTheme();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Default dark mode

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureWipe Pro',
      debugShowCheckedModeBanner: false,

      // Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F6F8),
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        cardColor: const Color(0xFF1C1C1C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1C),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),

      // Use current theme
      themeMode: _themeMode,

      // Navigation
      initialRoute: '/dashboard',
      routes: {
        '/dashboard': (context) => const WipeScreen(),
        '/verify': (context) => const VerifyScreen(),
        '/offline': (context) => const OfflineScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
