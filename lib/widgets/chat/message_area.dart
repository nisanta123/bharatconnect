import 'package:flutter/material.dart';
import 'package:bharatconnect/models/chat_models.dart'; // For Message model

class MessageArea extends StatelessWidget { // Changed to StatelessWidget
  final List<Message> messages;
  final String currentUserId;
  final String? contactId;
  final double dynamicPaddingBottom;
  final bool isContactTyping;
  final ScrollController scrollController;

  const MessageArea({
    super.key,
    required this.messages,
    required this.currentUserId,
    this.contactId,
    required this.dynamicPaddingBottom,
    required this.isContactTyping,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.7; // 70% of screen width

    return Expanded(
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), // Hide scrollbar
        child: ListView.builder(
          controller: scrollController, // Assign the scroll controller
          padding: EdgeInsets.only(bottom: dynamicPaddingBottom),
          itemCount: messages.length + (isContactTyping ? 1 : 0), // Use messages.length
          itemBuilder: (context, index) {
            if (index < messages.length) {
              final message = messages[index];
              final isMe = message.senderId == currentUserId;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth), // Constrain message bubble width
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isMe ? null : Colors.grey[800], // Set received message color to slightly different gray
                      borderRadius: BorderRadius.circular(12.0),
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF42A5F5), // Primary Blue
                                Color(0xFFAB47BC), // Accent Violet
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null, // Apply gradient for own messages
                    ),
                    child: Text(
                      message.text ?? '',
                      style: TextStyle(color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
              );
            } else if (isContactTyping) {
              // Typing indicator
              return Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7), // Constrain typing indicator width
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
      ),
    );
  }
}