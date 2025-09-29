import 'package:flutter/material.dart';
import 'package:bharatconnect/widgets/page_header.dart';
import 'package:bharatconnect/widgets/account_cards/profile_card.dart';
import 'package:bharatconnect/widgets/account_cards/connections_card.dart';
import 'package:bharatconnect/widgets/account_cards/privacy_settings_card.dart';
import 'package:bharatconnect/widgets/account_cards/theme_settings_card.dart';
import 'package:bharatconnect/widgets/account_cards/language_settings_card.dart';
import 'package:bharatconnect/widgets/account_cards/security_settings_card.dart'; // Corrected import
import 'package:bharatconnect/widgets/account_cards/linked_apps_card.dart';
import 'package:bharatconnect/widgets/account_cards/advanced_options_card.dart';
import 'package:bharatconnect/widgets/account_cards/chat_backup_card.dart';
import 'package:bharatconnect/models/search_models.dart'; // For User model
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile model

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserProfile? _userProfile; // To store the fetched user profile
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not logged in.';
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('bharatConnectUsers').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userProfile = UserProfile.fromFirestore(doc);
        });
      } else {
        setState(() {
          _errorMessage = 'User profile not found in Firestore.';
        });
      }
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Firebase Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
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
        appBar: PageHeader(title: 'Account Centre', showBackButton: false),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: const PageHeader(title: 'Account Centre', showBackButton: false),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        appBar: PageHeader(title: 'Account Centre', showBackButton: false),
        body: Center(child: Text('No user profile data available.')),
      );
    }

    return Scaffold(
      appBar: const PageHeader(title: 'Account Centre', showBackButton: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        children: [
          ProfileCard(initialProfileData: _userProfile!, authUid: _userProfile!.id, onProfileUpdated: _fetchUserProfile), // Pass actual user profile
          const SizedBox(height: 16),
          ConnectionsCard(currentUserId: _userProfile!.id),
          const SizedBox(height: 16),
          const ChatBackupCard(),
          const SizedBox(height: 16),
          const PrivacySettingsCard(),
          const SizedBox(height: 16),
          const ThemeSettingsCard(),
          const SizedBox(height: 16),
          const LanguageSettingsCard(),
          const SizedBox(height: 16),
          const SecuritySettingsCard(),
          const SizedBox(height: 16),
          const LinkedAppsCard(),
          const SizedBox(height: 16),
          const AdvancedOptionsCard(),
        ],
      ),
    );
  }
}