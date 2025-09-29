import 'package:flutter/material.dart';
import 'package:bharatconnect/services/user_service.dart'; // Import UserService
import 'package:bharatconnect/models/search_models.dart'; // Import User model
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile model
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar
import 'package:bharatconnect/widgets/custom_toast.dart'; // Use custom toast for notifications
// chat_models and chat_page imports removed; connections moved to Account Centre
// (removed unused dart:async import)

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String currentUserId; // Added currentUserId

  const UserProfileScreen({super.key, required this.userId, required this.currentUserId}); // Updated constructor

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  UserRequestStatus _chatStatus = UserRequestStatus.idle; // Added _chatStatus state

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = await _userService.getUserById(widget.userId);
      final status = await _userService.getChatStatus(widget.currentUserId, widget.userId); // Fetch chat status
      setState(() {
        _userProfile = user;
        _chatStatus = status; // Set chat status
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: _buildProfileTab(),
    );
  }

  Widget _buildProfileTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _userProfile == null
            ? const Center(child: Text('User not found.'))
            : Center( // Wrap with Center widget
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DefaultAvatar(
                        radius: 60,
                        avatarUrl: _userProfile!.avatarUrl,
                        name: _userProfile!.displayName,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userProfile!.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '@${_userProfile!.username ?? _userProfile!.email}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                      // const SizedBox(height: 16), // Removed
                      // _buildChatStatusButton(), // Removed the chat status button from profile tab
                      // Add more user details here as needed
                    ],
                  ),
                ),
              );
  }

  // Connections tab removed — connections are shown in Account Centre

  Widget _buildChatStatusButton() {
    switch (_chatStatus) {
      case UserRequestStatus.is_self:
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer),
          child: const Text('This is you', style: TextStyle(color: Colors.white70)),
        );
      case UserRequestStatus.on_cooldown:
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.access_time, size: 16, color: Colors.white70),
          label: const Text('On Cooldown', style: TextStyle(color: Colors.white70)), // You might want to add cooldownEndsAt here
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer),
        );
      case UserRequestStatus.request_sent:
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6)),
          child: const Text('Request Sent', style: TextStyle(color: Colors.white70)),
        );
      case UserRequestStatus.request_received:
        return OutlinedButton(
          onPressed: () {
            // Handle accepting the chat request
            print('Accept chat request from ${_userProfile!.displayName}');
            // Call a service method to accept the request
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.tertiary),
            foregroundColor: Theme.of(context).colorScheme.tertiary,
          ),
          child: const Text('Accept Request'),
        );
      case UserRequestStatus.chat_exists:
        return OutlinedButton(
          onPressed: () {
            // Handle open chat - navigate to chat page
            print('Open chat with ${_userProfile!.displayName}');
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
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ElevatedButton.icon(
            onPressed: () async {
              // Handle sending chat request
              print('Send chat request to ${_userProfile!.displayName}');
              await _userService.sendChatRequest(widget.currentUserId, widget.userId);
              // Refresh status after sending request
              _fetchUserProfile();
                showCustomToast(context, 'Chat request sent!');
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
        );
    }
  }
}
