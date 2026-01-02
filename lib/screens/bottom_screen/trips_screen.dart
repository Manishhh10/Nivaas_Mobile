import 'package:flutter/material.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Trips", style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
