import 'package:flutter/material.dart';
import 'package:bharatconnect/models/search_models.dart'; // Import User model
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar
import 'package:bharatconnect/services/status_service.dart'; // Import StatusService
import 'package:bharatconnect/models/status_model.dart'; // Import Status and DisplayStatus
import 'package:bharatconnect/screens/create_text_status_screen.dart'; // Import CreateTextStatusScreen
import 'package:bharatconnect/screens/view_status_screen.dart'; // Import ViewStatusScreen
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias FirebaseAuth
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with SingleTickerProviderStateMixin {
  final StatusService _statusService = StatusService();
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  UserProfile? _currentUserProfile; // To store the current user's profile
  List<DisplayStatus> _myStatuses = [];
  List<DisplayStatus> _otherUsersStatuses = [];
  bool _isLoading = true;

  late AnimationController _myStatusRingController;

  @override
  void initState() {
    super.initState();
    _myStatusRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Adjust speed as needed
    )..repeat(); // Repeat the animation indefinitely
    _fetchInitialData();
  }

  @override
  void dispose() {
    _myStatusRingController.dispose();
    super.dispose();
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

      // Listen to my statuses
      _statusService.fetchMyStatuses().listen((statuses) {
        setState(() {
          _myStatuses = statuses;
        });
      });

      // TODO: Replace with actual connected user IDs
      // For now, fetching all active statuses (excluding current user) for demonstration
      _statusService.fetchAllActiveStatuses([]).listen((statuses) {
        setState(() {
          _otherUsersStatuses = statuses;
        });
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              if (_myStatuses.isNotEmpty) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ViewStatusScreen(userId: _currentUserProfile!.id, statusId: _myStatuses.first.id), // View own latest status
                                ));
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                if (_myStatuses.isNotEmpty)
                                  AnimatedBuilder(
                                    animation: _myStatusRingController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _myStatusRingController.value * 2 * 3.141592653589793, // 2 * PI for a full circle
                                        child: Container(
                                          width: 60, // Slightly larger than avatar
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context).colorScheme.primary, // Primary Blue
                                                Theme.of(context).colorScheme.secondary, // Accent Violet
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
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
                                    onTap: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) => const CreateTextStatusScreen(),
                                      ));
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
                            onTap: () {
                              if (_myStatuses.isNotEmpty) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ViewStatusScreen(userId: _currentUserProfile!.id, statusId: _myStatuses.first.id), // View own latest status
                                ));
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
                                  _myStatuses.isNotEmpty
                                      ? '${_myStatuses.length} updates'
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
                    if (_otherUsersStatuses.isNotEmpty)
                      const Text(
                        'Recent updates',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14.0),
                      ),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(), // to disable ListView's own scrolling
                      shrinkWrap: true,
                      itemCount: _otherUsersStatuses.length,
                      itemBuilder: (context, index) {
                        final status = _otherUsersStatuses[index];
                        return StatusListItem(
                          status: status,
                          onClick: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ViewStatusScreen(userId: status.userId, statusId: status.id), // Pass userId and statusId
                            ));
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20.0),
                    // Viewed updates section (placeholder for now)
                    if (_otherUsersStatuses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No recent status updates.', style: TextStyle(color: Colors.grey)),
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
  final DisplayStatus status;
  final VoidCallback onClick;

  const StatusListItem({
    super.key,
    required this.status,
    required this.onClick,
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
    return GestureDetector(
      onTap: onClick,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (!status.viewedByCurrentUser) // Show gradient ring if not viewed
                  Container(
                    width: 60, // Slightly larger than avatar
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary, // Primary Blue
                          Theme.of(context).colorScheme.secondary, // Accent Violet
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                DefaultAvatar(
                  radius: 28, // Slightly smaller than ring
                  avatarUrl: status.userAvatarUrl,
                  name: status.userName,
                ),
              ],
            ),
            const SizedBox(width: 15.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Text(
                    _formatTimestamp(status.createdAt),
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
