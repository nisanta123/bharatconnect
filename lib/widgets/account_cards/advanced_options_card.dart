import 'package:flutter/material.dart';

class AdvancedOptionsCard extends StatelessWidget {
  const AdvancedOptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.settings_applications),
              title: const Text('Configure advanced settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                print('Navigate to advanced options');
              },
            ),
          ],
        ),
      ),
    );
  }
}