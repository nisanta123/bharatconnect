import 'package:flutter/material.dart';
import 'dart:async';
import 'package:bharatconnect/models/search_models.dart'; // Import User model
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar
import 'package:bharatconnect/services/status_service.dart'; // Import StatusService
import 'package:bharatconnect/models/status_model.dart'; // Import Status and DisplayStatus
import 'package:bharatconnect/screens/create_text_status_screen.dart'; // Import CreateTextStatusScreen
import 'package:bharatconnect/screens/view_status_screen.dart'; // Import ViewStatusScreen
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias FirebaseAuth
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile
import 'package:collection/collection.dart';
import 'dart:math' as math;

class _UserStatusGroup {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final List<DisplayStatus> statuses;

  _UserStatusGroup({
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.statuses,
  });

  DisplayStatus get latestStatus => statuses.first;
}

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with TickerProviderStateMixin {
  final StatusService _statusService = StatusService();
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  UserProfile? _currentUserProfile; // To store the current user's profile

  // Raw lists from streams
  List<DisplayStatus> _allMyStatuses = [];
  List<DisplayStatus> _allOtherUsersStatuses = [];

  // Categorized lists for UI
  List<DisplayStatus> _myUnviewedStatuses = [];
  List<_UserStatusGroup> _otherUsersUnviewedGroups = [];
  List<_UserStatusGroup> _viewedGroups = [];

  bool _isLoading = true;

  StreamSubscription? _myStatusesSubscription;
  StreamSubscription? _otherUsersStatusesSubscription;

  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    // Shared controller for spinning rings (used for own ring and other users')
    _ringController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _myStatusesSubscription?.cancel();
    _otherUsersStatusesSubscription?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  void _processAndCategorizeStatuses() {
    final myStatuses = <DisplayStatus>[];
    final othersUnviewed = <_UserStatusGroup>[];
    final othersViewed = <_UserStatusGroup>[];

    // Categorize own statuses - they all go into one list
    myStatuses.addAll(_allMyStatuses);

    // Group other users' statuses by userId
    final groupedByUploader = groupBy(_allOtherUsersStatuses, (DisplayStatus status) => status.userId);

    groupedByUploader.forEach((userId, statuses) {
      // Sort each user's statuses by date
      statuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latestStatus = statuses.first;
      final group = _UserStatusGroup(
        userId: userId,
        userName: latestStatus.userName,
        userAvatarUrl: latestStatus.userAvatarUrl,
        statuses: statuses,
      );

      // If any status in the group is unviewed, the whole group is unviewed
      if (statuses.any((s) => !s.viewedByCurrentUser)) {
        othersUnviewed.add(group);
      } else {
        othersViewed.add(group);
      }
    });

    // Sort the groups themselves by the latest status timestamp
    myStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    othersUnviewed.sort((a, b) => b.latestStatus.createdAt.compareTo(a.latestStatus.createdAt));
    othersViewed.sort((a, b) => b.latestStatus.createdAt.compareTo(a.latestStatus.createdAt));

    if (mounted) {
      setState(() {
        _myUnviewedStatuses = myStatuses;
        _otherUsersUnviewedGroups = othersUnviewed;
        _viewedGroups = othersViewed;
      });
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user != null) {
      // Fetch current user's profile
      final userProfileDoc = await _statusService.userProfilesCollection.doc(user.uid).get();
      if (userProfileDoc.exists) {
        _currentUserProfile = UserProfile.fromFirestore(userProfileDoc);
      }

      // Cancel any existing subscriptions
      _myStatusesSubscription?.cancel();
      _otherUsersStatusesSubscription?.cancel();

      // Listen to my statuses
      _myStatusesSubscription = _statusService.fetchMyStatuses().listen((statuses) {
        _allMyStatuses = statuses;
        _processAndCategorizeStatuses();
      });

      // Listen to other users' statuses
      _otherUsersStatusesSubscription = _statusService.fetchAllActiveStatuses([]).listen((statuses) {
        _allOtherUsersStatuses = statuses;
        _processAndCategorizeStatuses();
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
        actions: [
          // Debug action: clear local statuses cache
          IconButton(
            tooltip: 'Clear local statuses (debug)',
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              // Confirm before clearing
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear local statuses?'),
                  content: const Text('This will remove all locally cached statuses. Remote statuses remain in Firestore.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear')),
                  ],
                ),
              );
              if (ok == true) {
                await _statusService.clearLocalStatuses();
                // Refresh data
                await _fetchInitialData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local statuses cleared')));
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // My status section
                    if (_currentUserProfile != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: <Widget>[
                            GestureDetector(
                              onTap: () async {
                                if (_myUnviewedStatuses.isNotEmpty) {
                                  // If all are viewed, start from the oldest. Otherwise, start from the first unviewed.
                                  final bool allMyStatusesViewed = _myUnviewedStatuses.every((s) => s.viewedByCurrentUser);
                                  final DisplayStatus statusToOpen;

                                  if (allMyStatusesViewed) {
                                    statusToOpen = _myUnviewedStatuses.last; // Oldest
                                  } else {
                                    statusToOpen = _myUnviewedStatuses.firstWhere((s) => !s.viewedByCurrentUser, orElse: () => _myUnviewedStatuses.first);
                                  }
                                  
                                  unawaited(_statusService.markStatusViewed(statusToOpen.id));

                                  await Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => ViewStatusScreen(userId: _currentUserProfile!.id, statusId: statusToOpen.id),
                                  ));

                                  // Optimistic UI update: just mark as viewed, don't move it
                                  setState(() {
                                    final idx = _myUnviewedStatuses.indexWhere((s) => s.id == statusToOpen.id);
                                    if (idx != -1) {
                                      _myUnviewedStatuses[idx] = _myUnviewedStatuses[idx].copyWith(viewedByCurrentUser: true);
                                    }
                                  });
                                }
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  if (_myUnviewedStatuses.isNotEmpty)
                                    AnimatedBuilder(
                                      animation: _ringController,
                                      builder: (context, child) {
                                        // Show gradient ring if there's at least one unviewed status
                                        final hasUnviewed = _myUnviewedStatuses.any((s) => !s.viewedByCurrentUser);
                                        return Transform.rotate(
                                          angle: _ringController.value * 2 * math.pi,
                                          child: Container(
                                            width: 60, // Slightly larger than avatar
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: hasUnviewed
                                                  ? LinearGradient(
                                                      colors: [
                                                        Theme.of(context).colorScheme.primary, // Primary Blue
                                                        Theme.of(context).colorScheme.secondary, // Accent Violet
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    )
                                                  : null,
                                              color: !hasUnviewed ? Colors.grey.shade300.withOpacity(0.6) : null,
                                              border: !hasUnviewed ? Border.all(color: Colors.grey.shade500, width: 2.0) : null,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    // Show gray ring if all own statuses are viewed
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade300.withOpacity(0.6),
                                        border: Border.all(color: Colors.grey.shade500, width: 2.0),
                                      ),
                                    ),
                                  DefaultAvatar(
                                    radius: 28, // Slightly smaller than ring
                                    avatarUrl: _currentUserProfile?.avatarUrl,
                                    name: _currentUserProfile?.displayName ?? _currentUserProfile?.username,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () async { // Made the onTap callback async
                                        await Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => const CreateTextStatusScreen(),
                                        ));
                                        _fetchInitialData(); // Call _fetchInitialData to refresh statuses
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            GestureDetector(
                              onTap: () async {
                                if (_myUnviewedStatuses.isNotEmpty) {
                                  final bool allMyStatusesViewed = _myUnviewedStatuses.every((s) => s.viewedByCurrentUser);
                                  final DisplayStatus statusToOpen;

                                  if (allMyStatusesViewed) {
                                    statusToOpen = _myUnviewedStatuses.last; // Oldest
                                  } else {
                                    statusToOpen = _myUnviewedStatuses.firstWhere((s) => !s.viewedByCurrentUser, orElse: () => _myUnviewedStatuses.first);
                                  }

                                  unawaited(_statusService.markStatusViewed(statusToOpen.id));
                                  await Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => ViewStatusScreen(userId: _currentUserProfile!.id, statusId: statusToOpen.id),
                                  ));
                                  // Optimistic UI update
                                  setState(() {
                                    final idx = _myUnviewedStatuses.indexWhere((s) => s.id == statusToOpen.id);
                                    if (idx != -1) {
                                      _myUnviewedStatuses[idx] = _myUnviewedStatuses[idx].copyWith(viewedByCurrentUser: true);
                                    }
                                  });
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'My Status',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                  ),
                                  Text(
                                    _myUnviewedStatuses.isNotEmpty
                                        ? '${_myUnviewedStatuses.length} update${_myUnviewedStatuses.length == 1 ? '' : 's'}'
                                        : 'Tap to add status update',
                                    style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10.0),
                    // Recent updates section
                    if (_otherUsersUnviewedGroups.isNotEmpty) ...[
                      const SizedBox(height: 10.0),
                      const Text(
                        'Recent updates',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14.0),
                      ),
                    ],
                    if (_otherUsersUnviewedGroups.isNotEmpty)
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(), // to disable ListView's own scrolling
                        shrinkWrap: true,
                        itemCount: _otherUsersUnviewedGroups.length,
                        itemBuilder: (context, index) {
                          final group = _otherUsersUnviewedGroups[index];
                          // Start from the first unviewed status
                          final firstUnviewed = group.statuses.firstWhere((s) => !s.viewedByCurrentUser, orElse: () => group.latestStatus);
                          return StatusListItem(
                            statusGroup: group,
                            ringController: _ringController,
                            onClick: () async {
                              unawaited(_statusService.markStatusViewed(firstUnviewed.id));
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ViewStatusScreen(userId: group.userId, statusId: firstUnviewed.id),
                              ));
                              // Optimistic UI update
                              setState(() {
                                final statusToUpdate = group.statuses.firstWhereOrNull((s) => s.id == firstUnviewed.id);
                                if (statusToUpdate != null) {
                                  // This is tricky because we are modifying a list inside a list of groups
                                  // A full re-process is safer
                                  final updatedStatus = statusToUpdate.copyWith(viewedByCurrentUser: true);
                                  final statusIndex = group.statuses.indexWhere((s) => s.id == firstUnviewed.id);
                                  if (statusIndex != -1) {
                                    group.statuses[statusIndex] = updatedStatus;
                                  }
                                  _processAndCategorizeStatuses();
                                }
                              });
                            },
                          );
                        },
                      ),
                    // Viewed updates section
                    if (_viewedGroups.isNotEmpty) ...[
                      const SizedBox(height: 16.0),
                      const Text(
                        'Viewed updates',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14.0),
                      ),
                    ],
                    if (_viewedGroups.isNotEmpty)
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _viewedGroups.length,
                        itemBuilder: (context, index) {
                          final group = _viewedGroups[index];
                          return StatusListItem(
                            statusGroup: group,
                            ringController: null, // no rotation for viewed that is faded
                            onClick: () async {
                              // For viewed groups, start from the very first (oldest) status
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ViewStatusScreen(userId: group.userId, statusId: group.statuses.last.id),
                              ));
                            },
                          );
                        },
                      ),
                    // Placeholder when no statuses are available
                    if (_myUnviewedStatuses.isEmpty && _otherUsersUnviewedGroups.isEmpty && _viewedGroups.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No status updates available.', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    const SizedBox(height: 80), // Space for floating action buttons
                  ],
                ),
              ),
            ),
    );
  }
}

