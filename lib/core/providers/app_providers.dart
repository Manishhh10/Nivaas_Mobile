import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/features/explore/data/models/accommodation_model.dart';
import 'package:nivaas/features/explore/data/models/experience_model.dart';
import 'package:nivaas/features/explore/data/models/review_model.dart';
import 'package:nivaas/features/trips/data/models/booking_model.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// ─── Accommodations ───
final accommodationsProvider = FutureProvider<List<Accommodation>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.accommodations);
  final list = response.data['data'] as List? ?? [];
  return list.map((e) => Accommodation.fromJson(e)).toList();
});

final accommodationDetailProvider =
    FutureProvider.family<Accommodation, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.accommodationById(id));
  return Accommodation.fromJson(response.data['data']);
});

// ─── Experiences ───
final experiencesProvider = FutureProvider<List<Experience>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.experiences);
  final list = response.data['data'] as List? ?? [];
  return list.map((e) => Experience.fromJson(e)).toList();
});

final experienceDetailProvider =
    FutureProvider.family<Experience, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.experienceById(id));
  return Experience.fromJson(response.data['data']);
});

// ─── Bookings (user's trips) ───
final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.bookings);
  final list = response.data['data'] as List? ?? [];
  return list.map((e) => Booking.fromJson(e)).toList();
});

// ─── Reviews ───
final reviewsProvider = FutureProvider<List<Review>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.reviews);
  final list = response.data['data'] as List? ?? [];
  return list.map((e) => Review.fromJson(e)).toList();
});

// ─── Verify token (current user + host status) ───
final verifyProvider = FutureProvider.autoDispose<VerifyResponse>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.verify);
  return VerifyResponse.fromJson(response.data);
});

// ─── Notifications ───
final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.notifications);
  final rawData = response.data['data'];
  final List list;
  if (rawData is List) {
    list = rawData;
  } else if (rawData is Map) {
    list = (rawData['notifications'] as List?) ?? [];
  } else {
    list = [];
  }
  return list.cast<Map<String, dynamic>>();
});

// ─── Conversations ───
final conversationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.conversations);
  final list = response.data['conversations'] as List? ?? response.data['data'] as List? ?? [];
  return list.cast<Map<String, dynamic>>();
});

/// Invalidate all cached providers – call on logout so the next login
/// doesn't show stale data from the previous account.
void invalidateAllProviders(WidgetRef ref) {
  ref.invalidate(verifyProvider);
  ref.invalidate(accommodationsProvider);
  ref.invalidate(experiencesProvider);
  ref.invalidate(bookingsProvider);
  ref.invalidate(reviewsProvider);
  ref.invalidate(notificationsProvider);
  ref.invalidate(conversationsProvider);
}
