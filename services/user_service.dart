import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/chat_models.dart';
import 'package:bharatconnect/models/search_models.dart';
import 'package:bharatconnect/models/user_profile_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for sent requests
  Stream<List<ChatRequest>> streamSentRequests(String senderId) {
    return _firestore
        .collection('chatRequests')
        .where('senderId', isEqualTo: senderId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRequest.fromFirestore(doc))
            .toList());
  }

  // Stream for received requests
  Stream<List<ChatRequest>> streamReceivedRequests(String receiverId) {
    return _firestore
        .collection('chatRequests')
        .where('receiverId', isEqualTo: receiverId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRequest.fromFirestore(doc))
            .toList());
  }

  Future<User?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('bharatConnectUsers').doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<String> acceptChatRequest(ChatRequest request) async {
    try {
      // 1. Update the chat request status to accepted
      await _firestore.collection('chatRequests').doc(request.id).update({
        'status': ChatRequestStatus.accepted.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Create a new chat document in a 'chats' collection
      // This assumes a simple chat structure. Adjust as needed.
      DocumentReference chatRef = await _firestore.collection('chats').add({
        'participants': [request.senderId, request.receiverId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Chat started. Messages are end-to-end encrypted.',
        'lastMessageSenderId': 'system',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      return chatRef.id; // Return the ID of the newly created chat
    } catch (e) {
      print('Error accepting chat request: $e');
      rethrow;
    }
  }

  Future<void> declineChatRequest(ChatRequest request) async {
    try {
      await _firestore.collection('chatRequests').doc(request.id).update({
        'status': ChatRequestStatus.declined.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error declining chat request: $e');
      rethrow;
    }
  }

  Future<void> cancelChatRequest(ChatRequest request) async {
    try {
      await _firestore.collection('chatRequests').doc(request.id).update({
        'status': ChatRequestStatus.cancelled.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error cancelling chat request: $e');
      rethrow;
    }
  }

  // New method to stream active chats for a user
  Stream<List<Chat>> streamUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true) // Order by last message time
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromFirestore(doc))
            .toList());
  }
}
