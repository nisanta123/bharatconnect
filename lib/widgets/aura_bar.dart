import 'package:flutter/material.dart';
import 'package:bharatconnect/models/aura_models.dart' as aura_models; // Alias aura_models
import 'package:bharatconnect/widgets/aura_ring_item.dart';
import 'package:collection/collection.dart'; // Add this import for firstWhereOrNull

class AuraBar extends StatelessWidget {
  final bool isLoading;
  final List<aura_models.DisplayAura> allDisplayAuras;
  final aura_models.AuraUser? currentUser; // Use AuraUser
  final List<String> connectedUserIds;

  const AuraBar({
    super.key,
    required this.isLoading,
    required this.allDisplayAuras,
    required this.currentUser,
    required this.connectedUserIds,
  });

  void handleCurrentUserAuraClick(BuildContext context) {
    // Implement navigation to aura-select or similar functionality
    print("Navigate to aura-select");
  }

  void handleOtherUserAuraClick(aura_models.DisplayAura aura) { // Use aura_models.DisplayAura
    print("View aura for: ${aura.userName}");
    // Potentially navigate to a view page: Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuraViewPage(aura: aura)));

  }

  @override
  Widget build(BuildContext context) {
    // Find the current user's aura from allDisplayAuras
    final aura_models.DisplayAura? currentUserAuraFromList = currentUser != null
        ? allDisplayAuras.firstWhereOrNull(
            (aura) => aura.userId == currentUser!.id,
          )
        : null;

    // Filter for connected users' auras, excluding the current user
    final connectedUsersAuras = isLoading || currentUser == null
        ? <aura_models.DisplayAura>[]
        : allDisplayAuras.where(
            (aura) =>
                aura.userId != currentUser!.id &&
                connectedUserIds.contains(aura.userId),
          ).toList();

    return Container(
      height: 100.0,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: isLoading ? 5 : (currentUser != null ? 1 : 0) + connectedUsersAuras.length,
        itemBuilder: (context, index) {
          if (isLoading) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                children: [
                  const Skeleton(width: 70, height: 70, shape: BoxShape.circle),
                  const SizedBox(height: 4.0),
                  const Skeleton(width: 50, height: 10, shape: BoxShape.rectangle),
                ],
              ),
            );
          } else if (currentUser != null && index == 0) {
            return AuraRingItem(
              user: currentUser!,
              activeAura: currentUserAuraFromList, // This is now nullable
              isCurrentUser: true,
              onClick: () => handleCurrentUserAuraClick(context),
            );
          } else {
            final aura = connectedUsersAuras[currentUser != null ? index - 1 : index];
            return AuraRingItem(
              user: aura_models.AuraUser( // Use AuraUser
                id: aura.userId,
                name: aura.userName,
                avatarUrl: aura.userProfileAvatarUrl,
              ),
              activeAura: aura,
              onClick: () => handleOtherUserAuraClick(aura),
            );
          }
        },
      ),
    );
  }
}

// Simple Skeleton Widget for loading states
class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final BoxShape shape;

  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(8.0) : null,
      ),
    );
  }
}