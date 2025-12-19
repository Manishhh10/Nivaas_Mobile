import 'package:flutter/material.dart';
import 'package:nivaas/screens/bottom%20screen/explore_screen.dart';
import 'package:nivaas/screens/bottom%20screen/notify_screen.dart';
import 'package:nivaas/screens/bottom%20screen/profile_screen.dart';
import 'package:nivaas/screens/bottom%20screen/trips_screen.dart';
import 'package:nivaas/screens/bottom%20screen/wishlist_screen.dart';


class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> screens = const [
    ExploreScreen(),
    WishlistScreen(),
    TripsScreen(),
    NotifyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Wishlist"),
          BottomNavigationBarItem(icon: Icon(Icons.flight), label: "Trips"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notify"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
