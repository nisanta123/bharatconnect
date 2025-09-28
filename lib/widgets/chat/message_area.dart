import 'package:flutter/material.dart';
import 'package:bharatconnect/models/chat_models.dart'; // For Message model
import 'package:bharatconnect/services/encryption_service.dart'; // Import EncryptionService
import 'package:bharatconnect/widgets/chat/message_bubble.dart'; // Corrected import path for MessageBubble

class MessageArea extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final String? contactId;
  final bool isContactTyping;
  final ScrollController scrollController;
  final EdgeInsets? padding;
  final EncryptionService encryptionService; // Add this line

  const MessageArea({
    super.key,
    required this.messages,
    required this.currentUserId,
    this.contactId,
    required this.isContactTyping,
    required this.scrollController,
    this.padding,
    required this.encryptionService, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.85; // 85% of screen width

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // Hide scrollbar
      child: ListView.builder(
        controller: scrollController,
        reverse: true, // 🔑 newest message starts at bottom
        physics: const BouncingScrollPhysics(), // Add BouncingScrollPhysics
        padding: (padding ?? EdgeInsets.zero).copyWith(left: 8.0, right: 8.0), // Add horizontal padding
        itemCount: messages.length + (isContactTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < messages.length) {
            final message = messages[index];
            final isMe = message.senderId == currentUserId;
            return MessageBubble(
              key: ValueKey(message.id), // 🔑 avoids flicker on rebuild
              message: message,
              isMe: isMe,
              maxBubbleWidth: maxBubbleWidth,
              encryptionService: encryptionService,
              currentUserId: currentUserId,
            );
          } else if (isContactTyping) {
            // Typing indicator should appear at the very bottom (top of reversed list)
            return Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.85), // Constrain typing indicator width to 85%
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[800], // Consistent received message color
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Text(
                    'Typing...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}