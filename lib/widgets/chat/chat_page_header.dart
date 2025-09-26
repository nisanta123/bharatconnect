import 'package:flutter/material.dart';

class ChatPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String contactName;
  final String? contactId;
  final String? contactAvatarUrl;
  final String contactStatusText;
  final String? contactAuraIconUrl;
  final String? contactAuraName;
  final bool isChatActive;
  final VoidCallback onMoreOptionsClick;

  const ChatPageHeader({
    super.key,
    required this.contactName,
    this.contactId,
    this.contactAvatarUrl,
    required this.contactStatusText,
    this.contactAuraIconUrl,
    this.contactAuraName,
    required this.isChatActive,
    required this.onMoreOptionsClick,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 40, // Reduced leadingWidth to shift back button more to the left
      titleSpacing: 4, // Reduced titleSpacing to decrease gap from profile picture
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: GestureDetector(
        onTap: () {
          print('View contact profile');
          // TODO: Navigate to contact profile
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 18, // Slightly reduced radius for smaller profile picture
              backgroundImage: contactAvatarUrl != null && contactAvatarUrl!.isNotEmpty
                  ? NetworkImage(contactAvatarUrl!)
                  : null,
              child: contactAvatarUrl == null || contactAvatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 22) // Adjusted icon size
                  : null,
            ),
            const SizedBox(width: 6), // Reduced width for smaller gap
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contactName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  contactStatusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {
            print('Video call');
          },
        ),
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () {
            print('Voice call');
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMoreOptionsClick,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}