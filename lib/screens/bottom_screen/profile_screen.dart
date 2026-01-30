import 'package:flutter/material.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/screens/home_check_screen.dart';
import 'package:nivaas/screens/login_screen.dart';
import 'package:nivaas/screens/bottom_screen/edit_profile_screen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final hiveService = HiveService();
      if (!hiveService.isLoggedIn()) {
        // Navigate to login if not logged in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }
      final userData = await hiveService.getUser();
      setState(() {
        _userData = userData ?? {};
        _profileImage = null;
        if (_userData?['profileImagePath'] != null) {
          final imagePath = _userData!['profileImagePath'];
          // Check if it's a network URL or local file path
          if (imagePath.startsWith('http') || imagePath.startsWith('/')) {
            // Network image - will be handled by Image.network in build
          } else {
            // Local file path
            final file = File(imagePath);
            if (file.existsSync()) {
              _profileImage = file;
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _userData = {};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  void _logout(BuildContext context) {
    final hiveService = HiveService();
    hiveService.logout();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Use Future.delayed to ensure snackbar is shown before navigation
    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeCheckScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: _userData == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _buildProfileImage(),
                    child: _buildProfileImageChild(),
                  ),
                  const SizedBox(height: 20),
                  Text('Name: ${_userData!['name'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text('Email: ${_userData!['email'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text('Phone: ${_userData!['phone'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen()),
                      ).then((_) => _loadUserData()); // Reload data after editing
                    },
                    child: const Text('Edit Profile'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  ImageProvider? _buildProfileImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    }
    final imagePath = _userData?['profileImagePath'];
    if (imagePath != null) {
      if (imagePath.startsWith('http') || imagePath.startsWith('/')) {
        final baseUrl = 'http://10.0.2.2:3002'; // Android emulator
        final fullUrl = imagePath.startsWith('http') ? imagePath : '$baseUrl$imagePath';
        return NetworkImage(fullUrl);
      }
    }
    return null;
  }

  Widget? _buildProfileImageChild() {
    if (_profileImage != null || (_userData?['profileImagePath'] != null)) {
      return null;
    }
    return const Icon(Icons.person, size: 50);
  }
}
