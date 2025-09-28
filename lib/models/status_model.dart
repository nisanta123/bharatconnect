import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile

class Status {
  final String id;
  final String userId;
  final String text;
  final String? fontFamily;
  final String? backgroundColor; // Stored as a string (e.g., hex or gradient ID)
  final Timestamp createdAt;
  final Timestamp expiresAt;

  const Status({
    required this.id,
    required this.userId,
    required this.text,
    this.fontFamily,
    this.backgroundColor,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Status.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Status.fromMap(data, doc.id);
  }

  factory Status.fromMap(Map<String, dynamic> data, String id) {
    return Status(
      id: id,
      userId: data['userId'] as String,
      text: data['text'] as String,
      fontFamily: data['fontFamily'] as String?,
      backgroundColor: data['backgroundColor'] as String?,
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : Timestamp.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      expiresAt: data['expiresAt'] is Timestamp ? data['expiresAt'] as Timestamp : Timestamp.fromMillisecondsSinceEpoch(data['expiresAt'] as int),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'text': text,
      'fontFamily': fontFamily,
      'backgroundColor': backgroundColor,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }
}

// This model will be used in the UI to display status updates,
// combining status data with user profile information and viewed status.
class DisplayStatus {
  final String id; // Status ID
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String text;
  final String? fontFamily;
  final String? backgroundColor;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool viewedByCurrentUser; // Whether the current user has viewed this specific status

  const DisplayStatus({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.text,
    this.fontFamily,
    this.backgroundColor,
    required this.createdAt,
    required this.expiresAt,
    this.viewedByCurrentUser = false,
  });

  // Helper to create a DisplayStatus from a Status and UserProfile
  factory DisplayStatus.fromStatusAndUserProfile({
    required Status status,
    required UserProfile userProfile,
    bool viewedByCurrentUser = false,
  }) {
    return DisplayStatus(
      id: status.id,
      userId: status.userId,
      userName: userProfile.displayName ?? userProfile.username ?? 'Unknown User',
      userAvatarUrl: userProfile.avatarUrl,
      text: status.text,
      fontFamily: status.fontFamily,
      backgroundColor: status.backgroundColor,
      createdAt: status.createdAt.toDate(),
      expiresAt: status.expiresAt.toDate(),
      viewedByCurrentUser: viewedByCurrentUser,
    );
  }
}
