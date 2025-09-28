import 'package:flutter/material.dart';
import 'package:bharatconnect/widgets/aura_bar.dart';
import 'package:bharatconnect/models/aura_models.dart' as aura_models; // Alias aura_models
import 'package:bharatconnect/screens/chat_page.dart'; // Corrected import path
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar
import 'package:bharatconnect/services/user_service.dart'; // Import UserService - Contains chat request and chat stream logic
import 'package:bharatconnect/models/chat_models.dart'; // Import ChatRequest and ChatRequestStatus
import 'dart:async'; // Import for StreamSubscription
import 'package:bharatconnect/models/search_models.dart'; // Import for User model
import 'package:bharatconnect/screens/user_profile_screen.dart'; // Import UserProfileScreen
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp

class ChatListScreen extends StatefulWidget {
  final UserProfile? currentUserProfile; // Accept currentUserProfile

  const ChatListScreen({super.key, this.currentUserProfile});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Map<String, String?>> _mockChats = const [
    {
      'id': 'chat_1', // Added mock chat ID
      'name': 'Alice',
      'lastMessage': 'Hey, how are you?',
      'time': '10:30 AM',
      'avatarUrl': null, // Set to null
    },
    {
      'id': 'chat_2', // Added mock chat ID
      'name': 'Bob',
      'lastMessage': 'Don\'t forget our meeting.',
      'time': 'Yesterday',
      'avatarUrl': null, // Set to null
    },
    {
      'id': 'chat_3', // Added mock chat ID
      'name': 'Charlie',
      'lastMessage': 'See you soon!',
      'time': 'Sunday',
      'avatarUrl': null, // Set to null
    },
    {
      'id': 'chat_4', // Added mock chat ID
      'name': 'David',
      'lastMessage': 'Flutter is awesome!',
      'time': 'Saturday',
      'avatarUrl': null, // Set to null
    },
    {
      'id': 'chat_5', // Added mock chat ID
      'name': 'Eve',
      'lastMessage': 'Let\'s catch up.',
      'time': 'Friday',
      'avatarUrl': null, // Set to null
    },
    {
      'id': 'chat_6', // Added mock chat ID
      'name': 'Frank',
      'lastMessage': 'New project ideas.',
      'time': 'Thursday',
      'avatarUrl': null, // Set to null
    },
    {
      'id': 'chat_7', // Added mock chat ID
      'name': 'Grace',
      'lastMessage': 'Meeting at 3 PM.',
      'time': 'Wednesday',
      'avatarUrl': null, // Set to null
    },
    {
      'id': 'chat_8', // Added mock chat ID
      'name': 'Heidi',
      'lastMessage': 'Can you send the report?',
      'time': 'Tuesday',
      'avatarUrl': null, // Set to null
    },
    {
      'id': 'chat_9', // Added mock chat ID
      'name': 'Ivan',
      'lastMessage': 'Great work!',
      'time': 'Monday',
      'avatarUrl': null, // Set to null
    },
    {
      'id': 'chat_10', // Added mock chat ID
      'name': 'Judy',
      'lastMessage': 'See you tomorrow.',
      'time': 'Sunday',
      'avatarUrl': null, // Set to null
    },
  ];

  final UserService _userService = UserService(); // Added UserService instance
  List<ChatRequest> _sentRequests = []; // Added state for sent requests
  List<ChatRequest> _receivedRequests = []; // Added state for received requests
  List<Chat> _chats = []; // Added state for active chats
  List<StreamSubscription> _requestSubscriptions = []; // Added for managing subscriptions

  bool _isLoadingAuras = false; // Set to true to test loading state

  @override
  void initState() {
    super.initState();
    _fetchChatRequests(); // Call to fetch chat requests
    _fetchUserChats(); // Call to fetch active chats
  }

  @override
  void dispose() {
    for (var subscription in _requestSubscriptions) {
      subscription.cancel(); // Cancel all subscriptions
    }
    super.dispose();
  }

