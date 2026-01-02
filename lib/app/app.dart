import 'package:flutter/material.dart';
import 'package:nivaas/screens/bottom_navigation_screen.dart';
import 'package:nivaas/theme/theme_data.dart';
// import 'package:flutter_for_college/screens/dashboard_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Apps for College',
      debugShowCheckedModeBanner: false,
      theme: getApplicationTheme(),
      home: const BottomNavigationScreen(),
    );
  }
}
