import 'package:flutter/material.dart';
import 'package:bharatconnect/models/chat_models.dart'; // For Chat and User models
import 'package:bharatconnect/models/search_models.dart'; // For User model

class ChatRequestDisplay extends StatelessWidget {
  final Chat chatDetails;
  final User contact;
  final String currentUserId;
  final VoidCallback onAcceptRequest;
  final VoidCallback onRejectRequest;
  final VoidCallback onCancelRequest;
  final bool isProcessing;

  const ChatRequestDisplay({
    super.key,
    required this.chatDetails,
    required this.contact,
    required this.currentUserId,
    required this.onAcceptRequest,
    required this.onRejectRequest,
    required this.onCancelRequest,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRequester = chatDetails.requesterId == currentUserId;
    final isAwaitingAction = chatDetails.requestStatus == ChatRequestStatus.awaiting_action;

    String titleText;
    String messageText;
    Widget actionButtons;

    if (isRequester) {
      titleText = 'Request Sent';
      messageText = 'You sent a chat request to ${contact.name}. Waiting for their approval.';
      actionButtons = ElevatedButton(
        onPressed: isProcessing ? null : onCancelRequest,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Cancel Request'),
      );
    } else if (isAwaitingAction) {
      titleText = 'Chat Request';
      messageText = '${contact.name} wants to connect with you.';
      actionButtons = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: isProcessing ? null : onAcceptRequest,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Accept'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton(
              onPressed: isProcessing ? null : onRejectRequest,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
              child: isProcessing ? const CircularProgressIndicator(color: Colors.redAccent) : const Text('Reject'),
            ),
          ),
        ],
      );
    } else {
      // Rejected or other unexpected status
      titleText = 'Chat Request';
      messageText = 'This chat request is no longer active or has been rejected.';
      actionButtons = ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop(); // Go back to chat list
        },
        child: const Text('Go to Chats'),
      );
    }

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add, size: 60, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                titleText,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                messageText,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              actionButtons,
            ],
          ),
        ),
      ),
    );
  }
}