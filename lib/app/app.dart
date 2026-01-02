import 'package:flutter/material.dart';
import 'package:nivaas/app/theme/app_theme.dart';
import 'package:nivaas/screens/home_check_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nivaas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeCheckScreen(),
    );
  }
}
