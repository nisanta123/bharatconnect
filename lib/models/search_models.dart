enum UserRequestStatus {
  idle,
  request_sent,
  chat_exists,
  is_self,
  on_cooldown,
}

class User {
  final String id;
  final String name;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final String? currentAuraId;
  final String? status;
  final bool hasViewedStatus;
  final bool onboardingComplete;
  final String? bio; // Added bio field

  const User({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.avatarUrl,
    this.currentAuraId,
    this.status,
    this.hasViewedStatus = false,
    this.onboardingComplete = false,
    this.bio, // Added bio to constructor
  });
}

class BharatConnectFirestoreUser extends User {
  const BharatConnectFirestoreUser({
    required super.id,
    required super.name,
    super.username,
    super.email,
    super.avatarUrl,
    super.currentAuraId,
    super.status,
    super.hasViewedStatus,
    super.onboardingComplete,
    super.bio, // Added bio to constructor
  });
}

class SearchResultUser extends User {
  final UserRequestStatus requestUiStatus;
  final int? cooldownEndsAt; // Timestamp in milliseconds

  const SearchResultUser({
    required super.id,
    required super.name,
    super.username,
    super.email,
    super.avatarUrl,
    super.currentAuraId,
    super.status,
    super.hasViewedStatus,
    super.onboardingComplete,
    required this.requestUiStatus,
    this.cooldownEndsAt,
    super.bio, // Added bio to constructor
  });
}
