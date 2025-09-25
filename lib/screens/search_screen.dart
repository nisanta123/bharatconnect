import 'package:flutter/material.dart';
import 'package:bharatconnect/models/search_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResultUser> _searchResults = [];
  bool _isSearching = false;

  // Mock data for demonstration
  final User _currentUser = User(id: '1', name: 'You', avatarUrl: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=U');
  final List<SearchResultUser> _mockSearchResults = [
    SearchResultUser(
      id: '2', name: 'Alice', username: 'alice_u', avatarUrl: 'https://via.placeholder.com/150/0000FF/FFFFFF?text=A',
      requestUiStatus: UserRequestStatus.idle,
    ),
    SearchResultUser(
      id: '3', name: 'Bob', username: 'bob_u', avatarUrl: 'https://via.placeholder.com/150/00FF00/FFFFFF?text=B',
      requestUiStatus: UserRequestStatus.request_sent,
    ),
    SearchResultUser(
      id: '4', name: 'Charlie', username: 'charlie_u', avatarUrl: 'https://via.placeholder.com/150/FFFF00/000000?text=C',
      requestUiStatus: UserRequestStatus.chat_exists,
    ),
    SearchResultUser(
      id: '5', name: 'David', username: 'david_u', avatarUrl: 'https://via.placeholder.com/150/FF00FF/FFFFFF?text=D',
      requestUiStatus: UserRequestStatus.on_cooldown, cooldownEndsAt: DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // For now, just update the UI with mock results based on search term presence
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      if (_searchController.text.isNotEmpty) {
        _searchResults = _mockSearchResults.where((user) =>
            user.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (user.username?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)
        ).toList();
      } else {
        _searchResults = [];
      }
    });
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
    if (user.id == _currentUser.id) {
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
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer),
          child: const Text('Request Sent', style: TextStyle(color: Colors.white70)),
        );
      case UserRequestStatus.chat_exists:
        return OutlinedButton(
          onPressed: () {
            // Handle open chat
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
        return ElevatedButton.icon(
          onPressed: () {
            // Handle send request
            print('Send request to ${user.name}');
          },
          icon: const Icon(Icons.send, size: 16),
          label: const Text('Send Request'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                        ? NetworkImage(user.avatarUrl!)
                                        : null,
                                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                        ? const Icon(Icons.person, size: 30)
                                        : null,
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