import 'package:flutter/material.dart';
import 'package:bharatconnect/models/chat_models.dart'; // For Chat model

class ChatItem extends StatelessWidget {
  final Chat chat;
  final String currentUserId;

  const ChatItem({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final contactUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final contactInfo = chat.participantInfo[contactUserId];

    String displayName = contactInfo?.name ?? 'Unknown';
    String? avatarUrl = contactInfo?.avatarUrl;
    String lastMessageText = chat.lastMessage?.text ?? '';
    String timeAgo = ''; // TODO: Implement time formatting

    // Determine if the chat has unread messages from others
    final bool hasUnread = chat.lastMessage != null &&
        chat.lastMessage!.senderId != currentUserId &&
        !chat.lastMessage!.readBy.contains(currentUserId);

    return ListTile(
      leading: CircleAvatar(
        radius: 28, // Same as chat list screen
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.white, size: 35)
            : null,
      ),
      title: Text(
        displayName,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              color: Theme.of(context).colorScheme.onBackground,
            ),
      ),
      subtitle: Text(
        lastMessageText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hasUnread ? Theme.of(context).colorScheme.onBackground : Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeAgo, // Display formatted time
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: hasUnread ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(), // Display actual unread count
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: () {
        print('Open chat with $displayName');
        // TODO: Navigate to ChatPage
      },
    );
  }
}