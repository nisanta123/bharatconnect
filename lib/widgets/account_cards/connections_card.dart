import 'package:flutter/material.dart';
import 'package:bharatconnect/services/user_service.dart';
import 'package:bharatconnect/models/chat_models.dart';
import 'package:bharatconnect/models/user_profile_model.dart';
import 'package:bharatconnect/widgets/default_avatar.dart';
import 'dart:async';
import 'package:bharatconnect/screens/chat_page.dart';

class ConnectionsCard extends StatefulWidget {
  final String currentUserId;
  const ConnectionsCard({super.key, required this.currentUserId});

  @override
  State<ConnectionsCard> createState() => _ConnectionsCardState();
}

class _ConnectionsCardState extends State<ConnectionsCard> {
  final UserService _userService = UserService();
  List<Chat> _connectedChats = [];
  StreamSubscription? _sub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.currentUserId.isNotEmpty) {
      _sub = _userService.streamUserChats(widget.currentUserId).listen((chats) {
        setState(() {
          _connectedChats = chats.where((chat) => chat.requestStatus == ChatRequestStatus.accepted || chat.requestStatus == ChatRequestStatus.none || chat.requestStatus == null).toList();
          _loading = false;
        });
      }, onError: (e) {
        print('ConnectionsCard stream error: $e');
        setState(() {
          _loading = false;
        });
      });
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Connections',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_connectedChats.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_alt,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No active connections found.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start chatting with people to see them here!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _connectedChats.length,
                separatorBuilder: (context, index) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final chat = _connectedChats[index];
                  final otherParticipantId = chat.participants.firstWhere((id) => id != widget.currentUserId, orElse: () => 'Unknown');
                  return FutureBuilder<UserProfile?>(
                    future: _userService.getUserById(otherParticipantId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          leading: DefaultAvatar(radius: 28, name: 'Loading'),
                          title: const Text('Loading...'),
                        );
                      } else if (snapshot.hasError) {
                        return ListTile(
                          leading: DefaultAvatar(radius: 28, name: 'Error'),
                          title: const Text('Error loading user'),
                        );
                      } else if (snapshot.hasData && snapshot.data != null) {
                        final connectedUser = snapshot.data!;
                        return ListTile(
                          leading: DefaultAvatar(
                            radius: 28,
                            avatarUrl: connectedUser.avatarUrl,
                            name: connectedUser.displayName,
                          ),
                          title: Text(connectedUser.displayName),
                          subtitle: Text('@${connectedUser.username ?? connectedUser.email}'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ChatPage(chatId: chat.id, currentUserProfile: null),
                            ));
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}