import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bharatconnect/models/status_model.dart';
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference for statuses
  CollectionReference<Map<String, dynamic>> get statusesCollection => _firestore.collection('statuses');
  // Collection reference for user profiles (assuming 'bharatConnectUsers' as per previous context)
  CollectionReference<Map<String, dynamic>> get userProfilesCollection => _firestore.collection('bharatConnectUsers');

  // Create a new text status
  Future<void> createTextStatus({
    required String text,
    String? fontFamily,
    String? backgroundColor,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    final now = Timestamp.now();
    final expiresAt = Timestamp.fromMillisecondsSinceEpoch(
      now.millisecondsSinceEpoch + (24 * 60 * 60 * 1000), // 24 hours from now
    );

    await statusesCollection.add({
      'userId': user.uid,
      'text': text,
      'fontFamily': fontFamily,
      'backgroundColor': backgroundColor,
      'createdAt': now,
      'expiresAt': expiresAt,
    });
  }

  // Fetch all active statuses for the current user
  Stream<List<DisplayStatus>> fetchMyStatuses() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return statusesCollection
        .where('userId', isEqualTo: user.uid)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Status> myStatuses = snapshot.docs.map((doc) => Status.fromFirestore(doc)).toList();
      final userProfileDoc = await userProfilesCollection.doc(user.uid).get();
      if (!userProfileDoc.exists) {
        return [];
      }
      final userProfile = UserProfile.fromFirestore(userProfileDoc);

      return myStatuses.map((status) => DisplayStatus.fromStatusAndUserProfile(
        status: status,
        userProfile: userProfile,
        viewedByCurrentUser: true, // Current user has viewed their own status
      )).toList();
    });
  }

  // Fetch all active statuses from connected users (excluding current user)
  // This method assumes you have a way to get a list of connected user IDs.
  // For now, it will fetch all active statuses from all users (excluding current user).
  Stream<List<DisplayStatus>> fetchAllActiveStatuses(List<String> connectedUserIds) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Filter out the current user's ID from the list of connected users
    final usersToFetch = connectedUserIds.where((id) => id != currentUser.uid).toList();

    if (usersToFetch.isEmpty) {
      return Stream.value([]);
    }

    return statusesCollection
        .where('userId', whereIn: usersToFetch)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Status> statuses = snapshot.docs.map((doc) => Status.fromFirestore(doc)).toList();

      // Fetch user profiles for all unique user IDs in the fetched statuses
      final Set<String> uniqueUserIds = statuses.map((s) => s.userId).toSet();
      final Map<String, UserProfile> userProfiles = {};

      if (uniqueUserIds.isNotEmpty) {
        final userProfileSnapshots = await Future.wait(
          uniqueUserIds.map((uid) => userProfilesCollection.doc(uid).get()),
        );
        for (var doc in userProfileSnapshots) {
          if (doc.exists) {
            final profile = UserProfile.fromFirestore(doc);
            userProfiles[profile.id] = profile;
          }
        }
      }

      final List<DisplayStatus> displayStatuses = [];
      for (var status in statuses) {
        final userProfile = userProfiles[status.userId];
        if (userProfile != null) {
          // TODO: Implement actual logic to check if current user has viewed this status
          final viewedByCurrentUser = false; // Placeholder
          displayStatuses.add(DisplayStatus.fromStatusAndUserProfile(
            status: status,
            userProfile: userProfile,
            viewedByCurrentUser: viewedByCurrentUser,
          ));
        }
      }
      return displayStatuses;
    });
  }

  // TODO: Add methods for marking status as viewed, deleting status, etc.
}
