import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/features/auth/data/datasources/auth_datasource.dart';
import 'package:nivaas/features/auth/data/models/user_hive_model.dart';

class AuthLocalDataSource implements IAuthDataSource {
  final HiveService hiveService;

  AuthLocalDataSource({required this.hiveService});

  @override
  Future<bool> signup(String email, String password) async {
    try {
      // Check if user already exists
      final existingUser = hiveService.getUserByEmail(email);
      if (existingUser != null) {
        return false; // User already exists
      }

      // Create new user
      final newUser = UserHiveModel(
        email: email,
        password: password,
        createdAt: DateTime.now(),
      );

      await hiveService.createUser(newUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      final user = hiveService.getUserByEmail(email);
      if (user == null) {
        return false; // User not found
      }

      // Verify password (in production, use bcrypt or similar)
      if (user.password == password) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserHiveModel?> getUserByEmail(String email) async {
    try {
      return hiveService.getUserByEmail(email);
    } catch (e) {
      return null;
    }
  }
}