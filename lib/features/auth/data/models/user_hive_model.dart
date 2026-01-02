import 'package:hive/hive.dart';
import 'package:nivaas/features/auth/domain/entities/user_entity.dart';

part 'user_hive_model.g.dart';

@HiveType(typeId: 0)
class UserHiveModel {
  @HiveField(0)
  final String email;

  @HiveField(1)
  final String password;

  @HiveField(2)
  final DateTime createdAt;

  UserHiveModel({
    required this.email,
    required this.password,
    required this.createdAt,
  });

  // Convert UserEntity to UserHiveModel
  factory UserHiveModel.fromEntity(UserEntity entity) {
    return UserHiveModel(
      email: entity.email,
      password: entity.password,
      createdAt: entity.createdAt,
    );
  }

  // Convert UserHiveModel to UserEntity
  UserEntity toEntity() {
    return UserEntity(
      email: email,
      password: password,
      createdAt: createdAt,
    );
  }

  // Convert list of models to list of entities
  static List<UserEntity> toEntityList(List<UserHiveModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
