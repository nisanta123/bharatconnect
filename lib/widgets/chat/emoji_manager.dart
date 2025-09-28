import 'package:flutter/material.dart';

class EmojiManager {
  bool isEmojiOpen = false;
  final FocusNode inputFocusNode;

  EmojiManager(this.inputFocusNode);

  void toggleEmojiPicker(VoidCallback onChange) {
    if (isEmojiOpen) {
      // If emoji picker is open → show keyboard
      isEmojiOpen = false;
      inputFocusNode.requestFocus();
    } else {
      // If keyboard is open → close it, show emoji picker
      isEmojiOpen = true;
      inputFocusNode.unfocus();
    }
    onChange();
  }

  void closeEmojiPicker(VoidCallback onChange) {
    if (isEmojiOpen) {
      isEmojiOpen = false;
      onChange();
    }
  }
}