class StatusListItem extends StatelessWidget {
  final _UserStatusGroup statusGroup;
  final VoidCallback onClick;
  final AnimationController? ringController;

  const StatusListItem({
    super.key,
    required this.statusGroup,
    required this.onClick,
    this.ringController,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}'; // Fallback to date
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnviewed = statusGroup.statuses.any((s) => !s.viewedByCurrentUser);
    final latestStatus = statusGroup.latestStatus;

    return GestureDetector(
      onTap: onClick,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Show spinning gradient ring when not viewed; show faded gray ring with border when viewed
                if (hasUnviewed)
                  ringController == null
                      ? Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        )
                      : AnimatedBuilder(
                          animation: ringController!,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: ringController!.value * 2 * math.pi,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                else
                  // viewed ring — faded gray with subtle border
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300.withOpacity(0.6), // faded fill
                      border: Border.all(color: Colors.grey.shade500, width: 2.0), // gray border
                    ),
                  ),
                DefaultAvatar(
                  radius: 28, // Slightly smaller than ring
                  avatarUrl: latestStatus.userAvatarUrl,
                  name: latestStatus.userName,
                ),
              ],
            ),
            const SizedBox(width: 15.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latestStatus.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    statusGroup.statuses.length > 1
                        ? '${statusGroup.statuses.length} updates'
                        : _formatTimestamp(latestStatus.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
