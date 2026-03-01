import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';

class WishlistNotifier extends Notifier<Set<String>> {
  static const String _boxName = 'wishlist_box';
  Box? _box;

  @override
  Set<String> build() {
    _init();
    return {};
  }

  Future<void> _init() async {
    // Load cached items first for instant display
    _box = await Hive.openBox(_boxName);
    final saved = _box!.get('items', defaultValue: <dynamic>[]);
    state = Set<String>.from(saved);

    // Then sync from backend
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get(ApiEndpoints.wishlist);
      final list = response.data['data'] as List? ?? [];
      state = Set<String>.from(list.map((e) => e.toString()));
      _box?.put('items', state.toList());
    } catch (_) {
      // Offline – keep cached data
    }
  }

  Future<void> toggle(String itemId) async {
    // Optimistically update UI
    if (state.contains(itemId)) {
      state = Set<String>.from(state)..remove(itemId);
    } else {
      state = {...state, itemId};
    }
    _box?.put('items', state.toList());

    // Sync with backend
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
        ApiEndpoints.wishlistToggle,
        data: {'itemId': itemId},
      );
      final list = response.data['data'] as List? ?? [];
      state = Set<String>.from(list.map((e) => e.toString()));
      _box?.put('items', state.toList());
    } catch (_) {
      // If backend fails, keep optimistic state (will sync on next load)
    }
  }

  bool isWishlisted(String itemId) => state.contains(itemId);
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, Set<String>>(WishlistNotifier.new);
