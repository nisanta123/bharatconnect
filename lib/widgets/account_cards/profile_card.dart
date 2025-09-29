import 'package:flutter/material.dart';
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile model
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar
import 'package:bharatconnect/screens/edit_profile_screen.dart';
import 'package:bharatconnect/widgets/custom_toast.dart';

class ProfileCard extends StatelessWidget {
  final UserProfile? initialProfileData;
  final String? authUid;
  final VoidCallback? onProfileUpdated;

  const ProfileCard({
    super.key,
    this.initialProfileData,
    this.authUid,
    this.onProfileUpdated,
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
            const SizedBox(height: 16),
            if (initialProfileData != null && authUid != null && initialProfileData!.id == authUid)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditProfileScreen(initialProfile: initialProfileData!)));
                        if (result == true) {
                          // If profile was updated, notify parent to refresh and show a custom toast
                          if (context.mounted) showCustomToast(context, 'Profile updated');
                          if (onProfileUpdated != null) onProfileUpdated!();
                        }
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit profile'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}