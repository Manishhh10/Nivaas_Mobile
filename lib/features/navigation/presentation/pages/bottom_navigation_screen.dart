import 'package:flutter/material.dart';
import 'package:nivaas/features/explore/presentation/pages/explore_screen.dart';
import 'package:nivaas/features/trips/presentation/pages/trips_screen.dart';
import 'package:nivaas/features/messages/presentation/pages/messages_screen.dart';
import 'package:nivaas/features/wishlist/presentation/pages/wishlist_screen.dart';
import 'package:nivaas/features/profile/presentation/pages/profile_screen.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int _selectedIndex = 0;

  static const Color primaryOrange = Color(0xFFFF6518);

  final List<Widget> _screens = const [
    ExploreScreen(),
    TripsScreen(),
    ConversationsScreen(),
    WishlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBackground = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _navItem(Icons.explore_outlined, Icons.explore, 'Explore', 0),
                _navItem(Icons.luggage_outlined, Icons.luggage, 'Trips', 1),
                _navItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages', 2),
                _navItem(Icons.favorite_border, Icons.favorite, 'Wishlist', 3),
                _navItem(Icons.person_outline, Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final unselectedColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.65);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? primaryOrange.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? primaryOrange : unselectedColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? primaryOrange : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
