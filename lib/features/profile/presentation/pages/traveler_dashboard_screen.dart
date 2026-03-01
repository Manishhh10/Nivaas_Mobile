import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';
import 'package:nivaas/features/messages/presentation/pages/messages_screen.dart';
import 'package:nivaas/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:nivaas/features/trips/presentation/pages/trips_screen.dart';
import 'package:nivaas/features/wishlist/presentation/pages/wishlist_screen.dart';

class TravelerDashboardData {
  final String userName;
  final int activeBookings;
  final int newMessages;
  final int savedPlaces;
  final int totalBookings;
  final int upcomingBookings;
  final int pastBookings;
  final int cancelledBookings;
  final List<Map<String, dynamic>> recentConversations;

  const TravelerDashboardData({
    required this.userName,
    required this.activeBookings,
    required this.newMessages,
    required this.savedPlaces,
    required this.totalBookings,
    required this.upcomingBookings,
    required this.pastBookings,
    required this.cancelledBookings,
    required this.recentConversations,
  });
}

final travelerDashboardProvider = FutureProvider<TravelerDashboardData>((
  ref,
) async {
  final api = ref.read(apiClientProvider);

  final verifyResponse = await api.get(ApiEndpoints.verify);
  final verify = VerifyResponse.fromJson(verifyResponse.data);
  final currentUserId = verify.user?.id ?? '';

  final bookingsResponse = await api.get(ApiEndpoints.bookings);
  final bookingList =
      bookingsResponse.data['data'] as List? ??
      bookingsResponse.data['bookings'] as List? ??
      [];

  final conversationsResponse = await api.get(ApiEndpoints.conversations);
  final conversationList =
      conversationsResponse.data['conversations'] as List? ??
      conversationsResponse.data['data'] as List? ??
      [];

  final wishlistResponse = await api.get(ApiEndpoints.wishlist);
  final wishlist = wishlistResponse.data['data'] as List? ?? [];

  final today = DateTime.now();

  final userBookings = bookingList.whereType<Map>().where((booking) {
    final rawUserId = booking['userId'];
    final bookingUserId = rawUserId is Map
        ? rawUserId['_id']?.toString() ?? rawUserId['id']?.toString() ?? ''
        : rawUserId?.toString() ?? '';
    return currentUserId.isEmpty || bookingUserId == currentUserId;
  }).map((e) => Map<String, dynamic>.from(e)).toList();

  int activeBookings = 0;
  int upcomingBookings = 0;
  int cancelledBookings = 0;

  for (final booking in userBookings) {
    final status = (booking['status'] ?? 'pending').toString().toLowerCase();
    final startDate = DateTime.tryParse(booking['startDate']?.toString() ?? '');
    final endDate = DateTime.tryParse(booking['endDate']?.toString() ?? '');

    if (status == 'cancelled') {
      cancelledBookings += 1;
      continue;
    }

    if (endDate != null && !endDate.isBefore(today)) {
      activeBookings += 1;
    }

    if (startDate != null && startDate.isAfter(today)) {
      upcomingBookings += 1;
    }
  }

  final pastBookings =
      (userBookings.length - upcomingBookings - cancelledBookings).clamp(
        0,
        userBookings.length,
      );

  final conversations = conversationList
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  final unreadMessages = conversations.fold<int>(0, (sum, conversation) {
    final unread = int.tryParse(conversation['unreadCount']?.toString() ?? '0');
    return sum + (unread ?? 0);
  });

  return TravelerDashboardData(
    userName: verify.user?.name.isNotEmpty == true ? verify.user!.name : 'Traveler',
    activeBookings: activeBookings,
    newMessages: unreadMessages,
    savedPlaces: wishlist.length,
    totalBookings: userBookings.length,
    upcomingBookings: upcomingBookings,
    pastBookings: pastBookings,
    cancelledBookings: cancelledBookings,
    recentConversations: conversations.take(4).toList(),
  );
});

class TravelerDashboardScreen extends ConsumerWidget {
  const TravelerDashboardScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(travelerDashboardProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traveler Dashboard'),
        elevation: 0,
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryOrange),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Could not load dashboard data'),
              TextButton(
                onPressed: () => ref.invalidate(travelerDashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          return RefreshIndicator(
            color: primaryOrange,
            onRefresh: () async => ref.invalidate(travelerDashboardProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Welcome back, ${data.userName}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here is your traveler overview.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 18),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _statCard(
                      context,
                      label: 'Active',
                      value: data.activeBookings,
                      icon: Icons.luggage_outlined,
                      tint: Colors.orange,
                    ),
                    _statCard(
                      context,
                      label: 'Messages',
                      value: data.newMessages,
                      icon: Icons.chat_bubble_outline,
                      tint: Colors.blue,
                    ),
                    _statCard(
                      context,
                      label: 'Saved',
                      value: data.savedPlaces,
                      icon: Icons.favorite_border,
                      tint: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _summaryCard(
                  context,
                  title: 'Booking breakdown',
                  rows: [
                    _summaryRow('Total bookings', data.totalBookings),
                    _summaryRow('Upcoming', data.upcomingBookings),
                    _summaryRow('Past', data.pastBookings),
                    _summaryRow('Cancelled', data.cancelledBookings),
                  ],
                ),
                const SizedBox(height: 14),
                _summaryCard(
                  context,
                  title: 'Quick actions',
                  rows: [
                    _actionTile(
                      context,
                      icon: Icons.luggage_outlined,
                      title: 'Trips',
                      subtitle: 'View your bookings and plans',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TripsScreen()),
                      ),
                    ),
                    _actionTile(
                      context,
                      icon: Icons.favorite_border,
                      title: 'Wishlist',
                      subtitle: 'Saved stays and experiences',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WishlistScreen()),
                      ),
                    ),
                    _actionTile(
                      context,
                      icon: Icons.chat_bubble_outline,
                      title: 'Messages',
                      subtitle: 'Continue your conversations',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConversationsScreen(),
                        ),
                      ),
                    ),
                    _actionTile(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Check updates and reminders',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _summaryCard(
                  context,
                  title: 'Recent conversations',
                  rows: data.recentConversations.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'No conversations yet.',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : data.recentConversations
                            .map((conversation) => _conversationTile(context, conversation))
                            .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String label,
    required int value,
    required IconData icon,
    required Color tint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const Spacer(),
          Text(
            value.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.68))),
        ],
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required List<Widget> rows,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: primaryOrange.withValues(alpha: 0.12),
        child: Icon(icon, color: primaryOrange, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  Widget _conversationTile(BuildContext context, Map<String, dynamic> conversation) {
    final counterpart =
        conversation['counterpart'] is Map
            ? Map<String, dynamic>.from(conversation['counterpart'] as Map)
            : <String, dynamic>{};
    final counterpartName =
        counterpart['name']?.toString().trim().isNotEmpty == true
            ? counterpart['name'].toString()
            : 'Host';
    final lastMessage =
        conversation['lastMessage']?.toString().trim().isNotEmpty == true
            ? conversation['lastMessage'].toString()
            : 'No message preview';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: primaryOrange.withValues(alpha: 0.14),
            child: Text(
              counterpartName[0].toUpperCase(),
              style: const TextStyle(
                color: primaryOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counterpartName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
