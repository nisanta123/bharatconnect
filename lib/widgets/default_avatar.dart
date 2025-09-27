import 'package:flutter/material.dart';

class DefaultAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final double radius;

  const DefaultAvatar({
    super.key,
    this.avatarUrl,
    this.name,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Muted background
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Icon(Icons.person, size: radius, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
          : null,
    );
  }
}
