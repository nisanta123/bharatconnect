import 'package:flutter/material.dart';

class ChatInputZone extends StatelessWidget {
  final String newMessage;
  final ValueChanged<String> onNewMessageChange;
  final VoidCallback onSendMessage;
  final VoidCallback onToggleEmojiPicker;
  final bool isEmojiPickerOpen;
  final ValueChanged<dynamic> onFileSelect; // Placeholder for File
  final TextEditingController? textareaRef; // Placeholder for TextEditingController
  final bool isDisabled;
  final bool justSelectedEmoji;
  final String? filePreviewUrl;
  final VoidCallback onClearFileSelection;

  const ChatInputZone({
    super.key,
    required this.newMessage,
    required this.onNewMessageChange,
    required this.onSendMessage,
    required this.onToggleEmojiPicker,
    required this.isEmojiPickerOpen,
    required this.onFileSelect,
    this.textareaRef,
    this.isDisabled = false,
    this.justSelectedEmoji = false,
    this.filePreviewUrl,
    required this.onClearFileSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          if (filePreviewUrl != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  // Placeholder for image preview
                  const Icon(Icons.image, size: 40, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClearFileSelection,
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(isEmojiPickerOpen ? Icons.keyboard : Icons.emoji_emotions),
                onPressed: onToggleEmojiPicker,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: isDisabled ? null : () => print('Attach file'), // TODO: Implement file picker
                color: Theme.of(context).colorScheme.onSurface,
              ),
              Expanded(
                child: TextField(
                  controller: textareaRef, // Use the provided controller
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                  onChanged: onNewMessageChange,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !isDisabled,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                onPressed: isDisabled || (newMessage.isEmpty && filePreviewUrl == null) ? null : onSendMessage,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}