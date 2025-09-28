import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bharatconnect/screens/home_screen.dart';
import 'package:bharatconnect/widgets/logo.dart'; // Assuming you have a Logo widget
import 'package:bharatconnect/models/user_profile_model.dart'; // Assuming UserProfile model
import 'package:bharatconnect/screens/login_screen.dart'; // For logout navigation
import 'package:bharatconnect/widgets/custom_toast.dart'; // Import CustomToast
import 'package:bharatconnect/widgets/default_avatar.dart'; // Import DefaultAvatar

class ProfileSetupScreen extends StatefulWidget {
  final User user;
  const ProfileSetupScreen({super.key, required this.user});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _bioController = TextEditingController();

  File? _profilePicFile;
  String? _profilePicPreviewUrl; // For displaying network image or new picked image

  String? _errorMessage;
  String? _usernameError;
  bool _isLoading = false;
  bool _isPageLoading = true;

  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    print('ProfileSetupScreen: initState called.');
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    print('ProfileSetupScreen: _fetchUserProfile started.');
    setState(() {
      _isPageLoading = true;
      _errorMessage = null;
    });

    final user = widget.user;

    try {
      print('ProfileSetupScreen: Attempting to fetch user profile for UID: ${user.uid}');
      final doc = await FirebaseFirestore.instance.collection("bharatConnectUsers").doc(user.uid).get();

      if (doc.exists) {
        print('ProfileSetupScreen: User profile found for UID: ${user.uid}');
        _currentUserProfile = UserProfile.fromFirestore(doc);
        _displayNameController.text = _currentUserProfile?.displayName ?? '';
        _usernameController.text = _currentUserProfile?.username ?? '';
        _phoneNumberController.text = _currentUserProfile?.phone ?? '';
        _bioController.text = _currentUserProfile?.bio ?? '';
        _profilePicPreviewUrl = _currentUserProfile?.avatarUrl; // Set network image as preview
      } else {
        print('ProfileSetupScreen: User profile NOT found in Firestore for UID: ${user.uid}. Initializing with email.');
        // If no profile exists, initialize with email from Firebase Auth
        _currentUserProfile = UserProfile(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email?.split('@')[0] ?? '', // Add displayName
          username: user.email?.split('@')[0], // username is nullable
          onboardingComplete: false,
          // status will be null initially
        );
        _displayNameController.text = _currentUserProfile!.displayName;
        _usernameController.text = _currentUserProfile!.username ?? '';
      }
    } on FirebaseException catch (e) {
      print('ProfileSetupScreen: FirebaseException in _fetchUserProfile: ${e.code} - ${e.message}');
      _errorMessage = 'Firebase Error: ${e.message}';
      showCustomToast(context, _errorMessage!, isError: true);
    } catch (e) {
      print('ProfileSetupScreen: Unexpected error in _fetchUserProfile: $e');
      _errorMessage = 'An unexpected error occurred: $e';
      showCustomToast(context, _errorMessage!, isError: true);
    } finally {
      setState(() {
        _isPageLoading = false;
      });
      print('ProfileSetupScreen: _fetchUserProfile finished. _isPageLoading: $_isPageLoading');
    }
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedImageFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedImageFile != null) {
      setState(() {
        _profilePicFile = File(pickedImageFile.path);
        _profilePicPreviewUrl = pickedImageFile.path; // Use local path for preview
      });
      showCustomToast(context, "Profile picture selected. Save to upload.");
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profilePicFile = null;
      _profilePicPreviewUrl = null;
    });
    showCustomToast(context, "Profile picture removed.");
  }

  bool _validateUsername(String val) {
    _usernameError = null;
    final usernameRegex = RegExp(r"^[a-z0-9_]{3,20}$");
    if (!val.trim().isNotEmpty) {
      _usernameError = 'Username is required.';
      return false;
    }
    if (!usernameRegex.hasMatch(val)) {
      _usernameError = 'Username must be 3-20 characters, lowercase letters, numbers, or underscores only.';
      return false;
    }
    return true;
  }

  Future<void> _saveProfile() async {
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus();

    if (isValid == null || !isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _usernameError = null;
    });

    final user = widget.user;
    final authUid = user.uid;
    final authEmail = user.email;

    if (authUid == null || authEmail == null) {
      _errorMessage = 'User authentication information is missing. Please try logging in again.';
      showCustomToast(context, "User Info Error: UID or Email missing. Please login.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final trimmedDisplayName = _displayNameController.text.trim();
    final trimmedUsername = _usernameController.text.trim();
    final trimmedPhoneNumber = _phoneNumberController.text.trim();
    final trimmedBio = _bioController.text.trim();

    if (!trimmedUsername.isNotEmpty) {
      _usernameError = 'Username is required.';
      setState(() => _isLoading = false);
      return;
    }
    if (!_validateUsername(trimmedUsername)) {
      setState(() => _isLoading = false);
      return;
    }

    final finalDisplayName = trimmedDisplayName.isNotEmpty ? trimmedDisplayName : trimmedUsername;

    if (!finalDisplayName.isNotEmpty) {
      _errorMessage = 'Please enter your display name.';
      setState(() => _isLoading = false);
      return;
    }

    if (trimmedPhoneNumber.isNotEmpty && !RegExp(r"^\+?\d{10,15}$").hasMatch(trimmedPhoneNumber.replaceAll(RegExp(r"\s+"), ''))) {
      _errorMessage = 'Please enter a valid phone number (e.g., 10 digits or international format like +919876543210).';
      setState(() => _isLoading = false);
      return;
    }

    String? finalPhotoURL = _currentUserProfile?.avatarUrl; // Keep existing if no new image

    if (_profilePicFile != null) {
      try {
        final ref = FirebaseStorage.instance.ref().child("profile_pics/$authUid.jpg");
        await ref.putFile(_profilePicFile!);
        finalPhotoURL = await ref.getDownloadURL();
        showCustomToast(context, "Profile picture uploaded!");
      } catch (uploadError) {
        _errorMessage = 'Failed to upload profile picture. Please try again.';
        showCustomToast(context, 'Upload Error: Could not upload image.', isError: true);
        setState(() => _isLoading = false);
        return;
      }
    } else if (_profilePicPreviewUrl == null && _currentUserProfile?.avatarUrl != null) {
      // If user removed existing image
      try {
        final ref = FirebaseStorage.instance.refFromURL(_currentUserProfile!.avatarUrl!);
        await ref.delete();
        showCustomToast(context, "Profile picture removed from storage.");
      } catch (deleteError) {
        showCustomToast(context, 'Deletion Warning: Could not delete old picture.', isError: true);
      }
      finalPhotoURL = null;
    }

    final profileDataToSave = {
      "email": authEmail,
      "username": trimmedUsername,
      "displayName": finalDisplayName,
      "avatarUrl": finalPhotoURL,
      "phone": trimmedPhoneNumber.isNotEmpty ? trimmedPhoneNumber : null,
      "bio": trimmedBio.isNotEmpty ? trimmedBio : null,
      "onboardingComplete": true,
      "createdAt": FieldValue.serverTimestamp(),
      "status": null, // Add status field, initially null
    };

    try {
      await FirebaseFirestore.instance.collection("bharatConnectUsers").doc(authUid).set(profileDataToSave, SetOptions(merge: true));

      // Update local user profile in AuthContext equivalent (placeholder)
      // setAuthUser(updatedProfileForContext);

      showCustomToast(context, 'Welcome, $finalDisplayName! Your BharatConnect account is ready.');

      // Navigate to home screen and remove all previous routes from the stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false, // This predicate removes all previous routes
      );
    } on FirebaseException catch (error) {
      _errorMessage = 'Failed to save your profile or generate keys. Please try again.';
      showCustomToast(context, 'Setup Error: ${error.message}', isError: true);
    } catch (error) {
      _errorMessage = 'An unexpected error occurred during profile setup.';
      showCustomToast(context, 'Setup Error: An unexpected error occurred.', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLogoutAndStartOver() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      showCustomToast(context, "Logout failed: $e", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ProfileSetupScreen: build method called.');

    if (_isPageLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                "Loading profile setup...",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            margin: const EdgeInsets.all(20),
            elevation: 8.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: Logo(size: "large"), // BharatConnect Logo
                    ),
                    Text(
                      'Create Your Profile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                      child: Text(
                        'Let\'s get your BharatConnect profile ready.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          DefaultAvatar(
                            radius: 48,
                            avatarUrl: _profilePicPreviewUrl,
                            // The name parameter is optional, but can be passed if available
                            // name: _displayNameController.text.isNotEmpty ? _displayNameController.text : null,
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.3), // Dark overlay
                              ),
                              child: Icon(Icons.camera_alt, size: 24, color: Colors.white.withOpacity(0.8)), // Camera icon
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tap to upload a profile picture (Optional)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                          if (_profilePicPreviewUrl != null)
                            TextButton.icon(
                              onPressed: _removeProfileImage,
                              icon: Icon(Icons.delete_outline, size: 16, color: Theme.of(context).colorScheme.error), // Trash2 equivalent
                              label: Text(
                                'Remove',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Email', style: Theme.of(context).textTheme.labelLarge),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor, // Muted background
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.mail_outline, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)), // Mail icon
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.user.email ?? 'Loading email...',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Display Name', style: Theme.of(context).textTheme.labelLarge),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        hintText: 'Your Name (e.g., same as username if blank)',
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Username', style: Theme.of(context).textTheme.labelLarge),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'your_unique_username',
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                        ),
                        prefixIcon: Icon(Icons.alternate_email, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)), // AtSign equivalent
                        errorText: _usernameError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _usernameController.text = value.toLowerCase();
                          _usernameController.selection = TextSelection.fromPosition(TextPosition(offset: _usernameController.text.length));
                          _validateUsername(value.toLowerCase());
                        });
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required.';
                        }
                        if (!RegExp(r"^[a-z0-9_]{3,20}$").hasMatch(value)) {
                          return 'Username must be 3-20 characters, lowercase letters, numbers, or underscores only.';
                        }
                        return null;
                      },
                    ),
                    if (_usernameError == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Unique, lowercase, no spaces, 3-20 characters (letters, numbers, underscores).',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Phone Number (Optional)', style: Theme.of(context).textTheme.labelLarge),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).inputDecorationTheme.fillColor,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                          ),
                          child: Text('+91', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'e.g. 98765*****',
                              filled: true,
                              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                              ),
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty && !RegExp(r"^\+?\d{10,15}$").hasMatch(value.replaceAll(RegExp(r"\s+"), ''))) {
                                return 'Please enter a valid phone number.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Helps friends find you and secures your account.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Bio (Optional)', style: Theme.of(context).textTheme.labelLarge),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tell us a bit about yourself...',
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                        ),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF42A5F5),
                            Color(0xFFAB47BC),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20.0,
                                width: 20.0,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                              )
                            : Text('Complete Setup & Continue', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading ? null : _handleLogoutAndStartOver,
                      child: Text(
                        'Logout and start over',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
