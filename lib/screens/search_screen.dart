import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bharatconnect/models/search_models.dart';
import 'package:bharatconnect/services/user_service.dart';
import 'package:bharatconnect/models/aura_models.dart';
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar
import 'package:bharatconnect/screens/user_profile_screen.dart'; // Import UserProfileScreen

class SearchScreen extends StatefulWidget {
  final String currentUserId;
  const SearchScreen({super.key, required this.currentUserId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  List<SearchResultUser> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    print('SearchScreen: Performing search for query: $query');
    final fetchedUsers = await _userService.searchUsers(query);
    print('SearchScreen: Fetched ${fetchedUsers.length} users.');
    final List<SearchResultUser> results = [];

    for (var user in fetchedUsers) {
      print('SearchScreen: Processing user: ${user.name} (ID: ${user.id})');
      UserRequestStatus status = UserRequestStatus.idle; // Default status
      try {
        status = await _userService.getChatStatus(widget.currentUserId, user.id);
        print('SearchScreen: Chat status for ${user.name}: $status');
      } catch (e) {
        print('SearchScreen: Error getting chat status for ${user.name}: $e');
        // Optionally, set an error status or skip this user
      }

      results.add(SearchResultUser(
        id: user.id,
        name: user.name,
        username: user.username, // Ensure username is passed
        email: user.email, // Ensure email is passed
        avatarUrl: user.avatarUrl,
        requestUiStatus: status,
        // cooldownEndsAt: ... (implement cooldown logic if needed)
      ));
      print('SearchScreen: Added ${user.name} to search results.');
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
    print('SearchScreen: Search finished. Displaying ${results.length} results.');
  }

  Future<void> _sendChatRequest(String targetUserId) async {
    try {
      await _userService.sendChatRequest(widget.currentUserId, targetUserId);
      // After sending, refresh the search results to update the button status
      await _performSearch(_searchController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat request sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  String _formatCooldownTime(int endTimeMillis) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (endTimeMillis <= now) return "Send Request";

    final diff = endTimeMillis - now;
    final hours = (diff / (1000 * 60 * 60)).floor();
    final minutes = ((diff % (1000 * 60 * 60)) / (1000 * 60)).floor();

    if (hours > 0) {
      return "Wait ${hours}h ${minutes}m";
    }
    if (minutes > 0) {
      return "Wait ${minutes}m";
    }
    return "Wait <1m";
  }

  Widget _buildActionButton(SearchResultUser user) {
    if (user.id == widget.currentUserId) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer),
        child: const Text('This is you', style: TextStyle(color: Colors.white70)),
      );
    }

    switch (user.requestUiStatus) {
      case UserRequestStatus.on_cooldown:
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.access_time, size: 16, color: Colors.white70),
          label: Text(_formatCooldownTime(user.cooldownEndsAt!), style: const TextStyle(color: Colors.white70)),
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer),
        );
      case UserRequestStatus.request_sent:
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6)), // Added opacity for fade effect
          child: const Text('Request Sent', style: TextStyle(color: Colors.white70)),
        );
      case UserRequestStatus.request_received:
        return OutlinedButton(
          onPressed: () {
            // Handle accepting the chat request
            print('Accept chat request from ${user.name}');
            // You would typically call a service method here to accept the request
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.tertiary), // Use a different color for received requests
            foregroundColor: Theme.of(context).colorScheme.tertiary,
          ),
          child: const Text('Accept Request'),
        );
      case UserRequestStatus.chat_exists:
        return OutlinedButton(
          onPressed: () {
            // Handle open chat - navigate to chat page
            print('Open chat with ${user.name}');
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('Open Chat'),
        );
      case UserRequestStatus.idle:
      default:
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF42A5F5), // Primary Blue
                Color(0xFFAB47BC), // Accent Violet
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8.0), // Match button border radius
          ),
          child: ElevatedButton.icon(
            onPressed: () => _sendChatRequest(user.id),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Make button background transparent
              foregroundColor: Colors.white, // Ensure text/icon color is white for contrast
              shadowColor: Colors.transparent, // Remove shadow to show gradient fully
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Handle settings
              print('Settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or username',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
            ),
          ),
          _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Searching users...'),
                    ],
                  ),
                )
              : _searchResults.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final showUsername = user.username != null && user.username!.toLowerCase() != 'n/a';
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => UserProfileScreen(userId: user.id, currentUserId: widget.currentUserId), // Pass currentUserId
                              ));
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    DefaultAvatar(
                                      radius: 24,
                                      avatarUrl: user.avatarUrl,
                                      name: user.name,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: Theme.of(context).textTheme.titleMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (showUsername)
                                            Text(
                                              '@${user.username}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    _buildActionButton(user),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : _searchController.text.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(Icons.search, size: 60, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('Search for People', style: TextStyle(fontSize: 18)),
                              Text('Find and connect with others on BharatConnect.'),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text('No users found matching "${_searchController.text}".'),
                        ),
        ],
      ),
    );
  }
}