import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/aura_models.dart';
import 'package:bharatconnect/models/user_profile_model.dart';

class AuraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sets a user's active aura
  Future<void> setActiveAura(String userId, String auraOptionId) async {
    final userRef = _firestore.collection('bharatConnectUsers').doc(userId);
    final activeAuraRef = _firestore.collection('auras').doc(userId); // Changed to 'auras'

    // Update user's profile with the active aura ID
    await userRef.update({
      'activeAuraId': auraOptionId,
    });

    // Create or update the active aura document
    await activeAuraRef.set({
      'userId': userId,
      'auraOptionId': auraOptionId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Clears a user's active aura
  Future<void> clearActiveAura(String userId) async {
    final userRef = _firestore.collection('bharatConnectUsers').doc(userId);
    final activeAuraRef = _firestore.collection('auras').doc(userId); // Changed to 'auras'

    // Remove active aura ID from user's profile
    await userRef.update({
      'activeAuraId': FieldValue.delete(),
    });

    // Delete the active aura document
    await activeAuraRef.delete();
  }

  // Get a stream of active auras for connected users
  Stream<List<DisplayAura>> getConnectedUsersAuras(List<String> connectedUserIds) {
    if (connectedUserIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore.collection('auras') // Changed to 'auras'
        .where('userId', whereIn: connectedUserIds)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<DisplayAura> displayAuras = [];
      for (final doc in snapshot.docs) {
        final firestoreAura = FirestoreAura.fromFirestore(doc);
        final userProfileDoc = await _firestore.collection('bharatConnectUsers').doc(firestoreAura.userId).get();

        if (userProfileDoc.exists) {
          final userProfile = UserProfile.fromFirestore(userProfileDoc);
          final userAura = AURA_OPTIONS.firstWhere(
            (aura) => aura.id == firestoreAura.auraOptionId,
            orElse: () => AURA_OPTIONS.first, // Default to first aura if not found
          );

          displayAuras.add(DisplayAura(
            id: doc.id,
            userId: firestoreAura.userId,
            userName: userProfile.displayName ?? userProfile.username ?? 'Unknown',
            userProfileAvatarUrl: userProfile.avatarUrl,
            auraOptionId: firestoreAura.auraOptionId,
            createdAt: firestoreAura.createdAt.toDate(),
            auraStyle: userAura,
          ));
        }
      }
      return displayAuras;
    });
  }
}
