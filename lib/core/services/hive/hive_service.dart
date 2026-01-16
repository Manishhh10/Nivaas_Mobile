import 'package:hive_flutter/adapters.dart';
import 'package:nivaas/core/constants/hive_table_constant.dart';
import 'package:nivaas/features/auth/data/models/user_hive_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class HiveService {
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstant.dbName}';

    // Delete the directory to clear old data
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    Hive.init(path);

    _registerAdapters();
    await _openBoxes();
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserHiveModelAdapter());
    }
  }

  Future<void> _openBoxes() async {
    await Hive.openBox<UserHiveModel>(HiveTableConstant.userTable);
    await Hive.openBox('authBox'); // For storing login state
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

  String? getLoggedInUser() {
    return _authBox.get('loggedInUser');
  }

  bool isLoggedIn() {
    return _authBox.get('isLoggedIn', defaultValue: false) as bool;
  }

  Future<void> logout() async {
    await _authBox.put('loggedInUser', null);
    await _authBox.put('isLoggedIn', false);
  }

  Future<void> close() async {
    await Hive.close();
  }
}
