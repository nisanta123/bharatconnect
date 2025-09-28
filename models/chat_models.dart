import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

class ChatRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final ChatRequestStatus status;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  ChatRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRequest(
      id: doc.id,
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      status: ChatRequestStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status']),
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}

class Chat {
  final String? id;
  final List<String> participants;
  final Timestamp createdAt;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final Timestamp? lastMessageTimestamp;

  Chat({
    this.id,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTimestamp,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      participants: List<String>.from(data['participants']),
      createdAt: data['createdAt'] as Timestamp,
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageTimestamp: data['lastMessageTimestamp'] as Timestamp?,
    );
  }
}
