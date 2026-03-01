import 'package:nivaas/features/auth/data/models/user_hive_model.dart';

abstract class IAuthDataSource {
  Future<bool> signup(String email, String password);
  Future<bool> login(String email, String password);
  Future<UserHiveModel?> getUserByEmail(String email);
}
