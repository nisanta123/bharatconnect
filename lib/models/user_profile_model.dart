import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  String? username;
  String? displayName;
  String? avatarUrl;
  bool onboardingComplete;
  String? phone;
  String? bio;
  String? activeKeyId; // For E2EE, if implemented later

  UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.onboardingComplete = false,
    this.phone,
    this.bio,
    this.activeKeyId,
  });

  // Factory constructor to create a UserProfile from a Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] as String,
      username: data['username'] as String?,
      displayName: data['displayName'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      phone: data['phone'] as String?,
      bio: data['bio'] as String?,
      activeKeyId: data['activeKeyId'] as String?,
    );
  }

  // Method to convert UserProfile to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'onboardingComplete': onboardingComplete,
      'phone': phone,
      'bio': bio,
      'activeKeyId': activeKeyId,
    };
  }

  // Method to update specific fields
  UserProfile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    bool? onboardingComplete,
    String? phone,
    String? bio,
    String? activeKeyId,
  }) {
    return UserProfile(
      id: id,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      activeKeyId: activeKeyId ?? this.activeKeyId,
    );
  }
}
