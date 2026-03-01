import 'package:flutter_test/flutter_test.dart';
import 'package:nivaas/features/auth/presentation/view_model/auth_state.dart';
import 'package:nivaas/features/auth/domain/entities/user_entity.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';

void main() {
  // ─── Group 1: AuthState ViewModel Tests ──────────────────────────────────

  group('AuthState viewmodel', () {
    // TEST 1
    test('default state has initial status and null fields', () {
      const state = AuthState();

      expect(state.status, AuthStatus.initial);
      expect(state.errorMessage, isNull);
      expect(state.userEmail, isNull);
    });

    // TEST 2
    test('copyWith updates status to loading', () {
      const state = AuthState();
      final loading = state.copyWith(status: AuthStatus.loading);

      expect(loading.status, AuthStatus.loading);
      expect(loading.errorMessage, isNull);
      expect(loading.userEmail, isNull);
    });

    // TEST 3
    test('copyWith sets error status and message', () {
      const state = AuthState();
      final error = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid credentials',
      );

      expect(error.status, AuthStatus.error);
      expect(error.errorMessage, 'Invalid credentials');
    });

    // TEST 4
    test('copyWith sets success status and userEmail', () {
      const state = AuthState();
      final success = state.copyWith(
        status: AuthStatus.success,
        userEmail: 'user@example.com',
      );

      expect(success.status, AuthStatus.success);
      expect(success.userEmail, 'user@example.com');
    });

    // TEST 5
    test('copyWith clears errorMessage when transitioning to success', () {
      final errorState = const AuthState().copyWith(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong',
      );
      final successState = errorState.copyWith(
        status: AuthStatus.success,
        userEmail: 'new@user.com',
        errorMessage: null,
      );

      expect(successState.status, AuthStatus.success);
      expect(successState.errorMessage, isNull);
      expect(successState.userEmail, 'new@user.com');
    });
  });

  // ─── Group 2: UserEntity ViewModel Logic Tests ──────────────────────────

  group('UserEntity viewmodel logic', () {
    // TEST 6
    test('isAdmin returns true for admin role', () {
      const admin = UserEntity(
        id: 'a1',
        name: 'Admin',
        email: 'admin@nivaas.com',
        phoneNumber: '9800000000',
        role: 'admin',
      );

      expect(admin.isAdmin, isTrue);
    });

    // TEST 7
    test('isAdmin returns true for role with whitespace', () {
      const admin = UserEntity(
        id: 'a2',
        name: 'Admin',
        email: 'admin2@nivaas.com',
        phoneNumber: '9800000001',
        role: '  Admin  ',
      );

      expect(admin.isAdmin, isTrue);
    });

    // TEST 8
    test('isAdmin returns false for regular user', () {
      const user = UserEntity(
        id: 'u1',
        name: 'User',
        email: 'user@nivaas.com',
        phoneNumber: '9800000002',
        role: 'user',
      );

      expect(user.isAdmin, isFalse);
    });
  });

  // ─── Group 3: Auth Response / VerifyResponse ViewModel Tests ─────────────

  group('Auth response viewmodel parsing', () {
    // TEST 9
    test('VerifyResponse parses admin user with hostStatus correctly', () {
      final json = {
        'message': 'Verified',
        'user': {
          '_id': 'admin1',
          'name': 'Admin User',
          'email': 'admin@nivaas.com',
          'phoneNumber': '9800000000',
          'role': 'admin',
          'image': '/uploads/admin.jpg',
        },
        'hostStatus': {
          'status': 'verified',
          'isVerifiedHost': true,
          'rejectionReason': null,
        },
      };

      final response = VerifyResponse.fromJson(json);

      expect(response.user?.isAdmin, isTrue);
      expect(response.user?.name, 'Admin User');
      expect(response.user?.image, '/uploads/admin.jpg');
      expect(response.hostStatus?.isVerifiedHost, isTrue);
      expect(response.hostStatus?.status, 'verified');
      expect(response.hostStatus?.rejectionReason, isNull);
    });

    // TEST 10
    test('VerifyResponse handles missing hostStatus gracefully', () {
      final json = {
        'message': 'Verified',
        'user': {
          '_id': 'u1',
          'name': 'Regular',
          'email': 'regular@nivaas.com',
          'phoneNumber': '9811111111',
        },
      };

      final response = VerifyResponse.fromJson(json);

      expect(response.user?.name, 'Regular');
      expect(response.hostStatus, isNull);
      expect(response.user?.role, 'user');
      expect(response.user?.isAdmin, isFalse);
    });
  });
}
