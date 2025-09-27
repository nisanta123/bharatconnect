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
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar

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

  List<Widget> _widgetOptions = <Widget>[];

  @override
  void initState() {
    super.initState();
    print('HomeScreen: initState called.'); // Updated print
    _pageController = PageController(initialPage: _selectedIndex);
    _fetchCurrentUserProfile(); // Fetch user profile on init
  }

  Future<void> _fetchCurrentUserProfile() async {
    print('HomeScreen: _fetchCurrentUserProfile started.'); // Updated print
    final user = fb_auth.FirebaseAuth.instance.currentUser; // Use fb_auth.FirebaseAuth
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('bharatConnectUsers').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _currentUserProfile = UserProfile.fromFirestore(doc);
          _widgetOptions = <Widget>[
            ChatListScreen(currentUserProfile: _currentUserProfile), // Pass currentUserProfile
            SearchScreen(currentUserId: _currentUserProfile!.id), // Pass current user ID
            StatusScreen(),
            CallsScreen(),
            AccountScreen(),
          ];
        });
        print('HomeScreen: User profile fetched: ${_currentUserProfile?.displayName}'); // Updated print
      } else {
        print('HomeScreen: User profile not found in Firestore.'); // Updated print
      }
    } else {
      print('HomeScreen: No user logged in for _fetchCurrentUserProfile.'); // Updated print
    }
  }

  @override
  void dispose() {
    print('HomeScreen: dispose called.'); // Updated print
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
    print('HomeScreen: build method called. _currentUserProfile is null: ${_currentUserProfile == null}');
    // Display a loading indicator if user profile is not yet fetched
    if (_currentUserProfile == null) {
      print('HomeScreen: Displaying CircularProgressIndicator because _currentUserProfile is null.');
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFFFAFAFA)),
            onSelected: (String result) async {
              if (result == 'logout') {
                await fb_auth.FirebaseAuth.instance.signOut();
                // The StreamBuilder in main.dart will handle navigation after logout.
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ) : null, // AppBar is null for other pages
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _widgetOptions.map((widgetOption) {
                if (widgetOption is ChatListScreen) {
                  return ChatListScreen(currentUserProfile: _currentUserProfile); // Pass currentUserProfile
                } else if (widgetOption is SearchScreen) {
                  return SearchScreen(currentUserId: _currentUserProfile!.id); // Pass current user ID
                }
                return widgetOption;
              }).toList(),
            ),
          ),
        ],
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