import 'package:flutter/material.dart'; // Added for Color
// import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Timestamp

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
// class FirestoreAura {
//   final String userId;
//   final String auraOptionId;
//   final Timestamp createdAt;

//   FirestoreAura({
//     required this.userId,
//     required this.auraOptionId,
//     required this.createdAt,
//   });

//   factory FirestoreAura.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return FirestoreAura(
//       userId: data['userId'] as String,
//       auraOptionId: data['auraOptionId'] as String,
//       createdAt: data['createdAt'] as Timestamp,
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'userId': userId,
//       'auraOptionId': auraOptionId,
//       'createdAt': createdAt,
//     };
//   }
// }

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
    id: 'fire',
    name: 'Fire',
    iconUrl: 'assets/icons/fire.png',
    primaryColor: Color(0xFFEF4444), // red-500
    secondaryColor: Color(0xFFF97316), // orange-500
    gradient: 'bg-gradient-to-br from-red-500 to-orange-500',
  ),
  UserAura(
    id: 'water',
    name: 'Water',
    iconUrl: 'assets/icons/water.png',
    primaryColor: Color(0xFF3B82F6), // blue-500
    secondaryColor: Color(0xFF60A5FA), // blue-400
    gradient: 'bg-gradient-to-br from-blue-500 to-blue-400',
  ),
  UserAura(
    id: 'earth',
    name: 'Earth',
    iconUrl: 'assets/icons/earth.png',
    primaryColor: Color(0xFF22C55E), // green-500
    secondaryColor: Color(0xFF84CC16), // lime-500
    gradient: 'bg-gradient-to-br from-green-500 to-lime-500',
  ),
  UserAura(
    id: 'air',
    name: 'Air',
    iconUrl: 'assets/icons/air.png',
    primaryColor: Color(0xFF67E8F9), // cyan-400
    secondaryColor: Color(0xFFBAE6FD), // sky-300
    gradient: 'bg-gradient-to-br from-cyan-400 to-sky-300',
  ),
  UserAura(
    id: 'love',
    name: 'Love',
    iconUrl: 'assets/icons/heart.png',
    primaryColor: Color(0xFFEC4899), // pink-500
    secondaryColor: Color(0xFFF472B6), // pink-400
    gradient: 'bg-gradient-to-br from-pink-500 to-pink-400',
  ),
  UserAura(
    id: 'peace',
    name: 'Peace',
    iconUrl: 'assets/icons/peace.png',
    primaryColor: Color(0xFF6366F1), // indigo-500
    secondaryColor: Color(0xFF818CF8), // indigo-400
    gradient: 'bg-gradient-to-br from-indigo-500 to-indigo-400',
  ),
  UserAura(
    id: 'joy',
    name: 'Joy',
    iconUrl: 'assets/icons/joy.png',
    primaryColor: Color(0xFFFACC15), // yellow-500
    secondaryColor: Color(0xFFFDE047), // yellow-400
    gradient: 'bg-gradient-to-br from-yellow-500 to-yellow-400',
  ),
  UserAura(
    id: 'calm',
    name: 'Calm',
    iconUrl: 'assets/icons/moon.png',
    primaryColor: Color(0xFF475569), // slate-600
    secondaryColor: Color(0xFF94A3B8), // slate-400
    gradient: 'bg-gradient-to-br from-slate-600 to-slate-400',
  ),
];