  void _fetchChatRequests() {
    if (widget.currentUserProfile == null) return;

    // Listen to sent requests
    _requestSubscriptions.add(
      _userService.streamSentRequests(widget.currentUserProfile!.id).listen((requests) {
        print('DEBUG: Sent requests updated: ${requests.length}');
        setState(() {
          _sentRequests = requests.where((req) => req.status == ChatRequestStatus.pending).toList();
        });
      }),
    );

    // Listen to received requests
    _requestSubscriptions.add(
      _userService.streamReceivedRequests(widget.currentUserProfile!.id).listen((requests) {
        print('DEBUG: Received requests updated: ${requests.length}');
        setState(() {
          _receivedRequests = requests.where((req) => req.status == ChatRequestStatus.awaiting_action).toList();
        });
      }),
    );
  }

  void _fetchUserChats() {
    if (widget.currentUserProfile == null) return;

    _requestSubscriptions.add(
      _userService.streamUserChats(widget.currentUserProfile!.id).listen((chats) {
        print('DEBUG: User chats updated: ${chats.length}');
        setState(() {
          _chats = chats;
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor; // Same as header/footer

    // Create a AuraUser object from UserProfile for AuraBar
    final aura_models.AuraUser? currentUserForAuraBar = widget.currentUserProfile != null
        ? aura_models.AuraUser(
            id: widget.currentUserProfile!.id,
            name: widget.currentUserProfile!.displayName ?? widget.currentUserProfile!.username ?? 'You',
            avatarUrl: widget.currentUserProfile!.avatarUrl,
          )
        : null;

    // Extract connected user IDs from active chats
    final List<String> connectedUserIds = _chats
        .expand((chat) => chat.participants)
        .where((id) => id != widget.currentUserProfile?.id)
        .toSet() // Use toSet to get unique IDs
        .toList();

    return CustomScrollView( // Removed ScrollConfiguration wrapper
      slivers: [
        if (currentUserForAuraBar != null) // Conditionally show AuraBar
          SliverToBoxAdapter(
            child: AuraBar(
              currentUser: currentUserForAuraBar,
              connectedUserIds: connectedUserIds, // Pass the extracted connected user IDs
            ),
          ),
        // Display Received Requests
        if (_receivedRequests.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Received Requests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final request = _receivedRequests[index];
              return _buildRequestListItem(context, request, isSent: false);
            },
            childCount: _receivedRequests.length,
          ),
        ),
        // Display Sent Requests
        if (_sentRequests.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Sent Requests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final request = _sentRequests[index];
              return _buildRequestListItem(context, request, isSent: true);
            },
            childCount: _sentRequests.length,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Chats',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final chat = _chats[index];
              final otherParticipantId = chat.participants.firstWhere(
                (id) => id != widget.currentUserProfile!.id,
                orElse: () => 'Unknown',
              );

              return FutureBuilder<UserProfile?>(
                future: _userService.getUserById(otherParticipantId),
                builder: (context, snapshot) {
                  print('DEBUG: ChatListScreen - FutureBuilder for chat ${chat.id} - ConnectionState: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, HasError: ${snapshot.hasError}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print('DEBUG: ChatListScreen - FutureBuilder for chat ${chat.id} - Waiting for user profile.');
                    return ListTile(
                      leading: DefaultAvatar(radius: 28, name: 'Loading'),
                      title: Text('Loading...'),
                      subtitle: Text(chat.lastMessageText ?? 'No messages yet.'),
                    );
                  } else if (snapshot.hasError) {
                    print('DEBUG: ChatListScreen - Error fetching participant for chat ${chat.id}: ${snapshot.error}');
                    return ListTile(
                      leading: DefaultAvatar(radius: 28, name: 'Error'),
                      title: Text('Error'),
                      subtitle: Text(chat.lastMessageText ?? 'No messages yet.'),
                    );
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final otherUser = snapshot.data!;
                    print('DEBUG: ChatListScreen - Displaying chat ${chat.id} with user: ${otherUser.displayName}');
                    return Container(
                      color: backgroundColor,
                      child: ListTile(
                        tileColor: backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: DefaultAvatar(
                          radius: 28,
                          avatarUrl: otherUser.avatarUrl,
                          name: otherUser.displayName,
                        ),
                        title: Text(
                          otherUser.displayName,
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                        subtitle: Text(
                          chat.lastMessageText ?? 'No messages yet.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
                        ),
                        trailing: Text(
                          chat.lastMessageTimestamp != null
                              ? (chat.lastMessageTimestamp!).toDate().toLocal().toString().split(' ')[1].substring(0, 5)
                              : '',
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6)),
                        ),
                        onTap: () {
                          Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chatId: chat.id!, currentUserProfile: widget.currentUserProfile), // Pass currentUserProfile
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;

                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                          ));
                        },
                      ),
                    );
                  } else {
                    print('DEBUG: ChatListScreen - FutureBuilder for chat ${chat.id} - No data or null data for user profile.');
                    return ListTile(
                      leading: DefaultAvatar(radius: 28, name: 'Unknown'),
                      title: Text('Unknown User'),
                      subtitle: Text(chat.lastMessageText ?? 'No messages yet.'),
                    );
                  }
                },
              );
            },
            childCount: _chats.length,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestListItem(BuildContext context, ChatRequest request, {required bool isSent}) {
    final targetUserId = isSent ? request.receiverId : request.senderId;

    return FutureBuilder<UserProfile?>( // Use FutureBuilder to fetch user details
      future: _userService.getUserById(targetUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: DefaultAvatar(radius: 28, name: 'Loading'),
            title: Text('Loading...'),
            subtitle: Text(isSent ? 'Request Sent' : 'Request Received'),
          );
        } else if (snapshot.hasError) {
          print('Error fetching user for request: ${snapshot.error}');
          return ListTile(
            leading: DefaultAvatar(radius: 28, name: 'Error'),
            title: Text('Error'),
            subtitle: Text(isSent ? 'Request Sent' : 'Request Received'),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          final String userName = user.displayName;
          final String userIdentifier = user.username != null && user.username!.isNotEmpty
              ? '@${user.username}'
              : user.email ?? '';

          return ListTile(
            leading: DefaultAvatar(
              radius: 28,
              avatarUrl: user.avatarUrl,
              name: user.displayName,
            ),
            title: Text(
              userName,
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
            ),
            subtitle: Text( // Simplified subtitle further
              isSent ? 'Request Sent' : '',
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
            ),
            trailing: _buildRequestTrailingWidget(context, request, isSent), // Use a helper method for trailing widget
            onTap: () {
              // Navigate to user profile or chat details with custom animation
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => UserProfileScreen(userId: user.id, currentUserId: widget.currentUserProfile!.id),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0); // Start from right
                  const end = Offset.zero;
                  const curve = Curves.ease;

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
              ));
            },
          );
        } else {
          return ListTile(
            leading: DefaultAvatar(radius: 28, name: 'Unknown'),
            title: Text('Unknown User'),
            subtitle: Text(isSent ? 'Request Sent' : 'Request Received'),
          );
        }
      },
    );
  }

  Widget _buildRequestTrailingWidget(BuildContext context, ChatRequest request, bool isSent) {
    if (request.status == ChatRequestStatus.pending || request.status == ChatRequestStatus.awaiting_action) {
      return isSent
          ? ElevatedButton(
              onPressed: () async {
                // Handle cancel sent request
                print('Cancel sent request to ${request.receiverId}');
                try {
                  await _userService.cancelChatRequest(request);
                } catch (e) {
                  print('Error cancelling request: $e');
                  // Show error to user
                }
              },
              child: const Text('Cancel'),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    // Handle accept received request
                    print('Accept request from ${request.senderId}');
                    try {
                      String newChatId = await _userService.acceptChatRequest(request);
                      // Navigate to the new chat screen immediately
                      Navigator.of(context).push(PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chatId: newChatId, currentUserProfile: widget.currentUserProfile), // Pass currentUserProfile
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.ease;

                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                      ));
                    } catch (e) {
                      print('Error accepting request: $e');
                      // Show error to user
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: () async {
                    // Handle decline received request
                    print('Decline request from ${request.senderId}');
                    try {
                      await _userService.declineChatRequest(request);
                    } catch (e) {
                      print('Error declining request: $e');
                      // Show error to user
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Decline'),
                ),
              ],
            );
    } else if (request.status == ChatRequestStatus.accepted) {
      return Text('Accepted', style: TextStyle(color: Theme.of(context).colorScheme.primary));
    } else if (request.status == ChatRequestStatus.rejected) {
      return Text('Declined', style: TextStyle(color: Theme.of(context).colorScheme.error));
    } else if (request.status == ChatRequestStatus.none) {
      return Text('No Action', style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6)));
    }
    return const SizedBox.shrink(); // Default empty widget
  }
}