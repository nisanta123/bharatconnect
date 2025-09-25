import 'package:flutter/material.dart';
import 'package:bharatconnect/screens/chat_list_screen.dart';
import 'package:bharatconnect/screens/status_screen.dart';
import 'package:bharatconnect/screens/calls_screen.dart';
import 'package:bharatconnect/screens/search_screen.dart';
import 'package:bharatconnect/screens/account_screen.dart';
import 'package:bharatconnect/widgets/aura_bar.dart';
import 'package:bharatconnect/models/aura_models.dart' as aura_models; // Alias aura_models
// import 'package:firebase_core/firebase_core.dart';
// import 'package:bharatconnect/firebase_options.dart';
// import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias firebase_auth
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:bharatconnect/models/user_profile_model.dart'; // Add this import
import 'package:bharatconnect/screens/login_screen.dart'; // Update import
import 'package:bharatconnect/screens/profile_setup_screen.dart'; // Add this import
import 'package:bharatconnect/screens/signup_screen.dart'; // Import SignupScreen

void main() { // Mark main as async
  // WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // ); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BharatConnect',
      theme: ThemeData(
        brightness: Brightness.dark, // Overall dark theme
        scaffoldBackgroundColor: const Color(0xFF121212), // --background
        cardColor: const Color(0xFF121212),  // unify with scaffold
        dialogBackgroundColor: const Color(0xFF121212), // same background for dialogs
        canvasColor: const Color(0xFF121212), // same for sheets
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF42A5F5), // --primary
          onPrimary: Color(0xFFFAFAFA), // --primary-foreground
          secondary: Color(0xFFAB47BC), // --accent
          onSecondary: Color(0xFFFAFAFA), // --accent-foreground
          background: Color(0xFF121212), // --background
          onBackground: Color(0xFFFAFAFA), // --foreground
          surface: Color(0xFF121212), // unified with scaffold
          onSurface: Color(0xFFFAFAFA), // --card-foreground
          error: Color(0xFFE04444), // --destructive
          onError: Color(0xFFFAFAFA), // --destructive-foreground
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF121212), // unified
          foregroundColor: Color(0xFFFAFAFA), // --foreground
          elevation: 0, // No shadow
          surfaceTintColor: Colors.transparent, // Prevent color change on scroll
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFFFAFAFA), // --foreground
          unselectedLabelColor: Color(0xFF999999), // --muted-foreground
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: Color(0xFF42A5F5), width: 2.0), // --primary
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFAB47BC), // Using --accent for FAB
          foregroundColor: Color(0xFFFAFAFA), // --accent-foreground
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFFAFAFA)),
          bodyMedium: TextStyle(color: Color(0xFFFAFAFA)),
          titleLarge: TextStyle(color: Color(0xFFFAFAFA)),
          titleMedium: TextStyle(color: Color(0xFFFAFAFA)),
          titleSmall: TextStyle(color: Color(0xFFFAFAFA)),
          labelLarge: TextStyle(color: Color(0xFFFAFAFA)),
          labelMedium: TextStyle(color: Color(0xFFFAFAFA)),
          labelSmall: TextStyle(color: Color(0xFFFAFAFA)),
        ).apply(
          bodyColor: const Color(0xFFFAFAFA),
          displayColor: const Color(0xFFFAFAFA),
        ),
        dividerColor: Colors.transparent, // Set dividerColor to transparent
        inputDecorationTheme: InputDecorationTheme(
          fillColor: const Color(0xFF1F1F1F), // --input
          labelStyle: const TextStyle(color: Color(0xFFFAFAFA)),
          hintStyle: TextStyle(color: const Color(0xFFFAFAFA).withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF333333)), // --border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF333333)), // --border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Color(0xFFAB47BC)), // --accent for focus
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF121212), // unified
        ),
      ),
      home: SignupScreen(), // Directly navigate to SignupScreen
    );
  }
}

class WhatsAppHome extends StatefulWidget {
  const WhatsAppHome({super.key});

  @override
  State<WhatsAppHome> createState() => _WhatsAppHomeState();
}

