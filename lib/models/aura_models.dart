import 'package:flutter/material.dart'; // Added for Color
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Timestamp

class AuraUser { // Renamed from User
  final String id;
  final String name;
  final String? avatarUrl;

  AuraUser({required this.id, required this.name, this.avatarUrl}); // Renamed constructor
}

// Represents a static aura option (e.g., Fire, Water)
class UserAura {
  final String id;
  final String name;
  final String iconUrl; // Path to local asset or network URL
  final Color primaryColor;
  final Color secondaryColor;
  final String? gradient; // String representing a gradient class/name (for potential future use)

  const UserAura({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.primaryColor,
    required this.secondaryColor,
    this.gradient,
  });
}

// Represents an active aura stored in Firestore
class FirestoreAura {
  final String userId;
  final String auraOptionId;
  final Timestamp createdAt;

  FirestoreAura({
    required this.userId,
    required this.auraOptionId,
    required this.createdAt,
  });

  factory FirestoreAura.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreAura(
      userId: data['userId'] as String,
      auraOptionId: data['auraOptionId'] as String,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(), // Handle null createdAt
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'auraOptionId': auraOptionId,
      'createdAt': createdAt,
    };
  }
}

// Represents a combined model for displaying an active aura
class DisplayAura {
  final String id; // Corresponds to Firestore doc ID for the active aura
  final String userId;
  final String userName;
  final String? userProfileAvatarUrl; // Made nullable
  final String auraOptionId; // ID of the selected UserAura
  final DateTime createdAt; // When the aura was set
  final UserAura? auraStyle; // The actual UserAura object

  DisplayAura({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileAvatarUrl,
    required this.auraOptionId,
    required this.createdAt,
    this.auraStyle,
  });

  DisplayAura copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileAvatarUrl,
    String? auraOptionId,
    DateTime? createdAt,
    UserAura? auraStyle,
  }) {
    return DisplayAura(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileAvatarUrl: userProfileAvatarUrl ?? this.userProfileAvatarUrl,
      auraOptionId: auraOptionId ?? this.auraOptionId,
      createdAt: createdAt ?? this.createdAt,
      auraStyle: auraStyle ?? this.auraStyle,
    );
  }
}

// Constant list of available aura options
const List<UserAura> AURA_OPTIONS = [
  UserAura(
    id: 'happy',
    name: 'Happy',
    iconUrl: 'assets/icons/happy.PNG',
    primaryColor: Color(0xFFFACC15), // yellow-300 equivalent
    secondaryColor: Color(0xFFF97316), // orange-400 equivalent
    gradient: 'bg-gradient-to-r from-yellow-300 via-orange-400 to-red-400',
  ),
  UserAura(
    id: 'sad',
    name: 'Sad',
    iconUrl: 'assets/icons/sad.PNG',
    primaryColor: Color(0xFF60A5FA), // blue-400 equivalent
    secondaryColor: Color(0xFF6366F1), // indigo-500 equivalent
    gradient: 'bg-gradient-to-r from-blue-400 to-indigo-500',
  ),
  UserAura(
    id: 'angry',
    name: 'Angry',
    iconUrl: 'assets/icons/angry.PNG',
    primaryColor: Color(0xFFEF4444), // red-500 equivalent
    secondaryColor: Color(0xFFEC4899), // pink-600 equivalent
    gradient: 'bg-gradient-to-r from-red-500 to-pink-600',
  ),
  UserAura(
    id: 'calm',
    name: 'Calm',
    iconUrl: 'assets/icons/calm.PNG',
    primaryColor: Color(0xFF86EFAC), // green-300 equivalent
    secondaryColor: Color(0xFF2DD4BF), // teal-400 equivalent
    gradient: 'bg-gradient-to-r from-green-300 to-teal-400',
  ),
  UserAura(
    id: 'focused',
    name: 'Focused',
    iconUrl: 'assets/icons/focused.PNG',
    primaryColor: Color(0xFF3B82F6), // blue-500 equivalent
    secondaryColor: Color(0xFF9333EA), // purple-600 equivalent
    gradient: 'bg-gradient-to-r from-blue-500 to-purple-600',
  ),
  UserAura(
    id: 'romantic',
    name: 'Romantic',
    iconUrl: 'assets/icons/romantic.PNG',
    primaryColor: Color(0xFFF472B6), // pink-400 equivalent
    secondaryColor: Color(0xFFEF4444), // red-400 equivalent
    gradient: 'bg-gradient-to-r from-pink-400 to-red-400',
  ),
  UserAura(
    id: 'chill',
    name: 'Chill',
    iconUrl: 'assets/icons/chill.PNG',
    primaryColor: Color(0xFF22D3EE), // cyan-400 equivalent
    secondaryColor: Color(0xFF38BDF8), // sky-500 equivalent
    gradient: 'bg-gradient-to-r from-cyan-400 to-sky-500',
  ),
  UserAura(
    id: 'playful',
    name: 'Playful',
    iconUrl: 'assets/icons/playful.PNG',
    primaryColor: Color(0xFFA78BFA), // purple-400 equivalent
    secondaryColor: Color(0xFFEC4899), // pink-500 equivalent
    gradient: 'bg-gradient-to-r from-purple-400 via-pink-500 to-red-500',
  ),
  UserAura(
    id: 'energetic',
    name: 'Energetic',
    iconUrl: 'assets/icons/energetic.PNG',
    primaryColor: Color(0xFFFACC15), // yellow-400 equivalent
    secondaryColor: Color(0xFFF59E0B), // amber-500 equivalent
    gradient: 'bg-gradient-to-r from-yellow-400 via-amber-500 to-orange-600',
  ),
];