import 'package:flutter/material.dart';
import 'package:bharatconnect/models/aura_models.dart' as aura_models; // Alias aura_models
import 'package:bharatconnect/widgets/aura_ring_item.dart';
import 'package:collection/collection.dart'; // Add this import for firstWhereOrNull
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile
import 'package:bharatconnect/screens/aura_select_screen.dart'; // Import AuraSelectScreen
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

  @override
  void initState() {
    super.initState();
    _listenForAuras();
  }

  @override
  void didUpdateWidget(covariant AuraBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser?.id != widget.currentUser?.id ||
        !const ListEquality().equals(oldWidget.connectedUserIds, widget.connectedUserIds)) {
      _listenForAuras(); // Re-listen if current user or connected users change
    }
  }

  @override
  void dispose() {
    _auraSubscription?.cancel();
    super.dispose();
  }

  void _listenForAuras() {
    _auraSubscription?.cancel(); // Cancel previous subscription

    if (widget.currentUser == null) {
      setState(() {
        _allDisplayAuras = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _auraSubscription = FirebaseFirestore.instance
        .collection('auras')
        .snapshots()
        .listen((snapshot) async {
      final List<aura_models.DisplayAura> fetchedAuras = [];
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final firestoreAura = aura_models.FirestoreAura.fromFirestore(doc);
        final createdAt = firestoreAura.createdAt.toDate();
        final expiresAt = createdAt.add(const Duration(hours: 1));

        if (now.isBefore(expiresAt)) {
          // Fetch user profile for each active aura
          final userProfileDoc = await FirebaseFirestore.instance
              .collection('bharatConnectUsers')
              .doc(firestoreAura.userId)
              .get();

          if (userProfileDoc.exists) {
            final userProfile = UserProfile.fromFirestore(userProfileDoc);
            final matchingAuraOption = aura_models.AURA_OPTIONS.firstWhereOrNull(
              (option) => option.id == firestoreAura.auraOptionId,
            );

            if (matchingAuraOption != null) {
              fetchedAuras.add(aura_models.DisplayAura(
                id: doc.id,
                userId: firestoreAura.userId,
                userName: userProfile.displayName ?? userProfile.username ?? 'Unknown',
                userProfileAvatarUrl: userProfile.avatarUrl,
                auraOptionId: firestoreAura.auraOptionId,
                createdAt: createdAt,
                auraStyle: matchingAuraOption,
              ));
            }
          }
        } else {
          // Aura expired, delete it from Firestore
          _clearExpiredAuraFromFirestore(doc.id);
        }
      }

      setState(() {
        _allDisplayAuras = fetchedAuras;
        _isLoading = false;
      });
    }, onError: (error) { // Corrected onError handling
      print('AuraBar: Error listening for auras: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _clearExpiredAuraFromFirestore(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('auras').doc(docId).delete();
    } catch (e) {
      print('AuraBar: Error deleting expired aura: $e');
    }
  }

  void _handleCurrentUserAuraClick(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuraSelectScreen())); // Uncommented navigation
  }

  void _handleOtherUserAuraClick(aura_models.DisplayAura aura) { // Use aura_models.DisplayAura
    // Potentially navigate to a view page: Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuraViewPage(aura: aura)));
  }

  @override
  Widget build(BuildContext context) {
    // Find the current user's aura from allDisplayAuras
    final aura_models.DisplayAura? currentUserAuraFromList = widget.currentUser != null
        ? _allDisplayAuras.firstWhereOrNull(
            (aura) => aura.userId == widget.currentUser!.id,
          )
        : null;

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
      height: 125.0, // Increased height to accommodate AuraRingItems without overflow
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
            return AuraRingItem(
              user: widget.currentUser!,
              activeAura: currentUserAuraFromList, // This is now nullable
              isCurrentUser: true,
              onClick: () => _handleCurrentUserAuraClick(context),
            );
          } else {
            final aura = connectedUsersAuras[widget.currentUser != null ? index - 1 : index];
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