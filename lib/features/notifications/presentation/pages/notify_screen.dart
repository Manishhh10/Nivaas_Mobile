import 'package:flutter/material.dart';

class NotifyScreen extends StatelessWidget {
  const NotifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Notifications", style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
