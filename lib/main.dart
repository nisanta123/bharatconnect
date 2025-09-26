import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Re-added Firebase Core import
import 'package:bharatconnect/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Re-added Firebase Auth import
import 'package:cloud_firestore/cloud_firestore.dart'; // Re-added Cloud Firestore import
import 'package:bharatconnect/models/user_profile_model.dart'; // Add this import
import 'package:bharatconnect/screens/login_screen.dart'; // Update import
import 'package:bharatconnect/screens/profile_setup_screen.dart'; // Add this import
import 'package:bharatconnect/screens/signup_screen.dart'; // Import SignupScreen
import 'package:bharatconnect/screens/home_screen.dart'; // Import HomeScreen
import 'package:bharatconnect/utils/no_scrollbar_behavior.dart'; // Import NoScrollbarBehavior

void main() async { // Mark main as async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print('Firebase app already initialized. Skipping.');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('MyApp: build method called.');
    return MaterialApp(
      title: 'BharatConnect',
      scrollBehavior: NoScrollbarBehavior(), // Apply custom scroll behavior globally
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
      ), // Closing parenthesis for ThemeData
      home: StreamBuilder<fb_auth.User?>( // Use fb_auth.User
        stream: fb_auth.FirebaseAuth.instance.authStateChanges(), // Use fb_auth.FirebaseAuth
        builder: (context, authSnapshot) {
          print('MyApp: StreamBuilder - Auth ConnectionState: ${authSnapshot.connectionState}');
          print('MyApp: StreamBuilder - Auth Has Data: ${authSnapshot.hasData}');
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            print('MyApp: StreamBuilder - Auth ConnectionState: waiting');
            return const Center(child: CircularProgressIndicator());
          }
          if (authSnapshot.hasData) {
            print('MyApp: StreamBuilder - User is logged in: ${authSnapshot.data!.uid}');
            // User is logged in, now check their profile status
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('bharatConnectUsers')
                  .doc(authSnapshot.data!.uid)
                  .get(),
              builder: (context, userProfileSnapshot) {
                print('MyApp: FutureBuilder - UserProfile ConnectionState: ${userProfileSnapshot.connectionState}');
                print('MyApp: FutureBuilder - UserProfile Has Data: ${userProfileSnapshot.hasData}');
                print('MyApp: FutureBuilder - UserProfile Data Exists: ${userProfileSnapshot.data?.exists}');
                if (userProfileSnapshot.connectionState == ConnectionState.waiting) {
                  print('MyApp: FutureBuilder - UserProfile ConnectionState: waiting');
                  return const Center(child: CircularProgressIndicator());
                }
                if (userProfileSnapshot.hasData && userProfileSnapshot.data!.exists) {
                  final userProfile = UserProfile.fromFirestore(userProfileSnapshot.data!); // Use fromFirestore
                  print('MyApp: UserProfile onboardingComplete: ${userProfile.onboardingComplete}');
                  if (userProfile.onboardingComplete) {
                    print('MyApp: Navigating to HomeScreen.'); // Updated navigation
                    return HomeScreen(); // Now refers to the rich home screen
                  } else {
                    print('MyApp: Navigating to ProfileSetupScreen.');
                    return ProfileSetupScreen(user: authSnapshot.data!); // Pass the user object
                  }
                } else {
                  print('MyApp: User authenticated but no profile or incomplete profile. Navigating to ProfileSetupScreen.');
                  // User is authenticated but no profile found (shouldn't happen if signup creates it)
                  // Or profile data is incomplete/corrupted
                  return ProfileSetupScreen(user: authSnapshot.data!); // Pass the user object
                }
              },
            );
          } else {
            print('MyApp: No user logged in. Navigating to LoginScreen.');
            // No user logged in
            return const LoginScreen(); // Show the LoginScreen
          }
        },
      ),
    ); // Closing parenthesis for MaterialApp
  }
}
