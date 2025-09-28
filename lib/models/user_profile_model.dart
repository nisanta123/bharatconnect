import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName; // 👈 standardized instead of "name"
  final String? username;
  final String? avatarUrl;
  final String? status; // Add status field
  final bool onboardingComplete;
  final String? phone;
  final String? bio;
  final String? activeKeyId; // For E2EE, if implemented later
  final String? activeAuraId; // New field to store the ID of the active aura

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.status, // Include in constructor
    this.onboardingComplete = false,
    this.phone,
    this.bio,
    this.activeKeyId,
    this.activeAuraId, // Include in constructor
  });

  // Factory to create from Firestore or Map
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromMap(doc.id, data);
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? data['username'] as String? ?? '', // 👈 fallback so it's never null
      username: data['username'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      status: data['status'] as String?,
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      bio: data['bio'] as String?,
      phone: data['phone'] as String?,
      activeKeyId: data['activeKeyId'] as String?,
      activeAuraId: data['activeAuraId'] as String?, // Include in fromFirestore
    );
  }

  // Convert to Map for saving
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'status': status, // Include in toMap
      'onboardingComplete': onboardingComplete,
      'phone': phone,
      'bio': bio,
      'activeKeyId': activeKeyId,
      'activeAuraId': activeAuraId, // Include in toMap
    };
  }

  // Method to update specific fields
  UserProfile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? status,
    bool? onboardingComplete,
    String? phone,
    String? bio,
    String? activeKeyId,
    String? activeAuraId, // Include in copyWith
  }) {
    return UserProfile(
      id: id,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      activeKeyId: activeKeyId ?? this.activeKeyId,
      activeAuraId: activeAuraId ?? this.activeAuraId, // Update activeAuraId
    );
  }
}
