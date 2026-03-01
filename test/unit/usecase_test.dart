import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nivaas/core/error/failures.dart';
import 'package:nivaas/features/auth/domain/entities/user_entity.dart';
import 'package:nivaas/features/auth/domain/repositories/auth_repository.dart';
import 'package:nivaas/features/auth/domain/usecases/login_usecase.dart';
import 'package:nivaas/features/auth/domain/usecases/signup_usecase.dart';
import 'package:nivaas/features/auth/data/models/login_request.dart';
import 'package:nivaas/features/auth/data/models/register_request.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';
import 'package:nivaas/features/auth/data/models/user_hive_model.dart';
import 'package:nivaas/features/explore/data/models/accommodation_model.dart';
import 'package:nivaas/features/explore/data/models/experience_model.dart';
import 'package:nivaas/features/explore/data/models/review_model.dart';
import 'package:nivaas/features/trips/data/models/booking_model.dart';
import 'package:nivaas/features/admin/data/models/admin_host_hive_model.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  // ─── Group 1: Auth Use-Case Tests (LoginUseCase + SignupUseCase) ───────────

  group('LoginUseCase', () {
    late MockAuthRepository mockRepository;
    late LoginUseCase loginUseCase;

    const tUser = UserEntity(
      id: 'u1',
      name: 'Test User',
      email: 'test@example.com',
      phoneNumber: '9800000000',
      role: 'user',
    );

    setUp(() {
      mockRepository = MockAuthRepository();
      loginUseCase = LoginUseCase(repository: mockRepository);
    });

    // TEST 1
    test('returns UserEntity on successful login', () async {
      when(() => mockRepository.login('test@example.com', 'password123'))
          .thenAnswer((_) async => const Right(tUser));

      final result = await loginUseCase('test@example.com', 'password123');

      expect(result, const Right(tUser));
      verify(() => mockRepository.login('test@example.com', 'password123'))
          .called(1);
    });

    // TEST 2
    test('returns Failure on login error', () async {
      when(() => mockRepository.login('bad@email.com', 'wrong'))
          .thenAnswer((_) async =>
              const Left(Failure(message: 'Invalid credentials')));

      final result = await loginUseCase('bad@email.com', 'wrong');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'Invalid credentials'),
        (_) => fail('Expected a failure'),
      );
    });
  });

  group('SignupUseCase', () {
    late MockAuthRepository mockRepository;
    late SignupUseCase signupUseCase;

    const tUser = UserEntity(
      id: 'u2',
      name: 'New User',
      email: 'new@example.com',
      phoneNumber: '9811111111',
      role: 'user',
    );

    setUp(() {
      mockRepository = MockAuthRepository();
      signupUseCase = SignupUseCase(repository: mockRepository);
    });

    // TEST 3
    test('returns UserEntity on successful signup', () async {
      when(() => mockRepository.register(
            'New User',
            'new@example.com',
            'password123',
            '9811111111',
          )).thenAnswer((_) async => const Right(tUser));

      final result = await signupUseCase(
          'New User', 'new@example.com', 'password123', '9811111111');

      expect(result, const Right(tUser));
      verify(() => mockRepository.register(
            'New User',
            'new@example.com',
            'password123',
            '9811111111',
          )).called(1);
    });

    // TEST 4
    test('returns Failure when email already exists', () async {
      when(() => mockRepository.register(any(), any(), any(), any()))
          .thenAnswer((_) async =>
              const Left(Failure(message: 'Email already registered')));

      final result = await signupUseCase(
          'Dup User', 'dup@example.com', 'pass123', '9800000001');

      result.fold(
        (failure) => expect(failure.message, 'Email already registered'),
        (_) => fail('Expected a failure'),
      );
    });
  });

  // ─── Group 2: Model Serialization / Domain Logic Use-Cases ────────────────

  group('Accommodation model use-cases', () {
    // TEST 5
    test('fromJson parses hostId as populated object and resolves hostName',
        () {
      final json = {
        '_id': 'acc1',
        'hostId': {
          '_id': 'host1',
          'userId': {'_id': 'user1', 'name': 'Alice Host', 'image': '/img.jpg'},
          'legalName': 'Alice Legal',
        },
        'title': 'Mountain View',
        'location': 'Pokhara',
        'price': 5000,
        'maxGuests': 4,
        'bedrooms': 2,
        'beds': 3,
        'bathrooms': 1,
      };

      final accommodation = Accommodation.fromJson(json);

      expect(accommodation.id, 'acc1');
      expect(accommodation.hostName, 'Alice Host');
      expect(accommodation.hostImage, '/img.jpg');
      expect(accommodation.hostUserId, 'user1');
      expect(accommodation.price, 5000.0);
      expect(accommodation.firstImage, '');
    });

    // TEST 6
    test('firstImage returns first entry or empty string', () {
      final withImages = Accommodation(
        id: 'a1',
        hostId: 'h1',
        title: 'T',
        location: 'L',
        price: 100,
        maxGuests: 1,
        bedrooms: 1,
        beds: 1,
        bathrooms: 1,
        images: ['/img1.jpg', '/img2.jpg'],
      );
      expect(withImages.firstImage, '/img1.jpg');

      final noImages = Accommodation(
        id: 'a2',
        hostId: 'h2',
        title: 'T',
        location: 'L',
        price: 100,
        maxGuests: 1,
        bedrooms: 1,
        beds: 1,
        bathrooms: 1,
      );
      expect(noImages.firstImage, '');
    });
  });

  group('Booking model use-cases', () {
    // TEST 7
    test('fromJson with populated accommodation resolves item properties', () {
      final json = {
        '_id': 'b1',
        'userId': 'u1',
        'accommodationId': {
          '_id': 'acc1',
          'title': 'Lake House',
          'location': 'Pokhara',
          'images': ['/lake.jpg'],
        },
        'startDate': '2026-03-10',
        'endDate': '2026-03-15',
        'totalPrice': 25000,
        'status': 'confirmed',
      };

      final booking = Booking.fromJson(json);

      expect(booking.id, 'b1');
      expect(booking.isStay, isTrue);
      expect(booking.isExperience, isFalse);
      expect(booking.itemTitle, 'Lake House');
      expect(booking.itemLocation, 'Pokhara');
      expect(booking.itemImages, ['/lake.jpg']);
      expect(booking.totalPrice, 25000.0);
    });

    // TEST 8
    test('isExperience is true when experienceId is set', () {
      final json = {
        '_id': 'b2',
        'userId': 'u1',
        'experienceId': {
          '_id': 'exp1',
          'title': 'Hiking Tour',
          'location': 'Annapurna',
          'images': ['/hike.jpg'],
        },
        'startDate': '2026-04-01',
        'endDate': '2026-04-01',
        'totalPrice': 3000,
        'status': 'pending',
      };

      final booking = Booking.fromJson(json);

      expect(booking.isExperience, isTrue);
      expect(booking.isStay, isFalse);
      expect(booking.itemTitle, 'Hiking Tour');
    });
  });

  group('Review model use-cases', () {
    // TEST 9
    test('fromJson handles populated userId and accommodationId', () {
      final json = {
        '_id': 'r1',
        'userId': {
          '_id': 'u1',
          'name': 'Reviewer',
          'image': '/reviewer.jpg',
        },
        'accommodationId': {'_id': 'acc1', 'title': 'Stay'},
        'rating': 5,
        'comment': 'Amazing place!',
        'createdAt': '2026-03-01T10:00:00Z',
      };

      final review = Review.fromJson(json);

      expect(review.id, 'r1');
      expect(review.userId, 'u1');
      expect(review.user?['name'], 'Reviewer');
      expect(review.accommodationId, 'acc1');
      expect(review.rating, 5);
      expect(review.comment, 'Amazing place!');
    });
  });

  group('AdminHostHiveModel use-cases', () {
    // TEST 10
    test('fromApiMap and toApiMap round-trip preserves data', () {
      final apiMap = {
        '_id': 'host1',
        'userId': {
          'name': 'Host User',
          'email': 'host@test.com',
          'phoneNumber': '9800000000',
        },
        'legalName': 'Host Legal Name',
        'phoneNumber': '9811111111',
        'address': 'Kathmandu',
        'governmentId': 'GOV123',
        'idDocument': '/docs/id.pdf',
        'verificationStatus': 'pending',
        'rejectionReason': '',
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final model = AdminHostHiveModel.fromApiMap(apiMap);
      final roundTrip = model.toApiMap();

      expect(roundTrip['_id'], 'host1');
      expect(roundTrip['userId']['name'], 'Host User');
      expect(roundTrip['userId']['email'], 'host@test.com');
      expect(roundTrip['legalName'], 'Host Legal Name');
      expect(roundTrip['verificationStatus'], 'pending');
      expect(roundTrip['address'], 'Kathmandu');
      expect(roundTrip['governmentId'], 'GOV123');
    });
  });
}
