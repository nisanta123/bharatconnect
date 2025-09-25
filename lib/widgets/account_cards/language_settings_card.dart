import 'package:flutter/material.dart';

class LanguageSettingsCard extends StatelessWidget {
  const LanguageSettingsCard({super.key});

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
              'Language Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Change app language'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                print('Navigate to language settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}