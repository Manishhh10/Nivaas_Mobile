import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/core/services/api/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nivaas/features/auth/presentation/pages/login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final hiveService = HiveService();
      if (!hiveService.isLoggedIn()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      // Fetch fresh user data from backend using ApiClient (Dio)
      try {
        final api = ApiClient();
        final response = await api.get(ApiEndpoints.verify);
        final user = response.data['user'] as Map<String, dynamic>?;
        if (user != null) {
          final serverImage = user['image'] as String?;
          if (serverImage != null && serverImage.isNotEmpty) {
            await hiveService.updateUserData({'profileImagePath': serverImage});
          }
        }
      } catch (_) {
        // Fallback to cached Hive data if network fails
      }

      final userData = await hiveService.getUser();
      setState(() {
        _userData = userData ?? {};
        _nameController.text = _userData?['name'] ?? '';
        _emailController.text = _userData?['email'] ?? '';
        _phoneController.text = _userData?['phone'] ?? '';
        _profileImage = null;
        if (_userData?['profileImagePath'] != null) {
          final imagePath = _userData!['profileImagePath'];
          // Only set _profileImage for local files
          if (!imagePath.startsWith('http') && !imagePath.startsWith('/')) {
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

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      // Copy to app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${directory.path}/$fileName';
      final localFile = await File(pickedFile.path).copy(localPath);

      setState(() {
        _profileImage = localFile;
        _userData?['profileImagePath'] = localPath;
      });

      try {
        final apiService = ApiService();
        final userId = _userData?['id'] ?? _userData?['_id'] ?? '';
        if (userId.isEmpty) {
          throw Exception('User ID missing. Please log in again.');
        }
        final imagePath = await apiService.uploadProfilePicture(localFile, userId);
        if (imagePath != null) {
          _userData?['profileImagePath'] = imagePath;
          final hiveService = HiveService();
          await hiveService.updateUserData({'profileImagePath': imagePath});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: ${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    final updatedData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneController.text,
    };

    final hiveService = HiveService();
    await hiveService.updateUserData(updatedData);

    // Update backend
    final apiService = ApiService();
    final userId = _userData?['id'] ?? _userData?['_id'] ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again to update profile')),
      );
      return;
    }
    try {
      final response = await apiService.updateProfile(userId, updatedData);
      if (response != null && response['image'] != null) {
        // Update local storage with server image path
        await hiveService.updateUserData({
          'profileImagePath': response['image'],
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: _buildEditProfileImage(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileImage() {
    if (_profileImage != null) {
      return ClipOval(child: Image.file(_profileImage!, fit: BoxFit.cover, width: 100, height: 100));
    }
    
    final imagePath = _userData?['profileImagePath'];
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http') || imagePath.startsWith('/')) {
        final baseUrl = 'http://10.0.2.2:5000'; // Android emulator
        final fullUrl = imagePath.startsWith('http') ? imagePath : '$baseUrl$imagePath';
        return ClipOval(child: Image.network(fullUrl, fit: BoxFit.cover, width: 100, height: 100, errorBuilder: (context, error, stackTrace) => const Icon(Icons.camera_alt, size: 50)));
      }
    }
    
    return const Icon(Icons.camera_alt, size: 50);
  }
}