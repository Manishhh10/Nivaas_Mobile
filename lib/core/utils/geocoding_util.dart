import 'package:dio/dio.dart';

class GeocodingResult {
  final double lat;
  final double lng;
  final String displayName;

  GeocodingResult({required this.lat, required this.lng, required this.displayName});
}

/// Geocode a location string to lat/lng using OpenStreetMap Nominatim
Future<GeocodingResult?> geocodeLocation(String query) async {
  try {
    final dio = Dio();
    final response = await dio.get(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'format': 'jsonv2',
        'q': query,
        'limit': '1',
      },
      options: Options(headers: {
        'User-Agent': 'nivaas-mobile/1.0',
        'Accept': 'application/json',
      }),
    );

    if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
      final first = response.data[0];
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');
      if (lat != null && lng != null) {
        return GeocodingResult(
          lat: lat,
          lng: lng,
          displayName: first['display_name']?.toString() ?? query,
        );
      }
    }
  } catch (_) {
    // Silently fail - map will show default location
  }
  return null;
}

/// Search locations for autocomplete suggestions.
Future<List<GeocodingResult>> searchLocations(String query, {int limit = 6}) async {
  if (query.trim().isEmpty) return const [];

  try {
    final dio = Dio();
    final response = await dio.get(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'format': 'jsonv2',
        'q': query,
        'limit': limit.toString(),
      },
      options: Options(headers: {
        'User-Agent': 'nivaas-mobile/1.0',
        'Accept': 'application/json',
      }),
    );

    if (response.statusCode == 200 && response.data is List) {
      final list = response.data as List;
      return list
          .map((item) {
            final lat = double.tryParse(item['lat']?.toString() ?? '');
            final lng = double.tryParse(item['lon']?.toString() ?? '');
            if (lat == null || lng == null) return null;
            return GeocodingResult(
              lat: lat,
              lng: lng,
              displayName: item['display_name']?.toString() ?? query,
            );
          })
          .whereType<GeocodingResult>()
          .toList();
    }
  } catch (_) {}

  return const [];
}

/// Reverse geocode coordinates to a readable address.
Future<GeocodingResult?> reverseGeocodeLocation(double lat, double lng) async {
  try {
    final dio = Dio();
    final response = await dio.get(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'format': 'jsonv2',
        'lat': lat.toString(),
        'lon': lng.toString(),
      },
      options: Options(headers: {
        'User-Agent': 'nivaas-mobile/1.0',
        'Accept': 'application/json',
      }),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return GeocodingResult(
        lat: lat,
        lng: lng,
        displayName: data['display_name']?.toString() ?? '$lat, $lng',
      );
    }
  } catch (_) {}

  return null;
}
