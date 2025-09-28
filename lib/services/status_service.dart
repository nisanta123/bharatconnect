import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bharatconnect/models/status_model.dart';
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile
import 'local_data_store.dart'; // Import LocalDataStore
import 'dart:async'; // Import for StreamController

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalDataStore _localDataStore = LocalDataStore(); // Instantiate LocalDataStore

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

    final newStatusRef = statusesCollection.doc();
    final status = Status(
      id: newStatusRef.id,
      userId: user.uid,
      text: text,
      fontFamily: fontFamily,
      backgroundColor: backgroundColor,
      createdAt: now,
      expiresAt: expiresAt,
    );

    await newStatusRef.set(status.toFirestore());
    await _localDataStore.saveStatus(status); // Save to local store
  }

  // Fetch all active statuses for the current user
  Stream<List<DisplayStatus>> fetchMyStatuses() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    final controller = StreamController<List<DisplayStatus>>();

    // 1. Emit locally stored statuses first
    _localDataStore.retrieve(LocalDataStore.statusesTable, where: 'userId = ?', whereArgs: [user.uid]).then((localStatusesData) async {
      final localStatuses = <DisplayStatus>[];
      for (var data in localStatusesData) {
        final status = Status.fromMap(data, data['id'] as String);
        final userProfile = await _localDataStore.getUser(user.uid); // Get user profile from local store
        if (userProfile != null) {
          localStatuses.add(DisplayStatus.fromStatusAndUserProfile(
            status: status,
            userProfile: UserProfile(id: userProfile.id, email: userProfile.email ?? '', displayName: userProfile.displayName, username: userProfile.username, avatarUrl: userProfile.avatarUrl), // Convert to UserProfile
            viewedByCurrentUser: true,
          ));
        }
      }
      controller.add(localStatuses);
    });

    // 2. Listen to Firestore for real-time updates
    statusesCollection
        .where('userId', isEqualTo: user.uid)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final List<Status> myStatuses = snapshot.docs.map((doc) => Status.fromFirestore(doc)).toList();
      final userProfileDoc = await userProfilesCollection.doc(user.uid).get();
      if (!userProfileDoc.exists) {
        controller.add([]);
        return;
      }
      final userProfile = UserProfile.fromFirestore(userProfileDoc);

      final List<DisplayStatus> displayStatuses = [];
      for (var status in myStatuses) {
        await _localDataStore.saveStatus(status); // Save/update in local store
        displayStatuses.add(DisplayStatus.fromStatusAndUserProfile(
          status: status,
          userProfile: userProfile,
          viewedByCurrentUser: true,
        ));
      }
      controller.add(displayStatuses);
    }, onError: (error) {
      print('Error streaming my statuses from Firestore: $error');
    });

    return controller.stream;
  }

  // Fetch all active statuses from connected users (excluding current user)
  // This method assumes you have a way to get a list of connected user IDs.
  // For now, it will fetch all active statuses from all users (excluding current user).
  Stream<List<DisplayStatus>> fetchAllActiveStatuses(List<String> connectedUserIds) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final controller = StreamController<List<DisplayStatus>>();

    // Filter out the current user's ID from the list of connected users
    final usersToFetch = connectedUserIds.where((id) => id != currentUser.uid).toList();

    if (usersToFetch.isEmpty) {
      return Stream.value([]);
    }

    // 1. Emit locally stored statuses first
    _localDataStore.retrieve(LocalDataStore.statusesTable, where: 'userId IN (${usersToFetch.map((_) => '?').join(',')})', whereArgs: usersToFetch).then((localStatusesData) async {
      final localDisplayStatuses = <DisplayStatus>[];
      for (var data in localStatusesData) {
        final status = Status.fromMap(data, data['id'] as String);
        final userProfile = await _localDataStore.getUser(status.userId); // Get user profile from local store
        if (userProfile != null) {
          localDisplayStatuses.add(DisplayStatus.fromStatusAndUserProfile(
            status: status,
            userProfile: UserProfile(id: userProfile.id, email: userProfile.email ?? '', displayName: userProfile.displayName, username: userProfile.username, avatarUrl: userProfile.avatarUrl), // Convert to UserProfile
            viewedByCurrentUser: false, // Placeholder for actual logic
          ));
        }
      }
      controller.add(localDisplayStatuses);
    });

    // 2. Listen to Firestore for real-time updates
    statusesCollection
        .where('userId', whereIn: usersToFetch)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final List<Status> statuses = snapshot.docs.map((doc) => Status.fromFirestore(doc)).toList();

      // Fetch user profiles for all unique user IDs in the fetched statuses
      final Set<String> uniqueUserIds = statuses.map((s) => s.userId).toSet();
      final Map<String, UserProfile> userProfiles = {};

      if (uniqueUserIds.isNotEmpty) {
        for (var uid in uniqueUserIds) {
          UserProfile? profile = await _localDataStore.getUser(uid); // Try local first
          if (profile == null) {
            final doc = await userProfilesCollection.doc(uid).get();
            if (doc.exists) {
              profile = UserProfile.fromFirestore(doc);
              await _localDataStore.saveUser(profile); // Save to local store
            }
          }
          if (profile != null) {
            userProfiles[profile.id] = profile;
          }
        }
      }

      final List<DisplayStatus> displayStatuses = [];
      for (var status in statuses) {
        await _localDataStore.saveStatus(status); // Save/update in local store
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
      controller.add(displayStatuses);
    }, onError: (error) {
      print('Error streaming all active statuses from Firestore: $error');
    });

    return controller.stream;
  }

  // TODO: Add methods for marking status as viewed, deleting status, etc.

  Future<void> syncStatusData() async {
    print('Syncing status data...');
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No current user, skipping status data sync.');
        return;
      }

      // Fetch all active statuses from Firestore
      final statusesSnapshot = await statusesCollection
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .get();

      for (var doc in statusesSnapshot.docs) {
        final status = Status.fromFirestore(doc);
        await _localDataStore.saveStatus(status); // Save status to local store

        // Fetch and save user profile for the status if not already in local store
        final userProfile = await _localDataStore.getUser(status.userId);
        if (userProfile == null) {
          final userDoc = await userProfilesCollection.doc(status.userId).get();
          if (userDoc.exists) {
            final profile = UserProfile.fromFirestore(userDoc);
            await _localDataStore.saveUser(profile); // Save user to local store
          }
        }
      }
      print('Status data sync complete.');
    } catch (e) {
      print('Error syncing status data: $e');
    }
  }
}
