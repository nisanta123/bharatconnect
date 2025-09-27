import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aura_models.dart';
import '../models/search_models.dart'; // Import for UserRequestStatus
import '../models/chat_models.dart'; // Import for Chat and ChatRequestStatus

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    final senderRequestRef = _firestore.collection('bharatConnectUsers').doc(senderId).collection('requestsSent').doc(receiverId); // Changed to bharatConnectUsers
    batch.set(senderRequestRef, {
      'receiverId': receiverId,
      'status': ChatRequestStatus.pending.toString(),
      'timestamp': timestamp,
    });

    // Add to receiver's requestsReceived subcollection
    final receiverRequestRef = _firestore.collection('bharatConnectUsers').doc(receiverId).collection('requestsReceived').doc(senderId); // Changed to bharatConnectUsers
    batch.set(receiverRequestRef, {
      'senderId': senderId,
      'status': ChatRequestStatus.awaiting_action.toString(),
      'timestamp': timestamp,
    });

    await batch.commit();
  }

  Future<UserRequestStatus> getChatStatus(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) {
      return UserRequestStatus.is_self;
    }

    // Check if a chat already exists
    final existingChat = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in existingChat.docs) {
      final chat = Chat.fromFirestore(doc); // Assuming a fromFirestore factory for Chat
      if (chat.participants.contains(targetUserId)) {
        return UserRequestStatus.chat_exists;
      }
    }

    // Check if a request has been sent by the current user to the target user
    final sentRequest = await _firestore
        .collection('bharatConnectUsers') // Changed to bharatConnectUsers
        .doc(currentUserId)
        .collection('requestsSent')
        .doc(targetUserId)
        .get();

    if (sentRequest.exists) {
      return UserRequestStatus.request_sent;
    }

    // Check for cooldown (this would require a more complex logic,
    // for now, we'll assume no cooldown if no request sent or chat exists)
    // You would typically store cooldown information in the user's document
    // or in the request document itself.
    return UserRequestStatus.idle;
  }
}