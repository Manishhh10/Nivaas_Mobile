import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';
import 'package:nivaas/features/host/presentation/pages/host_apply_screen.dart';
import 'package:nivaas/features/host/presentation/pages/host_calendar_screen.dart';
import 'package:nivaas/features/host/presentation/pages/host_listings_screen.dart';
import 'package:nivaas/features/host/presentation/pages/host_messages_screen.dart';
import 'package:nivaas/features/host/presentation/pages/host_today_screen.dart';

class HostDashboardData {
  final String hostName;
  final int listings;
  final int experiences;
  final int reservationsToday;
  final int upcomingReservations;
  final int pendingRequests;
  final int unreadMessages;
  final List<Map<String, dynamic>> nextReservations;

  const HostDashboardData({
    required this.hostName,
    required this.listings,
    required this.experiences,
    required this.reservationsToday,
    required this.upcomingReservations,
    required this.pendingRequests,
    required this.unreadMessages,
    required this.nextReservations,
  });
}

final hostDashboardDataProvider = FutureProvider<HostDashboardData>((ref) async {
  final api = ref.read(apiClientProvider);

  final verifyRes = await api.get(ApiEndpoints.verify);
  final verify = VerifyResponse.fromJson(verifyRes.data);

  final listingsRes = await api.get(ApiEndpoints.hostListings);
  final listingItems =
      listingsRes.data['listings'] as List? ?? listingsRes.data['data'] as List? ?? [];

  final experiencesRes = await api.get(ApiEndpoints.hostExperiences);
  final experienceItems =
      experiencesRes.data['experiences'] as List? ?? experiencesRes.data['data'] as List? ?? [];

  final reservationsRes = await api.get(ApiEndpoints.hostReservations);
  final reservationItems =
      reservationsRes.data['reservations'] as List? ??
      reservationsRes.data['data'] as List? ??
      [];

  final conversationsRes = await api.get('${ApiEndpoints.conversations}?mode=host');
  final conversationItems =
      conversationsRes.data['conversations'] as List? ??
      conversationsRes.data['data'] as List? ??
      [];

  final today = DateTime.now();
  final dayStart = DateTime(today.year, today.month, today.day);

  int reservationsToday = 0;
  int upcomingReservations = 0;
  int pendingRequests = 0;

  final reservations = reservationItems
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  for (final reservation in reservations) {
    final start = DateTime.tryParse(reservation['startDate']?.toString() ?? '');
    final end = DateTime.tryParse(reservation['endDate']?.toString() ?? '');
    final status = (reservation['status'] ?? '').toString().toLowerCase();

    if (status == 'pending') {
      pendingRequests += 1;
    }

    if (start == null || end == null) continue;

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    if ((startDay.isBefore(dayStart) || startDay.isAtSameMomentAs(dayStart)) &&
        (endDay.isAfter(dayStart) || endDay.isAtSameMomentAs(dayStart))) {
      reservationsToday += 1;
    }

    if (startDay.isAfter(dayStart)) {
      upcomingReservations += 1;
    }
  }

  final unreadMessages = conversationItems.whereType<Map>().fold<int>(0, (sum, item) {
    final unread = int.tryParse(item['unreadCount']?.toString() ?? '0') ?? 0;
    return sum + unread;
  });

  reservations.sort((a, b) {
    final aTime = DateTime.tryParse(a['startDate']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;
    final bTime = DateTime.tryParse(b['startDate']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;
    return aTime.compareTo(bTime);
  });

  return HostDashboardData(
    hostName: verify.user?.name.isNotEmpty == true ? verify.user!.name : 'Host',
    listings: listingItems.length,
    experiences: experienceItems.length,
    reservationsToday: reservationsToday,
    upcomingReservations: upcomingReservations,
    pendingRequests: pendingRequests,
    unreadMessages: unreadMessages,
    nextReservations: reservations.take(5).toList(),
  );
});

class HostStatsDashboardScreen extends ConsumerWidget {
  const HostStatsDashboardScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifyAsync = ref.watch(verifyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Dashboard'),
        elevation: 0,
      ),
      body: verifyAsync.when(
        data: (verify) {
          final hostStatus = verify.hostStatus;
          if (hostStatus == null || hostStatus.isVerifiedHost != true) {
            return _notVerifiedView(context, ref, hostStatus);
          }

          final dashboardAsync = ref.watch(hostDashboardDataProvider);
          return dashboardAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: primaryOrange),
            ),
            error: (_, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Could not load host dashboard'),
                  TextButton(
                    onPressed: () => ref.invalidate(hostDashboardDataProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (data) => RefreshIndicator(
              color: primaryOrange,
              onRefresh: () async {
                ref.invalidate(hostDashboardDataProvider);
              },
              child: _dashboardBody(context, data),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryOrange),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Could not load host status'),
              TextButton(
                onPressed: () => ref.invalidate(verifyProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardBody(BuildContext context, HostDashboardData data) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome back, ${data.hostName}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is your hosting summary.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.72)),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            _hostStatCard(context, 'Listings', data.listings),
            _hostStatCard(context, 'Experiences', data.experiences),
            _hostStatCard(context, 'Today', data.reservationsToday),
            _hostStatCard(context, 'Upcoming', data.upcomingReservations),
            _hostStatCard(context, 'Pending', data.pendingRequests),
            _hostStatCard(context, 'Unread', data.unreadMessages),
          ],
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          title: 'Quick actions',
          child: Column(
            children: [
              _actionTile(
                context,
                icon: Icons.today_outlined,
                title: 'Open Today',
                subtitle: 'View today and upcoming reservations',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HostTodayScreen()),
                ),
              ),
              _actionTile(
                context,
                icon: Icons.calendar_month_outlined,
                title: 'Open Calendar',
                subtitle: 'See your reservations by date',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HostCalendarScreen()),
                ),
              ),
              _actionTile(
                context,
                icon: Icons.list_alt_outlined,
                title: 'Manage listings',
                subtitle: 'Edit stays and experiences',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HostListingsScreen()),
                ),
              ),
              _actionTile(
                context,
                icon: Icons.chat_bubble_outline,
                title: 'Check messages',
                subtitle: 'Reply to guests quickly',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HostMessagesScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          title: 'Next reservations',
          child: data.nextReservations.isEmpty
              ? Text(
                  'No reservations yet.',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.65)),
                )
              : Column(
                  children: data.nextReservations
                      .map((reservation) => _reservationTile(context, reservation))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _hostStatCard(BuildContext context, String label, int value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
          const Spacer(),
          Text(
            value.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
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
            child,
          ],
        ),
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

  Widget _reservationTile(BuildContext context, Map<String, dynamic> reservation) {
    final isStay = reservation['accommodationId'] != null;
    final item = isStay ? reservation['accommodationId'] : reservation['experienceId'];
    final itemMap = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
    final title = itemMap['title']?.toString() ?? 'Reservation';
    final guestMap = reservation['userId'] is Map
        ? Map<String, dynamic>.from(reservation['userId'] as Map)
        : <String, dynamic>{};
    final guestName = guestMap['name']?.toString() ?? 'Guest';
    final status = reservation['status']?.toString() ?? 'pending';
    final startDate =
        DateTime.tryParse(reservation['startDate']?.toString() ?? '') ?? DateTime.now();

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStay ? 'Stay' : 'Experience',
                  style: const TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text('Guest: $guestName'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(status, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${startDate.month}/${startDate.day}/${startDate.year}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notVerifiedView(BuildContext context, WidgetRef ref, HostStatus? hostStatus) {
    final status = hostStatus?.status.toLowerCase() ?? 'none';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pending' ? Icons.hourglass_empty : Icons.add_home,
              size: 64,
              color: status == 'pending' ? Colors.orange : primaryOrange,
            ),
            const SizedBox(height: 20),
            Text(
              status == 'pending'
                  ? 'Your host application is being reviewed'
                  : status == 'rejected'
                      ? 'Your host application was rejected'
                      : 'Become a Nivaas Host',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              status == 'pending'
                  ? 'We will notify you once your verification is complete.'
                  : status == 'rejected'
                      ? hostStatus?.rejectionReason ??
                          'Please contact support for details.'
                      : 'Share your space or experiences with travelers from around the world.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            if (status != 'pending') ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HostApplyScreen()),
                  );
                  ref.invalidate(verifyProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(status == 'rejected' ? 'Reapply' : 'Apply Now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
