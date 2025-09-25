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

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Mock data for initial profile
  final User _mockUser = User(
    id: '1',
    name: 'John Doe',
    email: 'john.doe@example.com',
    username: 'johndoe',
    avatarUrl: null, // Set to null for default avatar
    bio: 'A passionate Flutter developer.',
    onboardingComplete: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader(title: 'Account Centre', showBackButton: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        children: [
          ProfileCard(initialProfileData: _mockUser, authUid: _mockUser.id),
          const SizedBox(height: 16),
          const ConnectionsCard(),
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