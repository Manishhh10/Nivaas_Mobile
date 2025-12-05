import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Text(
          'HOME',
          style: TextStyle(
            fontSize: 32,
            color: Color(0xFFFF6518),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}