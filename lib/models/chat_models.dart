import 'package:flutter/material.dart';
import 'package:bharatconnect/models/search_models.dart'; // For User model

enum MessageType {
  text,
  image,
  system,
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

  const Message({
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
  });
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

class UserAura {
  final String id;
  final String name;
  final String iconUrl;
  final Color primaryColor;
  final Color secondaryColor;

  const UserAura({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.primaryColor,
    required this.secondaryColor,
  });
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
