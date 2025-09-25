import 'package:flutter/material.dart';
import 'package:bharatconnect/models/search_models.dart'; // Import User model

class StatusUpdate {
  final User user;
  final String timeAgo;
  final bool hasViewed;

  StatusUpdate({
    required this.user,
    required this.timeAgo,
    this.hasViewed = false,
  });
}

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final User _currentUser = User(id: '1', name: 'My Status', avatarUrl: null);

  final List<StatusUpdate> _recentUpdates = [
    StatusUpdate(
      user: User(id: '2', name: 'Alice', avatarUrl: null),
      timeAgo: '10 minutes ago',
      hasViewed: false,
    ),
    StatusUpdate(
      user: User(id: '3', name: 'Bob', avatarUrl: null),
      timeAgo: '30 minutes ago',
      hasViewed: true,
    ),
    StatusUpdate(
      user: User(id: '4', name: 'Charlie', avatarUrl: null),
      timeAgo: '1 hour ago',
      hasViewed: false,
    ),
  ];

  final List<StatusUpdate> _viewedUpdates = [
    StatusUpdate(
      user: User(id: '5', name: 'David', avatarUrl: null),
      timeAgo: '2 hours ago',
      hasViewed: true,
    ),
    StatusUpdate(
      user: User(id: '6', name: 'Eve', avatarUrl: null),
      timeAgo: '5 hours ago',
      hasViewed: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // My status section
                GestureDetector(
                  onTap: () {
                    print('My status tapped');
                    // TODO: Navigate to create/view my status
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey,
                              backgroundImage: _currentUser.avatarUrl != null
                                  ? NetworkImage(_currentUser.avatarUrl!)
                                  : null,
                              child: _currentUser.avatarUrl == null
                                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366), // WhatsApp light green
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 15.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _currentUser.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                            ),
                            const Text(
                              'Tap to add status update',
                              style: TextStyle(color: Colors.grey, fontSize: 14.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                // Recent updates section
                if (_recentUpdates.isNotEmpty)
                  const Text(
                    'Recent updates',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14.0),
                  ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(), // to disable ListView's own scrolling
                  shrinkWrap: true,
                  itemCount: _recentUpdates.length,
                  itemBuilder: (context, index) {
                    final status = _recentUpdates[index];
                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey, // Consistent grey background
                            child: const Icon(Icons.person, color: Colors.white, size: 30), // Always show default icon
                          ),
                          title: Text(status.user.name),
                          subtitle: Text(status.timeAgo),
                          onTap: () {
                            print('${status.user.name} status tapped');
                            // TODO: Navigate to view contact status
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                // Viewed updates section
                if (_viewedUpdates.isNotEmpty)
                  const Text(
                    'Viewed updates',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14.0),
                  ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(), // to disable ListView's own scrolling
                  shrinkWrap: true,
                  itemCount: _viewedUpdates.length,
                  itemBuilder: (context, index) {
                    final status = _viewedUpdates[index];
                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey, // Consistent grey background
                            child: const Icon(Icons.person, color: Colors.white, size: 30), // Always show default icon
                          ),
                          title: Text(status.user.name),
                          subtitle: Text(status.timeAgo),
                          onTap: () {
                            print('${status.user.name} status tapped');
                            // TODO: Navigate to view contact status
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 80), // Space for floating action buttons
              ],
            ),
          ),
        ),
        // Floating Action Buttons
        /*
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              FloatingActionButton(
                heroTag: "textStatus",
                mini: true,
                backgroundColor: Colors.grey[300],
                onPressed: () {
                  print('New text status tapped');
                  // TODO: Navigate to create text status
                },
                child: const Icon(Icons.edit, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: "cameraStatus",
                backgroundColor: const Color(0xFF25D366), // WhatsApp light green
                onPressed: () {
                  print('New camera status tapped');
                  // TODO: Navigate to create camera status
                },
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ],
          ),
        ),
        */
      ],
    );
  }
}
