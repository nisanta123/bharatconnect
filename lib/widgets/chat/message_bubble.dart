import 'package:flutter/material.dart';
import 'package:bharatconnect/models/chat_models.dart';
import 'package:bharatconnect/services/encryption_service.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final double maxBubbleWidth;
  final EncryptionService encryptionService;
  final String currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.maxBubbleWidth,
    required this.encryptionService,
    required this.currentUserId,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String? _decryptedText;

  @override
  void initState() {
    super.initState();
    _decryptedText = widget.message.decryptedText;
    if (widget.message.encryptedText != null && _decryptedText == null) {
      _decryptMessage();
    }
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-evaluate decryption if the encrypted content or message ID has truly changed.
    // This prevents unnecessary 'Decrypting...' flickers for stable messages.
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.encryptedText != widget.message.encryptedText) {
      _decryptedText = widget.message.decryptedText; // Reset to cached value
      if (widget.message.encryptedText != null && _decryptedText == null) {
        _decryptMessage();
      }
    } else if (widget.message.decryptedText != null && _decryptedText == null) {
      // If the message was just decrypted (e.g., by another MessageBubble instance caching it),
      // update the state to reflect the decrypted text without re-decrypting.
      setState(() {
        _decryptedText = widget.message.decryptedText;
      });
    }
  }

  Future<void> _decryptMessage() async {
    // If already decrypted (either locally or from cache), or it's a plain text message, no need to decrypt.
    if (_decryptedText != null || widget.message.encryptedText == null) {
      if (mounted) {
        setState(() {
          _decryptedText = _decryptedText ?? widget.message.text; // Ensure plain text is shown if no encryption
        });
      }
      return;
    }

    // If it's an encrypted message and not yet decrypted, proceed with decryption.
    try {
      final decrypted = await widget.encryptionService.decryptMessage(
        widget.message.toFirestoreMap(),
        widget.currentUserId,
      );
      if (mounted) {
        setState(() {
          _decryptedText = decrypted;
          widget.message.decryptedText = decrypted; // Cache the decrypted text in the message object
        });
      }
    } catch (e) {
      print('Error decrypting message in MessageBubble: $e');
      if (mounted) {
        setState(() {
          _decryptedText = 'Error decrypting';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEncryptedAndNotDecrypted = widget.message.encryptedText != null && _decryptedText == null;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxBubbleWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: widget.isMe ? null : Colors.grey[800],
            borderRadius: BorderRadius.circular(12.0),
            gradient: widget.isMe
                ? const LinearGradient(
                    colors: [
                      Color(0xFF42A5F5),
                      Color(0xFFAB47BC),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: isEncryptedAndNotDecrypted
              ? Text('Decrypting...', style: TextStyle(color: widget.isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface))
              : Text(
                  _decryptedText ?? widget.message.text ?? '', // Display decrypted text, or plain text, or empty
                  style: TextStyle(color: widget.isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                ),
        ),
      ),
    );
  }
}
