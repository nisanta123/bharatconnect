import 'package:flutter/material.dart';
import 'package:bharatconnect/models/aura_models.dart' as aura_models; // Alias aura_models
import 'package:bharatconnect/widgets/aura_ring_item.dart';
import 'package:collection/collection.dart'; // Add this import for firstWhereOrNull
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile
import 'package:bharatconnect/screens/aura_select_screen.dart'; // Import AuraSelectScreen
import 'package:bharatconnect/services/aura_service.dart'; // Import AuraService
import 'dart:async'; // Import for StreamSubscription

class AuraBar extends StatefulWidget {
  final aura_models.AuraUser? currentUser; // Use AuraUser
  final List<String> connectedUserIds;

  const AuraBar({
    super.key,
    required this.currentUser,
    required this.connectedUserIds,
  });

  @override
  State<AuraBar> createState() => _AuraBarState();
}

class _AuraBarState extends State<AuraBar> {
  List<aura_models.DisplayAura> _allDisplayAuras = [];
  bool _isLoading = true;
  StreamSubscription? _auraSubscription;
  final AuraService _auraService = AuraService(); // Create an instance of AuraService

  @override
  void initState() {
    super.initState();
    print('AuraBar: initState called.');
    _listenForAuras();
  }

  @override
  void didUpdateWidget(covariant AuraBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('AuraBar: didUpdateWidget called.');
    if (oldWidget.currentUser?.id != widget.currentUser?.id ||
        !const ListEquality().equals(oldWidget.connectedUserIds, widget.connectedUserIds)) {
      print('AuraBar: currentUser or connectedUserIds changed. Re-listening for auras.');
      _listenForAuras(); // Re-listen if current user or connected users change
    }
  }

  @override
  void dispose() {
    print('AuraBar: dispose called.');
    _auraSubscription?.cancel();
    super.dispose();
  }

  void _listenForAuras() {
    _auraSubscription?.cancel(); // Cancel previous subscription

    if (widget.currentUser == null) {
      print('AuraBar: No current user. Clearing auras.');
      setState(() {
        _allDisplayAuras = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    print('AuraBar: Starting to listen for auras for user: ${widget.currentUser!.id}');

    // Combine current user's ID with connected user IDs
    final allUserIdsToListen = [widget.currentUser!.id, ...widget.connectedUserIds];

    _auraSubscription = _auraService.getConnectedUsersAuras(allUserIdsToListen)
        .listen((fetchedAuras) {
      print('AuraBar: Received new aura stream. Total auras: ${fetchedAuras.length}');
      setState(() {
        _allDisplayAuras = fetchedAuras;
        _isLoading = false;
      });
      print('AuraBar: Finished processing aura stream. Total active auras: ${_allDisplayAuras.length}');
    }, onError: (error) {
      print('AuraBar: Error listening for auras: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  // Removed _clearExpiredAuraFromFirestore as it's handled by the service or implicitly by aura expiration logic

  void _handleCurrentUserAuraClick(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuraSelectScreen())); // Uncommented navigation
  }

  void _handleOtherUserAuraClick(aura_models.DisplayAura aura) { // Use aura_models.DisplayAura
    print("AuraBar: View aura for: ${aura.userName}");
    // Potentially navigate to a view page: Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuraViewPage(aura: aura)));
  }

  @override
  Widget build(BuildContext context) {
    print('AuraBar: build method called.');
    // Find the current user's aura from allDisplayAuras
    final aura_models.DisplayAura? currentUserAuraFromList = widget.currentUser != null
        ? _allDisplayAuras.firstWhereOrNull(
            (aura) => aura.userId == widget.currentUser!.id,
          )
        : null;
    print('AuraBar: currentUser: ${widget.currentUser?.name}, ID: ${widget.currentUser?.id}');
    print('AuraBar: currentUserAuraFromList: ${currentUserAuraFromList?.auraStyle?.name}');

    // Filter for connected users' auras, excluding the current user
    final connectedUsersAuras = _isLoading || widget.currentUser == null
        ? <aura_models.DisplayAura>[]
        : _allDisplayAuras.where(
            (aura) =>
                aura.userId != widget.currentUser!.id &&
                widget.connectedUserIds.contains(aura.userId),
          ).toList();
    print('AuraBar: Connected users auras count: ${connectedUsersAuras.length}');

    return Container(
      height: 121.0, // Increased height by 11 pixels to fix overflow
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _isLoading ? 5 : (widget.currentUser != null ? 1 : 0) + connectedUsersAuras.length,
        itemBuilder: (context, index) {
          if (_isLoading) {
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
          } else if (widget.currentUser != null && index == 0) {
            print('AuraBar: Building AuraRingItem for current user.');
            return AuraRingItem(
              user: widget.currentUser!,
              activeAura: currentUserAuraFromList, // This is now nullable
              isCurrentUser: true,
              onClick: () => _handleCurrentUserAuraClick(context),
            );
          } else {
            final aura = connectedUsersAuras[widget.currentUser != null ? index - 1 : index];
            print('AuraBar: Building AuraRingItem for other user: ${aura.userName}');
            return AuraRingItem(
              user: aura_models.AuraUser( // Use AuraUser
                id: aura.userId,
                name: aura.userName,
                avatarUrl: aura.userProfileAvatarUrl,
              ),
              activeAura: aura,
              onClick: () => _handleOtherUserAuraClick(aura),
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