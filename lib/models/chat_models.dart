import 'package:flutter/material.dart';
import 'package:bharatconnect/models/search_models.dart'; // For User model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Import jsonDecode

enum MessageType {
  text,
  image,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

enum ChatRequestStatus {
  pending,
  awaiting_action,
  accepted,
  rejected,
  none,
}

class MediaInfo {
  final String fileName;
  final String fileType;
  final String fileId;
  final String? thumbnailUrl;
  final int? fileSize;

  const MediaInfo({
    required this.fileName,
    required this.fileType,
    required this.fileId,
    this.thumbnailUrl,
    this.fileSize,
  });
}

class Message {
  final String id;
  final String? clientTempId;
  final String chatId;
  final String senderId;
  final int timestamp;
  final MessageType type;
  final List<String> readBy;
  final String? text;
  final MediaInfo? mediaInfo;
  final String? error;
  final String? iv;
  final String? encryptedText;
  final Map<String, dynamic>? encryptedKeys;
  final String? keyId;
  String? decryptedText; // Add this line
  MessageStatus status; // Add message status

  Message({
    required this.id,
    this.clientTempId,
    required this.chatId,
    required this.senderId,
    required this.timestamp,
    required this.type,
    required this.readBy,
    this.text,
    this.mediaInfo,
    this.error,
    this.iv,
    this.encryptedText,
    this.encryptedKeys,
    this.keyId,
    this.decryptedText, // Initialize decryptedText
    this.status = MessageStatus.sending, // Default status
  });

  Message copyWith({
    String? id,
    String? clientTempId,
    String? chatId,
    String? senderId,
    int? timestamp,
    MessageType? type,
    List<String>? readBy,
    String? text,
    MediaInfo? mediaInfo,
    String? error,
    String? iv,
    String? encryptedText,
    Map<String, dynamic>? encryptedKeys,
    String? keyId,
    String? decryptedText,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      clientTempId: clientTempId ?? this.clientTempId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      readBy: readBy ?? this.readBy,
      text: text ?? this.text,
      mediaInfo: mediaInfo ?? this.mediaInfo,
      error: error ?? this.error,
      iv: iv ?? this.iv,
      encryptedText: encryptedText ?? this.encryptedText,
      encryptedKeys: encryptedKeys ?? this.encryptedKeys,
      keyId: keyId ?? this.keyId,
      decryptedText: decryptedText ?? this.decryptedText, // Copy decryptedText
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'clientTempId': clientTempId,
      'chatId': chatId,
      'senderId': senderId,
      'timestamp': timestamp,
      'type': type.toString(),
      'readBy': readBy,
      'text': text,
      'mediaInfo': mediaInfo != null
          ? {
              'fileName': mediaInfo!.fileName,
              'fileType': mediaInfo!.fileType,
              'fileId': mediaInfo!.fileId,
              'thumbnailUrl': mediaInfo!.thumbnailUrl,
              'fileSize': mediaInfo!.fileSize,
            }
          : null,
      'error': error,
      'iv': iv,
      'encryptedText': encryptedText,
      'encryptedKeys': encryptedKeys,
      'keyId': keyId,
      'status': status.toString(), // Include status
    };
  }

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message.fromMap(data, doc.id);
  }

  factory Message.fromMap(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      clientTempId: data['clientTempId'] as String?,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      timestamp: data['timestamp'] as int,
      type: MessageType.values.firstWhere((e) => e.toString() == data['type']),
      readBy: List<String>.from(data['readBy'] as List? ?? []),
      text: data['text'] as String?,
      mediaInfo: data['mediaInfo'] != null
          ? MediaInfo(
              fileName: data['mediaInfo']['fileName'] as String,
              fileType: data['mediaInfo']['fileType'] as String,
              fileId: data['mediaInfo']['fileId'] as String,
              thumbnailUrl: data['mediaInfo']['thumbnailUrl'] as String?,
              fileSize: data['mediaInfo']['fileSize'] as int?,
            )
          : null,
      error: data['error'] as String?,
      iv: data['iv'] as String?,
      encryptedText: data['encryptedText'] as String?,
      encryptedKeys: data['encryptedKeys'] as Map<String, dynamic>?,
      keyId: data['keyId'] as String?,
      decryptedText: null, // Initialize as null when creating from Firestore
      status: data['status'] != null
          ? MessageStatus.values.firstWhere((e) => e.toString() == data['status'], orElse: () => MessageStatus.sent)
          : MessageStatus.sent, // Default to sent if status is not present
    );
  }
}

class ParticipantInfo {
  final String name;
  final String? avatarUrl;
  final String? currentAuraId;
  final bool hasActiveUnviewedStatus;
  final bool hasActiveViewedStatus;

  const ParticipantInfo({
    required this.name,
    this.avatarUrl,
    this.currentAuraId,
    this.hasActiveUnviewedStatus = false,
    this.hasActiveViewedStatus = false,
  });
}

class ChatSpecificPresence {
  final String state;
  final int lastChanged;

  const ChatSpecificPresence({
    required this.state,
    required this.lastChanged,
  });
}

class Chat {
  final String id;
  final String type;
  final List<String> participants;
  final Map<String, ParticipantInfo> participantInfo;
  final Message? lastMessage;
  final int updatedAt;
  final String? contactUserId;
  final ChatRequestStatus? requestStatus;
  final String? requesterId;
  final int? acceptedTimestamp;
  final String? name;
  final String? avatarUrl;
  final Map<String, bool>? typingStatus;
  final Map<String, ChatSpecificPresence>? chatSpecificPresence;

