// lib/main.dart
import 'package:flutter/material.dart';

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
    );
  }
}