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
import 'package:bharatconnect/screens/splash_screen.dart'; // Import the SplashScreen
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BharatConnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark), // Enforce dark theme
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Set SplashScreen as the initial screen
      routes: {
        // Define other routes if necessary
        // '/login': (context) => const LoginScreen(),
        // '/home': (context) => const HomeScreen(),
      },
    );
  }
}
