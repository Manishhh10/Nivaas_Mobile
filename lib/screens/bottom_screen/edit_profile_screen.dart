import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/core/services/api/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nivaas/screens/login_screen.dart';

class EditProfileScreen extends StatefulWidget {
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

      // Upload to backend
      final apiService = ApiService();
      final imagePath = await apiService.uploadProfilePicture(localFile);
      if (imagePath != null) {
        // Update with server path for persistence
        _userData?['profileImagePath'] = imagePath;
        final hiveService = HiveService();
        await hiveService.updateUserData({'profileImagePath': imagePath});
      }
    }
  }

  Future<void> _saveProfile() async {
    final updatedData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'phoneNumber': _phoneController.text,
      if (_profileImage != null) 'profileImagePath': _profileImage!.path,
    };

    final hiveService = HiveService();
    await hiveService.updateUserData(updatedData);

    // Update backend
    final apiService = ApiService();
    try {
      final response = await apiService.updateProfile(updatedData);
      if (response != null && response['profileImage'] != null) {
        // Update local storage with server image path
        final updatedDataWithServerPath = {
          ...updatedData,
          'profileImagePath': response['profileImage'],
        };
        await hiveService.updateUserData(updatedDataWithServerPath);
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
        final baseUrl = 'http://10.0.2.2:3002'; // Android emulator
        final fullUrl = imagePath.startsWith('http') ? imagePath : '$baseUrl$imagePath';
        return ClipOval(child: Image.network(fullUrl, fit: BoxFit.cover, width: 100, height: 100, errorBuilder: (context, error, stackTrace) => const Icon(Icons.camera_alt, size: 50)));
      }
    }
    
    return const Icon(Icons.camera_alt, size: 50);
  }
}