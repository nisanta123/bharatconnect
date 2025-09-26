import 'package:flutter/material.dart';
import 'package:bharatconnect/screens/chat_list_screen.dart';
import 'package:bharatconnect/screens/status_screen.dart';
import 'package:bharatconnect/screens/calls_screen.dart';
import 'package:bharatconnect/screens/search_screen.dart';
import 'package:bharatconnect/screens/account_screen.dart';
import 'package:bharatconnect/widgets/aura_bar.dart';
import 'package:bharatconnect/models/aura_models.dart' as aura_models; // Alias aura_models
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Re-added Firebase Auth import
import 'package:cloud_firestore/cloud_firestore.dart'; // Re-added Cloud Firestore import
import 'package:bharatconnect/models/user_profile_model.dart'; // Add this import
import 'package:bharatconnect/widgets/logo.dart'; // Import the Logo widget
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts
import 'package:bharatconnect/widgets/custom_toast.dart'; // Import CustomToast

class HomeScreen extends StatefulWidget { // Renamed from WhatsAppHome
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState(); // Renamed state class
}

class _HomeScreenState extends State<HomeScreen> { // Renamed from _WhatsAppHomeState
  int _selectedIndex = 0;
  late PageController _pageController;
  UserProfile? _currentUserProfile; // Store the fetched user profile

  bool _isLoadingAuras = false; // Set to true to test loading state

  final List<Widget> _widgetOptions = <Widget>[
    ChatListScreen(),
    SearchScreen(),
    StatusScreen(),
    CallsScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _fetchCurrentUserProfile(); // Fetch user profile on init
  }

  Future<void> _fetchCurrentUserProfile() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser; // Use fb_auth.FirebaseAuth
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('bharatConnectUsers').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _currentUserProfile = UserProfile.fromFirestore(doc);
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300), // Smooth animation duration
        curve: Curves.easeInOut, // Changed to Curves.easeInOut for smoother transition
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Display a loading indicator if user profile is not yet fetched
    if (_currentUserProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Create a AuraUser object from UserProfile for AuraBar
    final aura_models.AuraUser currentUserForAuraBar = aura_models.AuraUser( // Explicitly use AuraUser from aura_models.dart
      id: _currentUserProfile!.id,
      name: _currentUserProfile!.displayName ?? _currentUserProfile!.username ?? 'You',
      avatarUrl: _currentUserProfile!.avatarUrl,
    );

    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar(
        title: const Logo(size: "medium"), // Using the Logo widget
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFFFAFAFA)), // Bell icon
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFFAFAFA)), // Three dots menu
            onPressed: () {
              showCustomToast(context, "More options clicked!"); // Trigger custom toast
            },
          ),
        ],
      ) : null, // AppBar is null for other pages
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions.map((widgetOption) {
          if (widgetOption is ChatListScreen) {
            return ChatListScreen(currentUserProfile: _currentUserProfile); // Pass currentUserProfile
          }
          return widgetOption;
        }).toList(),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF42A5F5), // Primary Blue
              Color(0xFFAB47BC), // Accent Violet
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50.0), // Adjust as needed for FAB shape
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent, // Make FAB background transparent
          elevation: 0, // Remove elevation to show gradient fully
          child: const Icon(Icons.add, color: Colors.white), // Plus icon
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call_outlined),
            activeIcon: Icon(Icons.call),
            label: 'Calls',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary, // Primary color for selected item
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // Muted foreground for unselected
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // To show all labels
        backgroundColor: Theme.of(context).cardColor, // Card color for background
      ),
    );
  }
}