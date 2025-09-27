import 'package:flutter/material.dart';
import 'package:bharatconnect/services/status_service.dart';
import 'package:bharatconnect/models/status_model.dart';
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile
import 'package:bharatconnect/widgets/default_avatar.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewStatusScreen extends StatefulWidget {
  final String userId;
  final String statusId;

  const ViewStatusScreen({
    super.key,
    required this.userId,
    required this.statusId,
  });

  @override
  State<ViewStatusScreen> createState() => _ViewStatusScreenState();
}

class _ViewStatusScreenState extends State<ViewStatusScreen> {
  final StatusService _statusService = StatusService();
  DisplayStatus? _status;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // This is a simplified fetch. In a real app, you might fetch a stream
      // of statuses for a user and manage progress.
      final statusDoc = await _statusService.statusesCollection.doc(widget.statusId).get();
      if (!statusDoc.exists) {
        throw Exception('Status not found.');
      }
      final status = Status.fromFirestore(statusDoc);

      final userProfileDoc = await _statusService.userProfilesCollection.doc(widget.userId).get();
      if (!userProfileDoc.exists) {
        throw Exception('User profile not found for status owner.');
      }
      final userProfile = UserProfile.fromFirestore(userProfileDoc);

      setState(() {
        _status = DisplayStatus.fromStatusAndUserProfile(
          status: status,
          userProfile: userProfile,
          viewedByCurrentUser: true, // Assume viewed when opened
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_status == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status Not Found')),
        body: const Center(child: Text('Status data could not be loaded.')),
      );
    }

    // Parse background color from string to Color
    Color backgroundColor = Colors.black; // Default if not specified or invalid
    if (_status!.backgroundColor != null) {
      try {
        backgroundColor = Color(int.parse(_status!.backgroundColor!, radix: 16));
      } catch (e) {
        print('Error parsing background color: $e');
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Status content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _status!.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.getFont(
                  _status!.fontFamily ?? 'Roboto', // Use selected font or default
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Top bar with user info and progress (simplified for single status)
          Positioned( // Positioned at the top
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Row(
                children: [
                  DefaultAvatar(
                    radius: 18,
                    avatarUrl: _status!.userAvatarUrl,
                    name: _status!.userName,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _status!.userName,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_status!.createdAt.hour}:${_status!.createdAt.minute}', // Display time
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