  const Chat({
    required this.id,
    required this.type,
    required this.participants,
    required this.participantInfo,
    this.lastMessage,
    required this.updatedAt,
    this.contactUserId,
    this.requestStatus,
    this.requesterId,
    this.acceptedTimestamp,
    this.name,
    this.avatarUrl,
    this.typingStatus,
    this.chatSpecificPresence,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat.fromMap(data, doc.id);
  }

  factory Chat.fromMap(Map<String, dynamic> data, String id) {
    final dynamic participantsData = data['participants'];
    List<String> parsedParticipants;

    if (participantsData is String) {
      parsedParticipants = List<String>.from(jsonDecode(participantsData) as List);
    } else if (participantsData is List) {
      parsedParticipants = List<String>.from(participantsData);
    } else {
      parsedParticipants = []; // Default to empty list
    }

    final dynamic participantInfoData = data['participantInfo'];
    Map<String, ParticipantInfo> parsedParticipantInfo;

    if (participantInfoData is String) {
      parsedParticipantInfo = (jsonDecode(participantInfoData) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, ParticipantInfo(
          name: value['name'] as String,
          avatarUrl: value['avatarUrl'] as String?,
          currentAuraId: value['currentAuraId'] as String?,
          hasActiveUnviewedStatus: value['hasActiveUnviewedStatus'] as bool? ?? false,
          hasActiveViewedStatus: value['hasActiveViewedStatus'] as bool? ?? false,
        )),
      );
    } else if (participantInfoData is Map<String, dynamic>) {
      parsedParticipantInfo = participantInfoData.map(
        (key, value) => MapEntry(key, ParticipantInfo(
          name: value['name'] as String,
          avatarUrl: value['avatarUrl'] as String?,
          currentAuraId: value['currentAuraId'] as String?,
          hasActiveUnviewedStatus: value['hasActiveUnviewedStatus'] as bool? ?? false,
          hasActiveViewedStatus: value['hasActiveViewedStatus'] as bool? ?? false,
        )),
      );
    } else {
      parsedParticipantInfo = {}; // Default to empty map
    }

    return Chat(
      id: id,
      type: data['type'] as String,
      participants: parsedParticipants,
      participantInfo: parsedParticipantInfo,
      lastMessage: data['lastMessage'] != null
          ? (data['lastMessage'] is String
              ? Message.fromMap(jsonDecode(data['lastMessage']) as Map<String, dynamic>, (jsonDecode(data['lastMessage']) as Map<String, dynamic>)['id'] as String)
              : Message.fromMap(data['lastMessage'] as Map<String, dynamic>, data['lastMessage']['id'] as String))
          : null,
      updatedAt: data['updatedAt'] as int,
      contactUserId: data['contactUserId'] as String?,
      requestStatus: data['requestStatus'] != null
          ? ChatRequestStatus.values.firstWhere((e) => e.toString() == data['requestStatus'])
          : null,
      requesterId: data['requesterId'] as String?,
      acceptedTimestamp: data['acceptedTimestamp'] as int?,
      name: data['name'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      typingStatus: (data['typingStatus'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as bool),
      ),
      chatSpecificPresence: (data['chatSpecificPresence'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, ChatSpecificPresence(
          state: value['state'] as String,
          lastChanged: value['lastChanged'] as int,
        )),
      ),
    );
  }

  String get lastMessageSenderId {
    return lastMessage?.senderId ?? 'system';
  }

  Timestamp? get lastMessageTimestamp {
    if (lastMessage != null) {
      return Timestamp.fromMillisecondsSinceEpoch(lastMessage!.timestamp);
    }
    return null;
  }

  String? get lastMessageText {
    return lastMessage?.text;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Chat copyWith({
    String? id,
    String? type,
    List<String>? participants,
    Map<String, ParticipantInfo>? participantInfo,
    Message? lastMessage,
    int? updatedAt,
    String? contactUserId,
    ChatRequestStatus? requestStatus,
    String? requesterId,
    int? acceptedTimestamp,
    String? name,
    String? avatarUrl,
    Map<String, bool>? typingStatus,
    Map<String, ChatSpecificPresence>? chatSpecificPresence,
  }) {
    return Chat(
      id: id ?? this.id,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      participantInfo: participantInfo ?? this.participantInfo,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      contactUserId: contactUserId ?? this.contactUserId,
      requestStatus: requestStatus ?? this.requestStatus,
      requesterId: requesterId ?? this.requesterId,
      acceptedTimestamp: acceptedTimestamp ?? this.acceptedTimestamp,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      typingStatus: typingStatus ?? this.typingStatus,
      chatSpecificPresence: chatSpecificPresence ?? this.chatSpecificPresence,
    );
  }
}

class FirestoreAura {
  final String userId;
  final String auraOptionId;
  final int createdAt;

  const FirestoreAura({
    required this.userId,
    required this.auraOptionId,
    required this.createdAt,
  });
}

class ChatRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final ChatRequestStatus status;
  final DateTime timestamp;

  const ChatRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.timestamp,
  });

  factory ChatRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRequest.fromMap(data, doc.id);
  }

  factory ChatRequest.fromMap(Map<String, dynamic> data, String id) {
    final dynamic timestampData = data['timestamp'];
    DateTime parsedTimestamp;

    if (timestampData is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
    } else if (timestampData is Timestamp) {
      parsedTimestamp = timestampData.toDate();
    } else {
      // Fallback or throw an error if the type is unexpected
      parsedTimestamp = DateTime.now(); // Or handle as an error
    }

    return ChatRequest(
      id: id,
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      status: ChatRequestStatus.values.firstWhere(
          (e) => e.toString() == data['status'],
          orElse: () => ChatRequestStatus.pending),
      timestamp: parsedTimestamp,
    );
  }
}
