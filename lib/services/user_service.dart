import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile
import '../models/aura_models.dart';
import '../models/search_models.dart'; // Import for UserRequestStatus
import '../models/chat_models.dart'; // Import for Chat and ChatRequestStatus
import 'encryption_service.dart'; // Import EncryptionService
import 'local_data_store.dart'; // Import LocalDataStore
import 'dart:async'; // Import for StreamController

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryptionService = EncryptionService(); // Instantiate EncryptionService
  final LocalDataStore _localDataStore = LocalDataStore(); // Instantiate LocalDataStore

  Future<void> initializeUserData(String userId) async {
    print('Initializing user data for $userId');
    try {
      // Fetch and store user profile
      await getUserById(userId); // This already saves to local store

      // Fetch and store chats
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      for (var doc in chatsSnapshot.docs) {
        final chat = Chat.fromFirestore(doc);
        await _localDataStore.saveChat(chat);

        // Fetch and store messages for each chat
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(chat.id)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .get();

        for (var msgDoc in messagesSnapshot.docs) {
          final message = Message.fromFirestore(msgDoc);
          await _localDataStore.saveMessage(message);
        }
      }

      // Fetch and store chat requests
      final sentRequestsSnapshot = await _firestore
          .collection('bharatConnectUsers')
          .doc(userId)
          .collection('requestsSent')
          .get();
      for (var doc in sentRequestsSnapshot.docs) {
        final request = ChatRequest.fromFirestore(doc);
        await _localDataStore.saveChatRequest(request);
      }

      final receivedRequestsSnapshot = await _firestore
          .collection('bharatConnectUsers')
          .doc(userId)
          .collection('requestsReceived')
          .get();
      for (var doc in receivedRequestsSnapshot.docs) {
        final request = ChatRequest.fromFirestore(doc);
        await _localDataStore.saveChatRequest(request);
      }

      print('User data initialization complete for $userId');
    } catch (e) {
      print('Error initializing user data: $e');
    }
  }

  Future<List<User>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    // Convert query to lowercase for case-insensitive search
    final lowerCaseQuery = query.toLowerCase();

    // Perform a multi-field search across name, username, email, and ID
    final nameResults = await _firestore
        .collection('bharatConnectUsers') // Changed to bharatConnectUsers
        .where('name', isGreaterThanOrEqualTo: lowerCaseQuery)
        .where('name', isLessThanOrEqualTo: lowerCaseQuery + '\uf8ff')
        .get();

    final usernameResults = await _firestore
        .collection('bharatConnectUsers') // Changed to bharatConnectUsers
        .where('username', isGreaterThanOrEqualTo: lowerCaseQuery)
        .where('username', isLessThanOrEqualTo: lowerCaseQuery + '\uf8ff')
        .get();

    final emailResults = await _firestore
        .collection('bharatConnectUsers') // Changed to bharatConnectUsers
        .where('email', isGreaterThanOrEqualTo: lowerCaseQuery)
        .where('email', isLessThanOrEqualTo: lowerCaseQuery + '\uf8ff')
        .get();

    final idResults = await _firestore
        .collection('bharatConnectUsers') // Changed to bharatConnectUsers
        .where(FieldPath.documentId, isEqualTo: query) // Search by document ID
        .get();

    // Combine results and remove duplicates
    final Set<String> uniqueUserIds = {};
    final List<User> users = [];

    for (var doc in [...nameResults.docs, ...usernameResults.docs, ...emailResults.docs, ...idResults.docs]) {
      if (uniqueUserIds.add(doc.id)) {
        users.add(User(
          id: doc.id,
          name: doc['displayName'] ?? doc['username'] ?? '', // Use displayName or username
          username: doc['username'] ?? '', // Include username
          email: doc['email'] ?? '', // Include email
          avatarUrl: doc['avatarUrl'],
        ));
      }
    }
    return users;
  }

  Future<void> sendChatRequest(String senderId, String receiverId) async {
    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    // Add to sender's requestsSent subcollection
    final senderRequestRef = _firestore.collection('bharatConnectUsers').doc(senderId).collection('requestsSent').doc(receiverId);
    batch.set(senderRequestRef, {
      'senderId': senderId, // Explicitly add senderId
      'receiverId': receiverId,
      'status': ChatRequestStatus.pending.toString(),
      'timestamp': timestamp,
    });

    // Add to receiver's requestsReceived subcollection
    final receiverRequestRef = _firestore.collection('bharatConnectUsers').doc(receiverId).collection('requestsReceived').doc(senderId);
    batch.set(receiverRequestRef, {
      'senderId': senderId,
      'receiverId': receiverId, // Explicitly add receiverId
      'status': ChatRequestStatus.awaiting_action.toString(),
      'timestamp': timestamp,
    });

    await batch.commit();
  }

  Future<UserRequestStatus> getChatStatus(String currentUserId, String targetUserId) async {
    final firestore = FirebaseFirestore.instance;

    // If the target is self
    if (currentUserId == targetUserId) return UserRequestStatus.is_self;

    try {
      // 1️⃣ Check if current user has sent a request
      final sentSnapshot = await firestore
          .collection('bharatConnectUsers')
          .doc(currentUserId)
          .collection('requestsSent')
          .doc(targetUserId)
          .get();

      if (sentSnapshot.exists) return UserRequestStatus.request_sent;

      // 2️⃣ Check if current user has received a request
      final receivedSnapshot = await firestore
          .collection('bharatConnectUsers')
          .doc(currentUserId)
          .collection('requestsReceived')
          .doc(targetUserId)
          .get();

      if (receivedSnapshot.exists) return UserRequestStatus.request_received;

      // 3️⃣ Check if a chat already exists between the two users
      final chatQuery = await firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      final chatExists = chatQuery.docs.any((doc) {
        final participants = List<String>.from(doc['participants']);
        return participants.contains(targetUserId);
      });

      if (chatExists) return UserRequestStatus.chat_exists;

      // 4️⃣ If none of the above, user is idle
      return UserRequestStatus.idle;

    } catch (e) {
      print('Error getting chat status: $e');
      return UserRequestStatus.idle;
    }
  }

  Future<UserProfile?> getUserById(String userId) async {
    // Try to get from local store first
    final cachedUser = await _localDataStore.getUser(userId);
    if (cachedUser != null) {
      return cachedUser;
    }

    try {
      final doc = await _firestore.collection('bharatConnectUsers').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?; // Get data as a map
        if (data == null) return null; // Handle case where data is null

        final userProfile = UserProfile(
          id: doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? data['username'] ?? '',
          username: data['username'] ?? '',
          avatarUrl: data['avatarUrl'],
          activeAuraId: data['activeAuraId'],
          onboardingComplete: data['onboardingComplete'] ?? false,
          bio: data['bio'],
          phone: data['phone'],
          activeKeyId: data['activeKeyId'],
        );
        await _localDataStore.saveUser(userProfile); // Save to local store
        return userProfile;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  Stream<List<ChatRequest>> streamSentRequests(String userId) {
    final controller = StreamController<List<ChatRequest>>();

    // 1. Emit locally stored sent requests first
    _localDataStore.retrieve(LocalDataStore.chatRequestsTable, where: 'senderId = ?', whereArgs: [userId]).then((localRequestsData) {
      final localRequests = localRequestsData.map((data) => ChatRequest.fromMap(data, data['id'] as String)).toList();
      controller.add(localRequests);
    });

    // 2. Listen to Firestore for real-time updates
    _firestore
        .collection('bharatConnectUsers')
        .doc(userId)
        .collection('requestsSent')
        .snapshots()
        .listen((snapshot) async {
      final firestoreRequests = <ChatRequest>[];
      for (var doc in snapshot.docs) {
        final request = ChatRequest.fromFirestore(doc);
        firestoreRequests.add(request);
        await _localDataStore.saveChatRequest(request); // Save/update in local store
      }
      // Emit all requests, including newly fetched ones
      final allRequests = await _localDataStore.retrieve(LocalDataStore.chatRequestsTable, where: 'senderId = ?', whereArgs: [userId]);
      final mergedRequests = allRequests.map((data) => ChatRequest.fromMap(data, data['id'] as String)).toList();
      controller.add(mergedRequests);
    }, onError: (error) {
      print('Error streaming sent requests from Firestore: $error');
    });

    return controller.stream;
  }

  Stream<List<ChatRequest>> streamReceivedRequests(String userId) {
    final controller = StreamController<List<ChatRequest>>();

    // 1. Emit locally stored received requests first
    _localDataStore.retrieve(LocalDataStore.chatRequestsTable, where: 'receiverId = ?', whereArgs: [userId]).then((localRequestsData) {
      final localRequests = localRequestsData.map((data) => ChatRequest.fromMap(data, data['id'] as String)).toList();
      controller.add(localRequests);
    });

    // 2. Listen to Firestore for real-time updates
    _firestore
        .collection('bharatConnectUsers')
        .doc(userId)
        .collection('requestsReceived')
        .snapshots()
        .listen((snapshot) async {
      final firestoreRequests = <ChatRequest>[];
      for (var doc in snapshot.docs) {
        final request = ChatRequest.fromFirestore(doc);
        firestoreRequests.add(request);
        await _localDataStore.saveChatRequest(request); // Save/update in local store
      }
      // Emit all requests, including newly fetched ones
      final allRequests = await _localDataStore.retrieve(LocalDataStore.chatRequestsTable, where: 'receiverId = ?', whereArgs: [userId]);
      final mergedRequests = allRequests.map((data) => ChatRequest.fromMap(data, data['id'] as String)).toList();
      controller.add(mergedRequests);
    }, onError: (error) {
      print('Error streaming received requests from Firestore: $error');
    });

    return controller.stream;
  }

  Stream<List<Chat>> streamUserChats(String userId) {
    final controller = StreamController<List<Chat>>();
    print('DEBUG: streamUserChats called for userId: $userId');

    // 2. Listen to Firestore for real-time updates
    _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) async {
      print('DEBUG: streamUserChats - Firestore snapshot received. Docs: ${snapshot.docs.length}');
      
      // Create a map of chats from the current Firestore snapshot
      final Map<String, Chat> firestoreChatsMap = {};
      for (var doc in snapshot.docs) {
        final chat = Chat.fromFirestore(doc);
        firestoreChatsMap[chat.id] = chat;
        await _localDataStore.saveChat(chat); // Save/update in local store
        print('DEBUG: streamUserChats - Saved chat to local store: ${chat.id}');
        print('DEBUG: streamUserChats - Added Firestore chat to firestoreChatsMap: ${chat.id}');
      }

      // The final list of chats should only contain those present in Firestore.
      // Local-only chats that don't have a Firestore counterpart will be excluded.
      final sortedMergedChats = firestoreChatsMap.values.toList(); // Use values from the Firestore-driven map
      sortedMergedChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Sort by updatedAt, newest first

      print('DEBUG: streamUserChats - Emitting final merged chats. Total: ${sortedMergedChats.length}');
      controller.add(sortedMergedChats);
    }, onError: (error) {
      print('Error streaming user chats from Firestore: $error');
      // Optionally, emit an error or just rely on local data
    });

    return controller.stream;
  }

  Future<void> cancelChatRequest(ChatRequest request) async {
    // Remove from sender's requestsSent
    await _firestore
        .collection('bharatConnectUsers')
        .doc(request.senderId)
        .collection('requestsSent')
        .doc(request.receiverId)
        .delete();
    // Remove from receiver's requestsReceived
    await _firestore
        .collection('bharatConnectUsers')
        .doc(request.receiverId)
        .collection('requestsReceived')
        .doc(request.senderId)
        .delete();
  }

  Future<String> acceptChatRequest(ChatRequest request) async {
    print('DEBUG: acceptChatRequest called');
    print('DEBUG: request.senderId = ${request.senderId}');
    print('DEBUG: request.receiverId = ${request.receiverId}');

    // Fetch sender and receiver user profiles
    final senderProfile = await getUserById(request.senderId);
    final receiverProfile = await getUserById(request.receiverId);

    if (senderProfile == null || receiverProfile == null) {
      throw Exception('Could not fetch sender or receiver profile.');
    }

    // Save/update profiles in local store after fetching/creating
    await _localDataStore.saveUser(senderProfile);
    await _localDataStore.saveUser(receiverProfile);

    // Create participantInfo map
    final Map<String, dynamic> participantInfo = {
      request.senderId: {
        'name': senderProfile.displayName,
        'avatarUrl': senderProfile.avatarUrl,
        'currentAuraId': senderProfile.activeAuraId,
      },
      request.receiverId: {
        'name': receiverProfile.displayName,
        'avatarUrl': receiverProfile.avatarUrl,
        'currentAuraId': receiverProfile.activeAuraId,
      },
    };

    // Create a new chat document
    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'participants': [request.senderId, request.receiverId],
      'participantInfo': participantInfo, // Add participantInfo
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'type': 'private',
      // Set chat name and avatar based on the other participant
      'name': receiverProfile.displayName, // Name of the chat for the sender
      'avatarUrl': receiverProfile.avatarUrl, // Avatar of the chat for the sender
    });
    print('DEBUG: New chat document created with ID: ${chatRef.id}');

    // Update request status
    print('DEBUG: Updating sender\'s requestsSent: userId=${request.senderId}, requestId=${request.receiverId}');
    await _firestore
        .collection('bharatConnectUsers')
        .doc(request.senderId)
        .collection('requestsSent')
        .doc(request.receiverId)
        .update({'status': ChatRequestStatus.accepted.toString()});

    print('DEBUG: Updating receiver\'s requestsReceived: userId=${request.receiverId}, requestId=${request.senderId}');
    await _firestore
        .collection('bharatConnectUsers')
        .doc(request.receiverId)
        .collection('requestsReceived')
        .doc(request.senderId)
        .update({'status': ChatRequestStatus.accepted.toString()});
    return chatRef.id;
  }

  Future<void> declineChatRequest(ChatRequest request) async {
    await _firestore
        .collection('bharatConnectUsers')
        .doc(request.senderId)
        .collection('requestsSent')
        .doc(request.receiverId)
        .update({'status': ChatRequestStatus.rejected.toString()});
    await _firestore
        .collection('bharatConnectUsers')
        .doc(request.receiverId)
        .collection('requestsReceived')
        .doc(request.senderId)
        .update({'status': ChatRequestStatus.rejected.toString()});
  }

  Stream<List<Message>> streamChatMessages(String chatId) {
    // Listen to Firestore for real-time updates, ordered by timestamp ascending.
    // The merging with local optimistic messages will be handled in the ChatPage's listener.
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Order by timestamp ascending
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }
}

// Helper function to convert UserProfile to User
User toUser(UserProfile profile) {
  return User(
    id: profile.id,
    name: profile.displayName,
    username: profile.username,
    email: profile.email,
    avatarUrl: profile.avatarUrl,
    // Assuming default values for other User fields not present in UserProfile
    currentAuraId: profile.activeAuraId,
    status: null, // UserProfile doesn't have status
    hasViewedStatus: false, // UserProfile doesn't have hasViewedStatus
    onboardingComplete: profile.onboardingComplete,
    bio: profile.bio,
  );
}