import 'package:flutter/material.dart';

class EmojiPicker extends StatelessWidget {
  final ValueChanged<String> onEmojiSelect;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelect,
  });

  @override
  Widget build(BuildContext context) {
    // This is a placeholder for a real emoji picker.
    // In a real app, you would use a package like 'emoji_picker_flutter'.
    return Container(
      height: 200, // Fixed height for now
      color: Theme.of(context).cardColor, // Background color for the picker
      child: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8, // Number of emojis per row
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: _mockEmojis.length,
        itemBuilder: (context, index) {
          final emoji = _mockEmojis[index];
          return GestureDetector(
            onTap: () => onEmojiSelect(emoji),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }

  static const List<String> _mockEmojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣',
    '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
    '😘', '😗', '😙', '😚', '😋', '😛', '😜', '🤪',
    '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
    '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
    '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
    '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯',
  ];
}