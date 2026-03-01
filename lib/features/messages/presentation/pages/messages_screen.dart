import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';

// Thread messages provider (takes recipientId as param)
final threadMessagesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, recipientId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('${ApiEndpoints.messageThread}?counterpartId=$recipientId');
  final list = response.data['messages'] as List? ?? response.data['data'] as List? ?? [];
  return list.cast<Map<String, dynamic>>();
});

// ─── Conversations List Screen ───

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: primaryOrange,
        onRefresh: () async => ref.invalidate(conversationsProvider),
        child: conversationsAsync.when(
          data: (conversations) {
            if (conversations.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 56, color: colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('No conversations yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Start a conversation with a host',
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.68))),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _conversationTile(context, conversations[i]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: primaryOrange)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _conversationTile(BuildContext context, Map<String, dynamic> conv) {
    final counterpart = conv['counterpart'] as Map<String, dynamic>? ?? {};
    final name = counterpart['name']?.toString() ?? 'User';

    String readImageValue(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) {
        final asMap = Map<String, dynamic>.from(value);
        return asMap['url']?.toString() ??
            asMap['path']?.toString() ??
            asMap['image']?.toString() ??
            asMap['secure_url']?.toString() ??
            '';
      }
      return '';
    }

    final avatarCandidates = [
      counterpart['image'],
      counterpart['avatar'],
      counterpart['profileImage'],
      counterpart['photo'],
      conv['counterpartImage'],
      conv['senderImage'],
      conv['recipientImage'],
      (conv['senderId'] is Map) ? (conv['senderId'] as Map)['image'] : null,
      (conv['recipientId'] is Map) ? (conv['recipientId'] as Map)['image'] : null,
    ];
    final avatar = avatarCandidates
        .map(readImageValue)
        .firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');

    final lastMessage = conv['lastMessage']?.toString() ?? '';
    final unread = conv['unreadCount'] as int? ?? 0;
    final recipientId = counterpart['_id']?.toString() ?? '';

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: avatar.isNotEmpty
            ? NivaasImage(imagePath: avatar, width: 48, height: 48)
            : CircleAvatar(
                radius: 24,
                backgroundColor: primaryOrange.withOpacity(0.1),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: primaryOrange, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(lastMessage,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: unread > 0 ? onSurface : onSurface.withOpacity(0.65),
            fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
          )),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: primaryOrange, shape: BoxShape.circle),
              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          : null,
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ChatScreen(recipientId: recipientId, recipientName: name)));
      },
    );
  }
}

// ─── Chat / Thread Screen ───

class ChatScreen extends ConsumerStatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  final _msgController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final api = ApiClient();
      await api.post(ApiEndpoints.sendMessage, data: {
        'recipientId': widget.recipientId,
        'text': text,
      });
      _msgController.clear();
      ref.invalidate(threadMessagesProvider(widget.recipientId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(threadMessagesProvider(widget.recipientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: threadAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hi!', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    // Messages come newest first from API; if not, reverse
                    final msg = messages[messages.length - 1 - i];
                    final isMine = msg['senderId']?.toString() != widget.recipientId;
                    return _messageBubble(msg, isMine);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: primaryOrange)),
              error: (e, _) => Center(child: Text('Error loading messages')),
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> msg, bool isMine) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? primaryOrange : colorScheme.surface,
          border: isMine ? null : Border.all(color: colorScheme.outline.withOpacity(0.25)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMine ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMine ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          msg['text']?.toString() ?? '',
          style: TextStyle(
            color: isMine ? Colors.white : colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.25))),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sending ? null : _sendMessage,
            icon: _sending
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: primaryOrange, strokeWidth: 2))
                : const Icon(Icons.send, color: primaryOrange),
          ),
        ],
      ),
    );
  }
}
