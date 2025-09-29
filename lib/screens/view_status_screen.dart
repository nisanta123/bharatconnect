import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/services/status_service.dart';
import 'package:bharatconnect/models/status_model.dart';
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile
import 'package:bharatconnect/widgets/default_avatar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class _ViewStatusScreenState extends State<ViewStatusScreen> with SingleTickerProviderStateMixin {
  final StatusService _statusService = StatusService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Status> _statuses = [];
  UserProfile? _ownerProfile;
  UserProfile? _currentUserProfile; // To store the current user's profile
  bool _isLoading = true;
  String? _errorMessage;
  bool _isHolding = false; // Flag to track long-press state

  late AnimationController _progressController;
  int _currentIndex = 0;
  // duration per status (seconds) — short for demo; can be tied to content length
  static const int _perStatusSeconds = 6;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: _perStatusSeconds))
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _handleNext();
        }
      })
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _fetchInitialData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch current user's profile
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final currentUserDoc = await _statusService.userProfilesCollection.doc(currentUser.uid).get();
        if (currentUserDoc.exists) {
          _currentUserProfile = UserProfile.fromFirestore(currentUserDoc);
        } else {
          // Fallback to create a profile from the auth user if the document doesn't exist
          _currentUserProfile = UserProfile(
            id: currentUser.uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName ?? '',
            username: null, // Not available from auth user object
            avatarUrl: currentUser.photoURL,
          );
        }
      }

      // Fetch owner profile
      final userProfileDoc = await _statusService.userProfilesCollection.doc(widget.userId).get();
      if (userProfileDoc.exists) {
        _ownerProfile = UserProfile.fromFirestore(userProfileDoc);
      }

      // Fetch all statuses for this user ordered by createdAt ascending so index 0 is first
      final snapshot = await _status_service_query(widget.userId);
      final docs = snapshot.docs;
      _statuses = docs.map((d) => Status.fromFirestore(d)).toList();

      // Find initial index from provided statusId
      final startIndex = _statuses.indexWhere((s) => s.id == widget.statusId);
      _currentIndex = startIndex >= 0 ? startIndex : 0;

      // Start progress animation
      _startProgress();

      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load statuses: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _status_service_query(String userId) async {
    // Avoid range queries on multiple fields (expiresAt + createdAt) which require composite indexes.
    // Instead fetch statuses for the user ordered by createdAt and filter expired ones client-side.
    return await _statusService.statusesCollection.where('userId', isEqualTo: userId).orderBy('createdAt').get();
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();

    // Record the view, including the owner's
    if (_currentUserProfile != null) {
      final currentStatus = _statuses[_currentIndex];
      _statusService.recordStatusView(currentStatus.id, _currentUserProfile!);
    }
  }

  void _handleNext() {
    if (_currentIndex < _statuses.length - 1) {
      setState(() => _currentIndex += 1);
      _startProgress();
    } else {
      // At end: pop to previous screen
      Navigator.of(context).pop();
    }
  }

  void _handlePrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex -= 1);
      _startProgress();
    } else {
      Navigator.of(context).pop();
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

    if (_statuses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status')),
        body: const Center(child: Text('No statuses available.')),
      );
    }

    final currentStatus = _statuses[_currentIndex];
    final owner = _ownerProfile ?? UserProfile(id: currentStatus.userId, email: '', displayName: '');
    final displayStatus = DisplayStatus.fromStatusAndUserProfile(status: currentStatus, userProfile: owner, viewedByCurrentUser: true);

    // Parse background color from string to Color
    Color backgroundColor = Colors.black; // Default if not specified or invalid
    if (displayStatus.backgroundColor != null) {
      try {
        final raw = displayStatus.backgroundColor!;
        // allow both hex strings with or without leading 0x/#
        var hex = raw.replaceAll('#', '').replaceAll('0x', '');
        if (hex.length == 6) hex = 'FF$hex'; // add alpha if missing
        backgroundColor = Color(int.parse(hex, radix: 16));
      } catch (e) {
        // ignore and use default
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (_isHolding) return; // ignore taps if holding
          final w = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < w / 2) {
            _handlePrevious();
          } else {
            _handleNext();
          }
        },
        onLongPressStart: (_) {
          _isHolding = true;
          _progressController.stop();
        },
        onLongPressEnd: (_) {
          _isHolding = false;
          _progressController.forward();
        },
        onVerticalDragUpdate: (details) {
          // If viewing own status, allow swipe up to see viewers
          if (_currentUserProfile != null &&
              widget.userId == _currentUserProfile!.id &&
              details.primaryDelta! < -10) { // A negative delta indicates a swipe up
            _showViewers(context, currentStatus.id);
          }
        },
        child: Stack(
          children: [
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  displayStatus.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    displayStatus.fontFamily ?? 'Roboto',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Top: segmented progress bars + user info
            SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Row(
                      children: _buildProgressSegments(),
                    ),
                  ),
                  // user row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        DefaultAvatar(radius: 18, avatarUrl: displayStatus.userAvatarUrl, name: displayStatus.userName),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayStatus.userName, style: const TextStyle(color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(
                                '${displayStatus.createdAt.hour.toString().padLeft(2, '0')}:${displayStatus.createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom: View count for own status
            if (_currentUserProfile != null && widget.userId == _currentUserProfile!.id)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.remove_red_eye, color: Colors.white),
                      const SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: _statusService.getStatusViews(currentStatus.id),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Text('0', style: TextStyle(color: Colors.white));
                          }
                          final viewCount = snapshot.data!.docs.length;
                          return Text(
                            '$viewCount',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showViewers(BuildContext context, String statusId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Viewed by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _statusService.getStatusViews(statusId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No views yet.'));
                    }

                    final viewers = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: viewers.length,
                      itemBuilder: (context, index) {
                        final viewerData = viewers[index].data() as Map<String, dynamic>;
                        final isCurrentUser = viewerData['viewerId'] == _currentUserProfile?.id;

                        return ListTile(
                          leading: DefaultAvatar(
                            radius: 20,
                            avatarUrl: viewerData['viewerAvatarUrl'],
                            name: viewerData['viewerName'],
                          ),
                          title: Text(isCurrentUser ? 'You' : viewerData['viewerName'] ?? 'Unknown'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildProgressSegments() {
    final total = _statuses.length;
    return List.generate(total, (i) {
      double fill = 0.0;
      if (i < _currentIndex) {
        fill = 1.0;
      } else if (i == _currentIndex) {
        fill = _progressController.value;
      } else {
        fill = 0.0;
      }

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: SizedBox(
            height: 3,
            child: Stack(
              children: [
                Container(decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fill.clamp(0.0, 1.0),
                  child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
