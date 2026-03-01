import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Notifications',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        final api = ApiClient();
                        await api.patch(ApiEndpoints.markAllNotificationsRead);
                        ref.invalidate(notificationsProvider);
                      } catch (_) {}
                    },
                    child: const Text('Mark all read',
                        style: TextStyle(color: primaryOrange, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: primaryOrange,
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: notificationsAsync.when(
                  data: (notifications) {
                    if (notifications.isEmpty) return _emptyState();
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _notificationTile(context, ref, notifications[i]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: primaryOrange)),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 48, color: colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('Failed to load notifications'),
                        TextButton(
                          onPressed: () => ref.invalidate(notificationsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationTile(BuildContext context, WidgetRef ref, Map<String, dynamic> notif) {
    final isRead = notif['isRead'] == true;
    final type = notif['type']?.toString() ?? '';
    final message = notif['message']?.toString() ?? '';
    final createdAt = notif['createdAt']?.toString() ?? '';
    final id = notif['_id']?.toString() ?? '';

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'booking':
        icon = Icons.calendar_today;
        iconColor = Colors.blue;
        break;
      case 'payment':
        icon = Icons.payment;
        iconColor = Colors.green;
        break;
      case 'host':
        icon = Icons.home_work;
        iconColor = primaryOrange;
        break;
      case 'review':
        icon = Icons.star;
        iconColor = Colors.amber;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    String timeAgo = '';
    final date = DateTime.tryParse(createdAt);
    if (date != null) {
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}m ago';
      } else {
        timeAgo = 'Just now';
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
          color: isRead
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.72)
              : Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        timeAgo,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: primaryOrange,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () async {
        if (!isRead && id.isNotEmpty) {
          try {
            final api = ApiClient();
            await api.patch(ApiEndpoints.markNotificationRead(id));
            ref.invalidate(notificationsProvider);
          } catch (_) {}
        }
      },
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('You\'re all caught up!', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }
}
