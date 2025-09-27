import 'package:flutter/material.dart';
import 'package:bharatconnect/models/search_models.dart'; // Import User model
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar

enum CallType {
  incoming,
  outgoing,
  missed,
}

class Call {
  final User user;
  final CallType type;
  final String time;

  const Call({ // Added const
    required this.user,
    required this.type,
    required this.time,
  });
}

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  final List<Call> _mockCalls = const [
    Call(
      user: User(id: '1', name: 'Alice', avatarUrl: null),
      type: CallType.incoming,
      time: 'Yesterday, 10:30 AM',
    ),
    Call(
      user: User(id: '2', name: 'Bob', avatarUrl: null),
      type: CallType.outgoing,
      time: 'Yesterday, 11:00 AM',
    ),
    Call(
      user: User(id: '3', name: 'Charlie', avatarUrl: null),
      type: CallType.missed,
      time: 'Today, 9:00 AM',
    ),
    Call(
      user: User(id: '4', name: 'David', avatarUrl: null),
      type: CallType.incoming,
      time: 'Today, 1:00 PM',
    ),
    Call(
      user: User(id: '5', name: 'Eve', avatarUrl: null),
      type: CallType.outgoing,
      time: 'Today, 2:30 PM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Placeholder for loading state
    bool isLoading = false; // Set to true to see loading skeletons
    // Placeholder for empty state
    bool hasCalls = true; // Set to false to see empty state

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
      ),
      body: Stack(
        children: [
          if (isLoading)
            ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.all(8.0),
                child: CallHistoryItemSkeleton(),
              ),
            )
          else if (!hasCalls)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.call_missed, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No recent calls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You haven\'t made or received any calls yet.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      print('Start a call tapped');
                      // TODO: Navigate to contacts to start a call
                    },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text('Start a call', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075E54), // WhatsApp green
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              itemCount: _mockCalls.length, // Use mock calls length
              itemBuilder: (context, index) {
                final call = _mockCalls[index];
                IconData callIcon;
                Color iconColor;

                switch (call.type) {
                  case CallType.incoming:
                    callIcon = Icons.call_received;
                    iconColor = Colors.green; // Assuming answered incoming
                    break;
                  case CallType.outgoing:
                    callIcon = Icons.call_made;
                    iconColor = Colors.green; // Assuming answered outgoing
                    break;
                  case CallType.missed:
                    callIcon = Icons.call_missed;
                    iconColor = Colors.red;
                    break;
                }

                return Column(
                  children: [
                    ListTile(
                      leading: DefaultAvatar(
                        radius: 25,
                        avatarUrl: call.user.avatarUrl,
                        name: call.user.name,
                      ),
                      title: Text(call.user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: <Widget>[
                          Icon(
                            callIcon,
                            color: iconColor,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(call.time),
                        ],
                      ),
                      trailing: Icon(Icons.call, color: Theme.of(context).primaryColor),
                      onTap: () {
                        print('Call with ${call.user.name} tapped');
                        // TODO: Handle call item tap
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class CallHistoryItemSkeleton extends StatelessWidget {
  const CallHistoryItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        DefaultAvatar(
          radius: 25,
          avatarUrl: null, // Skeleton doesn't have an avatar URL
          name: null, // Skeleton doesn't have a name
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(width: 150, height: 10, color: Colors.grey[300]),
              const SizedBox(height: 5),
              Container(width: 100, height: 10, color: Colors.grey[300]),
            ],
          ),
        ),
        Container(width: 24, height: 24, color: Colors.grey[300]),
      ],
    );
  }
}