import 'package:flutter/material.dart';
import 'package:bharatconnect/models/aura_models.dart' as aura_models; // Alias aura_models

class AuraRingItem extends StatelessWidget {
  final aura_models.AuraUser user; // Use AuraUser
  final aura_models.DisplayAura? activeAura; // Use DisplayAura and make nullable
  final bool isCurrentUser;
  final VoidCallback onClick;

  const AuraRingItem({
    super.key,
    required this.user,
    this.activeAura,
    this.isCurrentUser = false,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: [
                // Aura Ring (simplified for now)
                Container(
                  width: 70,
                  height: 67, // Reduced from 68
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeAura != null ? Colors.purpleAccent : Colors.grey,
                      width: 2.0,
                    ),
                  ),
                  child: ClipOval(
                    child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? Image.network(
                            user.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40),
                          )
                        : const Icon(Icons.person, size: 40),
                  ),
                ),
                if (isCurrentUser && activeAura == null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 0.0), // Reduced from 1.0
            Text(
              user.name,
              style: Theme.of(context).textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}