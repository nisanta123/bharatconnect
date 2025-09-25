import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/user_profile_model.dart';
// import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For File operations
// import 'package:firebase_storage/firebase_storage.dart'; // For uploading images
import 'package:bharatconnect/main.dart'; // Import WhatsAppHome

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _displayName = '';
  File? _pickedImage;
  String? _errorMessage;
  bool _isLoading = false;

  // Fetch current user profile data
  // UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    // _fetchUserProfile();
  }

  // Future<void> _fetchUserProfile() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     final doc = await FirebaseFirestore.instance.collection('bharatConnectUsers').doc(user.uid).get();
  //     if (doc.exists) {
  //       setState(() {
  //         _currentUserProfile = UserProfile.fromFirestore(doc);
  //         _username = _currentUserProfile?.username ?? '';
  //         _displayName = _currentUserProfile?.displayName ?? '';
  //       });
  //     }
  //   }
  // }

  void _pickImage() async {
    // final picker = ImagePicker();
    // final pickedImageFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    // if (pickedImageFile != null) {
    //   setState(() {
    //     _pickedImage = File(pickedImageFile.path);
    //   });
    // }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picking is disabled.')),
    );
  }

  // Future<String?> _uploadImage() async {
  //   if (_pickedImage == null) return null;

  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return null;

  //   final ref = FirebaseStorage.instance
  //       .ref()
  //       .child('user_images')
  //       .child('${user.uid}.jpg');

  //   await ref.putFile(_pickedImage!);
  //   final url = await ref.getDownloadURL();
  //   return url;
  // }

  void _trySubmit() async {
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus();

    if (isValid != null && isValid) {
      _formKey.currentState?.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // final user = FirebaseAuth.instance.currentUser;
      // if (user == null) {
      //   setState(() {
      //     _errorMessage = 'User not logged in.';
      //     _isLoading = false;
      //   });
      //   return;
      // }

      // try {
      //   String? imageUrl = _currentUserProfile?.avatarUrl; // Keep existing if no new image
      //   if (_pickedImage != null) {
      //     imageUrl = await _uploadImage();
      //   }

      //   await FirebaseFirestore.instance.collection('bharatConnectUsers').doc(user.uid).update({
      //     'username': _username.trim(),
      //     'displayName': _displayName.trim().isEmpty ? _username.trim() : _displayName.trim(),
      //     'avatarUrl': imageUrl,
      //     'onboardingComplete': true,
      //   });

      //   // Optionally update the local UserProfile object in state or context
      //   // For now, we'll rely on the main.dart StreamBuilder to re-evaluate

      // } on FirebaseException catch (e) {
      //   setState(() {
      //     _errorMessage = e.message;
      //   });
      //   print(e);
      // } catch (e) {
      //   setState(() {
      //     _errorMessage = 'An unexpected error occurred.';
      //   });
      //   print(e);
      // } finally {
      //   setState(() {
      //     _isLoading = false;
      //   });
      // }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WhatsAppHome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (// _currentUserProfile?.avatarUrl != null
                                // ? NetworkImage(_currentUserProfile!.avatarUrl!)
                                // : 
                                null) as ImageProvider<Object>?,
                        child: _pickedImage == null // && _currentUserProfile?.avatarUrl == null
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Tap to add profile picture (Optional)'),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const ValueKey('username'),
                      initialValue: _username,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username.';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters.';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(labelText: 'Username'),
                      onSaved: (value) {
                        _username = value!;
                      },
                    ),
                    TextFormField(
                      key: const ValueKey('displayName'),
                      initialValue: _displayName,
                      decoration: const InputDecoration(labelText: 'Display Name (Optional)'),
                      onSaved: (value) {
                        _displayName = value!;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _trySubmit,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Complete Setup & Continue'),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              // await FirebaseAuth.instance.signOut();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Logout functionality is disabled.')),
                              );
                            },
                      child: const Text('Logout and start over'),
                    )
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
