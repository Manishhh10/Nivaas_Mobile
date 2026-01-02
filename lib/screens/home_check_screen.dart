import 'package:flutter/material.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/screens/splash_screen.dart';
import 'package:nivaas/screens/bottom_navigation_screen.dart';

class HomeCheckScreen extends StatefulWidget {
  const HomeCheckScreen({super.key});

  @override
  State<HomeCheckScreen> createState() => _HomeCheckScreenState();
}

class _HomeCheckScreenState extends State<HomeCheckScreen> {
  late HiveService _hiveService;

  @override
  void initState() {
    super.initState();
    _hiveService = HiveService();
    _checkAuthState();
  }

  void _checkAuthState() async {
    // Add a small delay for smooth transition
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Check if user is logged in
      bool isLoggedIn = _hiveService.isLoggedIn();

      if (isLoggedIn) {
        // User already logged in, go to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavigationScreen()),
        );
      } else {
        // Not logged in, show splash/onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
