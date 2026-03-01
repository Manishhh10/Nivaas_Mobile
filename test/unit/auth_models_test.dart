import 'package:flutter_test/flutter_test.dart';
import 'package:nivaas/features/auth/data/models/login_request.dart';
import 'package:nivaas/features/auth/data/models/register_request.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';
import 'package:nivaas/features/auth/data/models/user_hive_model.dart';
import 'package:nivaas/features/auth/domain/entities/user_entity.dart';

void main() {
  group('Auth model unit tests', () {
    test('LoginRequest.toJson returns correct map', () {
      final request = LoginRequest(email: 'test@example.com', password: 'secret');
      expect(request.toJson(), {
        'email': 'test@example.com',
        'password': 'secret',
      });
    });

    test('RegisterRequest.toJson returns correct map', () {
      final request = RegisterRequest(
        name: 'Test User',
        email: 'test@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phoneNumber: '1234567890',
      );
      expect(request.toJson(), {
        'name': 'Test User',
        'email': 'test@example.com',
        'password': 'secret',
        'confirmPassword': 'secret',
        'phoneNumber': '1234567890',
      });
    });

    test('LoginResponse.fromJson parses token', () {
      final response = LoginResponse.fromJson({
        'message': 'Login successful',
        'data': {
          'token': 'token123',
        },
      });

      expect(response.message, 'Login successful');
      expect(response.token, 'token123');
    });

    test('VerifyResponse.fromJson parses user and hostStatus', () {
      final response = VerifyResponse.fromJson({
        'message': 'Verified',
        'user': {
          '_id': 'user1',
          'name': 'Alice',
          'email': 'alice@example.com',
          'phoneNumber': '9876543210',
        },
        'hostStatus': {
          'status': 'verified',
          'isVerifiedHost': true,
        },
      });

      expect(response.message, 'Verified');
      expect(response.user?.id, 'user1');
      expect(response.user?.name, 'Alice');
      expect(response.user?.email, 'alice@example.com');
      expect(response.hostStatus?.isVerifiedHost, isTrue);
    });

    test('UserHiveModel.fromEntity and toEntity preserve fields', () {
      const entity = UserEntity(
        id: 'u1',
        name: 'Bob',
        email: 'bob@example.com',
        phoneNumber: '5551234',
        profileImagePath: '/path/to/image.jpg',
      );

      final model = UserHiveModel.fromEntity(entity);
      final converted = model.toEntity();

      expect(converted, equals(entity));
    });

    test('UserHiveModel.toEntityList maps all entries', () {
      final models = [
        UserHiveModel(
          id: 'u1',
          name: 'User One',
          email: 'u1@example.com',
          phoneNumber: '111',
        ),
        UserHiveModel(
          id: 'u2',
          name: 'User Two',
          email: 'u2@example.com',
          phoneNumber: '222',
        ),
      ];

      final entities = UserHiveModel.toEntityList(models);

      expect(entities.length, 2);
      expect(entities[0].id, 'u1');
      expect(entities[1].id, 'u2');
    });
  });
}
