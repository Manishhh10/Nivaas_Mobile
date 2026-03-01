import 'package:hive_flutter/adapters.dart';
import 'package:nivaas/core/constants/hive_table_constant.dart';
import 'package:nivaas/features/admin/data/models/admin_host_hive_model.dart';
import 'package:nivaas/features/auth/data/models/user_hive_model.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstant.dbName}';

    Hive.init(path);

    _registerAdapters();
    await _openBoxes();
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.adminHostTypeId)) {
      Hive.registerAdapter(AdminHostHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.adminActionTypeId)) {
      Hive.registerAdapter(AdminPendingActionAdapter());
    }
  }

  Future<void> _openBoxes() async {
    await Hive.openBox<UserHiveModel>(HiveTableConstant.userTable);
    await Hive.openBox('authBox'); // For storing login state
    await Hive.openBox<AdminHostHiveModel>(HiveTableConstant.adminHostsBox);
    await Hive.openBox<AdminPendingAction>(HiveTableConstant.adminActionsBox);
  }

  Box<UserHiveModel> get _userBox =>
      Hive.box<UserHiveModel>(HiveTableConstant.userTable);

  Box get _authBox => Hive.box('authBox');

  // User CRUD Operations
  Future<void> createUser(UserHiveModel user) async {
    await _userBox.put(user.email, user);
  }

  List<UserHiveModel> getAllUsers() {
    return _userBox.values.toList();
  }

  UserHiveModel? getUserByEmail(String email) {
    return _userBox.get(email);
  }

  Future<void> updateUser(UserHiveModel user) async {
    await _userBox.put(user.email, user);
  }

  Future<void> deleteUser(String email) async {
    await _userBox.delete(email);
  }

  Future<void> clearAllUsers() async {
    await _userBox.clear();
  }

  // Auth State Management
  Future<void> saveLoginState(String email) async {
    await _authBox.put('loggedInUser', email);
    await _authBox.put('isLoggedIn', true);
  }

  Future<void> saveUserRole(String role) async {
    await _authBox.put('userRole', role);
  }

  String getUserRole() {
    final value = _authBox.get('userRole');
    return (value == null ? 'user' : value.toString()).trim();
  }

  String? getLoggedInUser() {
    return _authBox.get('loggedInUser');
  }

  bool isLoggedIn() {
    return _authBox.get('isLoggedIn', defaultValue: false) as bool;
  }

  Future<Map<String, dynamic>?> getUser() async {
    final email = getLoggedInUser();
    if (email != null) {
      final user = getUserByEmail(email);
      if (user != null) {
        return {
          'id': user.id,
          '_id': user.id,
          'name': user.name,
          'email': user.email,
          'phone': user.phoneNumber,
          'phoneNumber': user.phoneNumber,
          'profileImagePath': user.profileImagePath,
          'role': getUserRole(),
        };
      }
    }
    return null;
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    final email = getLoggedInUser();
    if (email != null) {
      final user = getUserByEmail(email);
      if (user != null) {
        final nextEmail = (data['email'] ?? user.email).toString();
        final nextPhone = (data['phoneNumber'] ?? data['phone'] ?? user.phoneNumber).toString();
        final updatedUser = UserHiveModel(
          id: user.id,
          name: data['name'] ?? user.name,
          email: nextEmail,
          phoneNumber: nextPhone,
          profileImagePath: data['profileImagePath'] ?? user.profileImagePath,
        );
        if (nextEmail != user.email) {
          await _userBox.delete(user.email);
        }
        await _userBox.put(updatedUser.email, updatedUser);
        if (nextEmail != user.email) {
          await _authBox.put('loggedInUser', nextEmail);
        }
      }
    }
  }

  Future<void> logout() async {
    await _authBox.put('loggedInUser', null);
    await _authBox.put('isLoggedIn', false);
    await _authBox.put('token', null);
    await _authBox.put('userRole', null);
  }

  Future<void> saveToken(String token) async {
    await _authBox.put('token', token);
  }

  String? getToken() {
    return _authBox.get('token');
  }

  Future<void> saveThemeMode(String mode) async {
    await _authBox.put('themeMode', mode);
  }

  String getThemeMode() {
    return (_authBox.get('themeMode') ?? 'auto').toString();
  }

  Future<void> saveApiBaseUrl(String url) async {
    await _authBox.put('apiBaseUrl', url);
  }

  String? getApiBaseUrl() {
    final value = _authBox.get('apiBaseUrl');
    if (value == null) return null;
    final url = value.toString().trim();
    return url.isEmpty ? null : url;
  }

  Future<void> clearApiBaseUrl() async {
    await _authBox.delete('apiBaseUrl');
  }
}
