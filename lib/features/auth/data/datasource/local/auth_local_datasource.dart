import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/features/auth/data/models/user_hive_model.dart';

abstract class IAuthLocalDataSource {
  Future<bool> saveUser(UserHiveModel user);
  Future<UserHiveModel?> getUserByEmail(String email);
  Future<List<UserHiveModel>> getAllUsers();
  Future<bool> deleteUser(String email);
  Future<void> clearAllUsers();
}

class AuthLocalDataSource implements IAuthLocalDataSource {
  final HiveService hiveService;

  AuthLocalDataSource({required this.hiveService});

  @override
  Future<bool> saveUser(UserHiveModel user) async {
    try {
      // Check if user already exists
      final existingUser = hiveService.getUserByEmail(user.email);
      if (existingUser != null) {
        return false; // User already exists
      }

      await hiveService.createUser(user);
      return true;
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

  @override
  Future<List<UserHiveModel>> getAllUsers() async {
    try {
      return hiveService.getAllUsers();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> deleteUser(String email) async {
    try {
      final user = hiveService.getUserByEmail(email);
      if (user != null) {
        await hiveService.deleteUser(email);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearAllUsers() async {
    try {
      await hiveService.clearAllUsers();
    } catch (e) {
      // Handle error
    }
  }
}