class _WhatsAppHomeState extends State<WhatsAppHome> {
  int _selectedIndex = 0;
  late PageController _pageController;
  // UserProfile? _currentUserProfile; // Store the fetched user profile

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // _fetchCurrentUserProfile(); // Fetch user profile on init
  }

  // Future<void> _fetchCurrentUserProfile() async {
  //   final user = fb_auth.FirebaseAuth.instance.currentUser; // Use fb_auth.FirebaseAuth
  //   if (user != null) {
  //     final doc = await FirebaseFirestore.instance.collection('bharatConnectUsers').doc(user.uid).get();
  //     if (doc.exists) {
  //       setState(() {
  //         _currentUserProfile = UserProfile.fromFirestore(doc);
  //       });
  //     }
  //   }
  // }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Mock Data for AuraBar
  // Use fetched user profile for _currentUser
  // final User _currentUser = User(id: '1', name: 'You', avatarUrl: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=U');
  final List<String> _connectedUserIds = ['2', '3']; // Keep mock for now
  final List<aura_models.DisplayAura> _allDisplayAuras = [
    // Use fetched user profile for the current user's aura
    // aura_models.DisplayAura(
    //   userId: '1', userName: 'You', userProfileAvatarUrl: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=U', auraImageUrl: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=A1', auraId: 'aura1',
    // ),
    // Keep other mock auras for now
    aura_models.DisplayAura(
      id: 'mock_aura_id_2', // Added id
      userId: '2', userName: 'Alice', userProfileAvatarUrl: 'https://via.placeholder.com/150/0000FF/FFFFFF?text=A',
      auraOptionId: 'aura2', // Use auraOptionId
      createdAt: DateTime.now(), // Provide a DateTime
      auraStyle: aura_models.AURA_OPTIONS.firstWhere((e) => e.id == 'water'), // Example auraStyle
    ),
    aura_models.DisplayAura(
      id: 'mock_aura_id_3', // Added id
      userId: '3', userName: 'Bob', userProfileAvatarUrl: 'https://via.placeholder.com/150/00FF00/FFFFFF?text=B',
      auraOptionId: 'aura3', // Use auraOptionId
      createdAt: DateTime.now(), // Provide a DateTime
      auraStyle: aura_models.AURA_OPTIONS.firstWhere((e) => e.id == 'earth'), // Example auraStyle
    ),
    aura_models.DisplayAura(
      id: 'mock_aura_id_4', // Added id
      userId: '4', userName: 'Charlie', userProfileAvatarUrl: 'https://via.placeholder.com/150/FFFF00/000000?text=C',
      auraOptionId: 'aura4', // Use auraOptionId
      createdAt: DateTime.now(), // Provide a DateTime
      auraStyle: aura_models.AURA_OPTIONS.firstWhere((e) => e.id == 'fire'), // Example auraStyle
    ),
  ];
  bool _isLoadingAuras = false; // Set to true to test loading state

  final List<Widget> _widgetOptions = <Widget>[
    ChatListScreen(), // Removed const
    const SearchScreen(), // Use the new SearchScreen widget
    const StatusScreen(), // Now StatusScreen is const again, as its internal issues are fixed.
    const CallsScreen(),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300), // Smooth animation duration
        curve: Curves.ease, // Animation curve
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Display a loading indicator if user profile is not yet fetched
    // if (_currentUserProfile == null) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

    // Create a AuraUser object from UserProfile for AuraBar
    final aura_models.AuraUser currentUserForAuraBar = aura_models.AuraUser( // Explicitly use AuraUser from aura_models.dart
      id: 'mock_user_id', // Placeholder ID
      name: 'You', // Placeholder name
      avatarUrl: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=U', // Placeholder avatar
    );

    // Update _allDisplayAuras to include the current user's aura dynamically
    final List<aura_models.DisplayAura> updatedDisplayAuras = [
      aura_models.DisplayAura(
        id: 'mock_aura_id_1', // Added id
        userId: currentUserForAuraBar.id,
        userName: currentUserForAuraBar.name,
        userProfileAvatarUrl: currentUserForAuraBar.avatarUrl ?? '', // Handle nullability
        auraOptionId: 'aura1', // Placeholder aura option ID
        createdAt: DateTime.now(), // Provide a DateTime
        auraStyle: aura_models.AURA_OPTIONS.firstWhere((e) => e.id == 'fire'), // Example auraStyle
      ),
      // Add other mock auras here if needed, or fetch them from Firestore
      ..._allDisplayAuras.where((aura) => (aura as aura_models.DisplayAura).userId != currentUserForAuraBar.id).toList(), // Explicit cast
    ];

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF42A5F5), // Primary Blue
              Color(0xFFAB47BC), // Accent Violet
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'BharatConnect',
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 30, // Increased font size to 30px (Medium size)
              fontWeight: FontWeight.bold,
              color: Colors.white, // This color will be masked by the gradient
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFFFAFAFA)), // Bell icon
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFFAFAFA)), // Three dots menu
            onPressed: () {},
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
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
