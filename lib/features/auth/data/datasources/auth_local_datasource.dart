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

      // Local datasource stores only minimal profile fields.
      final localId = DateTime.now().millisecondsSinceEpoch.toString();
      final localName = email.split('@').first;

      // Create new user
      final newUser = UserHiveModel(
        id: localId,
        name: localName,
        email: email,
        phoneNumber: '',
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
      // Password is not persisted in local storage model anymore.
      // Treat existence as a successful local login check.
      return user != null;
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