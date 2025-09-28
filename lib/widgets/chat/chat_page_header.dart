import 'package:flutter/material.dart';
import 'package:bharatconnect/models/aura_models.dart'; // Import UserAura from aura_models.dart
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar

class ChatPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String contactName;
  final String? contactId;
  final String? contactAvatarUrl;
  final String contactStatusText;
  final UserAura? contactActiveAura; // Add UserAura parameter
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
    this.contactActiveAura, // Initialize UserAura parameter
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
            // Replaced CircleAvatar with DefaultAvatar and added aura ring logic
            Stack(
              alignment: Alignment.center,
              children: [
                if (contactActiveAura != null)
                  Container(
                    width: 40, // Slightly larger than avatar for the ring
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          contactActiveAura!.primaryColor,
                          contactActiveAura!.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                DefaultAvatar(
                  radius: 18, // Slightly reduced radius for smaller profile picture
                  avatarUrl: contactAvatarUrl,
                  name: contactName, // Pass contactName for default avatar
                ),
              ],
            ),
            const SizedBox(width: 6), // Reduced width for smaller gap
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      contactName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (contactActiveAura != null) ...[
                      const SizedBox(width: 4), // Small space between name and aura
                      Image.asset(
                        contactActiveAura!.iconUrl, // Corrected from iconPath to iconUrl
                        height: 18, // Adjust size as needed
                        width: 18,
                      ),
                    ],
                  ],
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