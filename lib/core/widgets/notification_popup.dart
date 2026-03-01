import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/features/notifications/presentation/pages/notifications_screen.dart';

/// A popup overlay that shows the latest notifications with a "See all" link.
class NotificationPopup extends ConsumerWidget {
  const NotificationPopup({super.key});

  static const Color primaryOrange = Color(0xFFFF6518);

  /// Show as a modal bottom sheet from any context.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationPopupSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}

class _NotificationPopupSheet extends ConsumerWidget {
  const _NotificationPopupSheet();

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      final api = ApiClient();
                      await api.put(ApiEndpoints.markAllNotificationsRead);
                      ref.invalidate(notificationsProvider);
                    } catch (_) {}
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: primaryOrange, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No notifications',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }
                final displayCount =
                    notifications.length > 5 ? 5 : notifications.length;
                return ListView.separated(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  itemCount: displayCount,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _notifTile(context, ref, notifications[i]),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child:
                        CircularProgressIndicator(color: primaryOrange)),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Failed to load notifications')),
              ),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: InkWell(
              onTap: () {
                Navigator.pop(context); // close popup
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(
                    'See all notifications',
                    style: TextStyle(
                      color: primaryOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifTile(
      BuildContext context, WidgetRef ref, Map<String, dynamic> notif) {
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
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
          color: isRead ? Colors.black54 : Colors.black87,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          Text(timeAgo, style: const TextStyle(fontSize: 11, color: Colors.black38)),
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
            await api.put(ApiEndpoints.markNotificationRead(id));
            ref.invalidate(notificationsProvider);
          } catch (_) {}
        }
      },
    );
  }
}
