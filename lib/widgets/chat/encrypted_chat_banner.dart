import 'package:flutter/material.dart';

class EncryptedChatBanner extends StatelessWidget {
  const EncryptedChatBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Theme.of(context).colorScheme.secondary.withOpacity(0.2), // Subtle accent background
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.lock, size: 18, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Text(
            'Messages are end-to-end encrypted',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}