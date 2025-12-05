import 'package:flutter/material.dart';
import 'package:nivaas/screens/splash_screen.dart';

void main() {
  runApp(const NivaasApp());
}

class NivaasApp extends StatelessWidget {
  const NivaasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nivaas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}