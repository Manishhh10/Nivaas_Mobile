import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/messages/presentation/pages/messages_screen.dart';

final hostConversationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiEndpoints.conversations}?mode=host');
  final list = response.data['conversations'] as List? ??
      response.data['data'] as List? ??
      [];
  return list.cast<Map<String, dynamic>>();
});

/// Host‑mode messages tab – re‑uses the existing conversation/thread logic
/// but strips the standalone AppBar so it feels native inside the host shell.
class HostMessagesScreen extends ConsumerWidget {
  const HostMessagesScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final conversationsAsync = ref.watch(hostConversationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Messages',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: RefreshIndicator(
                color: primaryOrange,
                onRefresh: () async => ref.invalidate(hostConversationsProvider),
                child: conversationsAsync.when(
                  data: (conversations) {
                    if (conversations.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(height: 120),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 56, color: colorScheme.onSurfaceVariant),
                                SizedBox(height: 12),
                                Text('No conversations yet',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text('Messages from guests will appear here',
                                    style: TextStyle(
                                        color: colorScheme.onSurfaceVariant, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: conversations.length,
                          separatorBuilder: (_, _) =>
                          Divider(height: 1, color: colorScheme.outline.withOpacity(0.25)),
                      itemBuilder: (_, i) =>
                          _conversationTile(context, ref, conversations[i]),
                    );
                  },
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: primaryOrange)),
                      error: (_, _) =>
                      const Center(child: Text('Error loading messages')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversationTile(
      BuildContext context, WidgetRef ref, Map<String, dynamic> convo) {
    final counterpart = convo['counterpart'] as Map<String, dynamic>? ?? {};
    final name = counterpart['name'] as String? ?? 'Guest';
    final image = counterpart['image'] as String? ?? '';
    final contextTitle = (convo['contextTitle'] ?? '').toString();
    final lastMsg = convo['lastMessage'] as String? ?? '';
    final unread = (convo['unreadCount'] as num?)?.toInt() ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: primaryOrange.withValues(alpha: 0.1),
        child: image.isNotEmpty
            ? ClipOval(
                child: NivaasImage(imagePath: image, width: 48, height: 48))
            : Text(name.isNotEmpty ? name[0].toUpperCase() : 'G',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: primaryOrange)),
      ),
      title: Text(name,
          style: TextStyle(
              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contextTitle.isNotEmpty)
            Text(
              contextTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFF6518),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: unread > 0
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight:
                      unread > 0 ? FontWeight.w500 : FontWeight.normal)),
        ],
      ),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: primaryOrange, shape: BoxShape.circle),
              child: Text('$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            )
          : null,
      onTap: () {
        // Reuse full chat screen so host can send messages too
        final recipientId = counterpart['_id'] as String? ?? '';
        if (recipientId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                recipientId: recipientId,
                recipientName: name,
              ),
            ),
          );
        }
      },
    );
  }
}
