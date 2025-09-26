import 'package:flutter/material.dart';
import 'package:bharatconnect/widgets/aura_bar.dart';
import 'package:bharatconnect/models/aura_models.dart' as aura_models; // Alias aura_models
import 'package:bharatconnect/screens/chat_page.dart'; // Corrected import path
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile

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

  // Mock Data for AuraBar
  // Removed _currentUser and _connectedUserIds as they are now passed from HomeScreen
  bool _isLoadingAuras = false; // Set to true to test loading state

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

    return CustomScrollView( // Removed ScrollConfiguration wrapper
      slivers: [
        if (currentUserForAuraBar != null) // Conditionally show AuraBar
          SliverToBoxAdapter(
            child: AuraBar(
              currentUser: currentUserForAuraBar,
              connectedUserIds: [], // AuraBar will fetch connected users internally
            ),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final chat = _mockChats[index];
              return Container(
                color: backgroundColor, // Match header/footer background
                child: ListTile(
                  tileColor: backgroundColor, // Force same background for tile
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: CircleAvatar(
                    radius: 28, // Increased from 25
                    backgroundColor: Colors.grey, // Consistent grey background
                    backgroundImage: chat['avatarUrl'] != null && chat['avatarUrl']!.isNotEmpty
                        ? NetworkImage(chat['avatarUrl']!)
                        : null,
                    child: chat['avatarUrl'] == null || chat['avatarUrl']!.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 35) // Adjusted icon size
                        : null,
                  ),
                  title: Text(
                    chat['name']!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                  ),
                  subtitle: Text(
                    chat['lastMessage']!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
                  ),
                  trailing: Text(
                    chat['time']!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6)),
                  ),
                  onTap: () {
                    Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chatId: chat['id']!),
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
                ),
              );
            },
            childCount: _mockChats.length,
          ),
        ),
      ],
    );
  }
}