import 'package:flutter/material.dart';
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile model
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar

class ProfileCard extends StatelessWidget {
  final UserProfile? initialProfileData;
  final String? authUid;

  const ProfileCard({
    super.key,
    this.initialProfileData,
    this.authUid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center align content
          children: [
            DefaultAvatar(
              radius: 40,
              avatarUrl: initialProfileData?.avatarUrl,
              name: initialProfileData?.displayName ?? initialProfileData?.username,
            ),
            const SizedBox(height: 8),
            Text(
              initialProfileData?.displayName ?? initialProfileData?.username ?? 'User',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24), // Increased spacing
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Display Name',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                initialProfileData?.displayName ?? initialProfileData?.username ?? 'User',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Username',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '@${initialProfileData?.username ?? 'No username'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: initialProfileData?.email ?? 'No email'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.mail_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bio',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                initialProfileData?.bio ?? 'No bio available.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}