import 'package:flutter/material.dart';

class EncryptedChatBanner extends StatelessWidget {
  const EncryptedChatBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical padding for spacing
        child: Chip(
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0), // Smaller horizontal padding
          side: BorderSide(color: Theme.of(context).colorScheme.secondary.withOpacity(0.4), width: 0.5), // Smaller border
          label: Row(
            mainAxisSize: MainAxisSize.min, // Ensure row takes minimum space
            children: <Widget>[
              Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.secondary), // Smaller icon
              const SizedBox(width: 6), // Smaller spacing
              Text(
                'Messages are end-to-end encrypted',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}