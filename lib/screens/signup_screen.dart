import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/user_profile_model.dart';
import 'package:bharatconnect/main.dart'; // Import WhatsAppHome
import 'package:bharatconnect/screens/login_screen.dart'; // Import LoginScreen
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:bharatconnect/widgets/logo.dart'; // Import the new Logo widget
import 'package:bharatconnect/widgets/default_avatar.dart';
import 'package:bharatconnect/screens/profile_setup_screen.dart' as ps_screen; // Add this import with prefix
import 'package:bharatconnect/widgets/custom_toast.dart'; // Import CustomToast

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String? _errorMessage;
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Added for password visibility toggle
  bool _isConfirmPasswordVisible = false; // Added for confirm password visibility toggle
  File? _pickedProfileImage;
  String? _pickedProfileImagePath;

  @override
  void initState() {
    super.initState();
    print('SignupScreen: initState called.');
  }

  void _showCustomMessage(String message, {bool isError = false}) {
    showCustomToast(context, message, isError: isError);
  }

  void _trySubmit() async {
    print('SignupScreen: _trySubmit started.');
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus();

    if (isValid != null && isValid) {
      _formKey.currentState?.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      print('SignupScreen: Form is valid, _isLoading set to true.');

      if (_password.trim() != _confirmPassword.trim()) {
        setState(() {
          _errorMessage = 'Passwords do not match.';
          _isLoading = false;
        });
        print('SignupScreen: Passwords do not match.');
        _showCustomMessage('Passwords do not match.', isError: true);
        return;
      }
      if (_password.length < 6) {
        setState(() {
          _errorMessage = 'Password should be at least 6 characters.';
          _isLoading = false;
        });
        print('SignupScreen: Password too short.');
        _showCustomMessage('Password should be at least 6 characters.', isError: true);
        return;
      }

      try {
        print('SignupScreen: Attempting to create user with email and password.');
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        print('SignupScreen: User created successfully: ${userCredential.user?.uid}');
        // Create initial user profile in Firestore
        if (userCredential.user != null) {
          print('SignupScreen: User created successfully: ${userCredential.user?.uid}');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ps_screen.ProfileSetupScreen(
                user: userCredential.user!,
                initialPhotoPath: _pickedProfileImagePath,
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'email-already-in-use') {
          message = 'This email is already registered. Please login or use a different email.';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak. Please choose a stronger password.';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email format. Please check your email address.';
        } else if (e.code == 'network-request-failed') {
          message = 'Network error. Please check your connection and try again.';
        } else {
          message = 'An unexpected error occurred during signup. Please try again.';
        }
        setState(() {
          _errorMessage = message;
        });
        _showCustomMessage(message, isError: true);
        print('SignupScreen: FirebaseAuthException: ${e.code} - ${e.message}');
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred.';
        });
        _showCustomMessage('An unexpected error occurred.', isError: true);
        print('SignupScreen: Unexpected error: $e');
      } finally {
        print('SignupScreen: _trySubmit finished. Setting _isLoading to false.');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1024, maxHeight: 1024);
    if (picked != null) {
      setState(() {
        _pickedProfileImage = File(picked.path);
        _pickedProfileImagePath = picked.path;
      });
      showCustomToast(context, 'Profile picture selected. You can change it later.');
    }
  }

  void _handleLoginLinkClick() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('SignupScreen: build method called.');
    return Scaffold(
      body: Center(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
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
                        child: Logo(size: "large"),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            DefaultAvatar(radius: 40, avatarUrl: _pickedProfileImagePath),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.25)),
                                child: Icon(Icons.camera_alt, size: 20, color: Colors.white.withOpacity(0.85)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_pickedProfileImagePath != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _pickedProfileImage = null;
                              _pickedProfileImagePath = null;
                            });
                          },
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Remove'),
                        ),
                      const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join BharatConnect to connect with India!',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Email', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('email'),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
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
                        onSaved: (value) {
                          _email = value!.trim(); // Trim email on save
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Password', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('password'),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: '•••••••• (min. 6 characters)',
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
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        onSaved: (value) {
                          _password = value!.trim(); // Trim password on save
                        },
                        onChanged: (value) {
                          _password = value.trim(); // Update _password immediately and trimmed
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Confirm Password', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('confirm_password'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (value.trim() != _password.trim()) { // Ensure comparison is trimmed
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: '••••••••',
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
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isConfirmPasswordVisible,
                        onSaved: (value) {
                          _confirmPassword = value!.trim(); // Trim confirm password on save
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 12),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 12),
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
                          onPressed: _isLoading ? null : _trySubmit,
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
                              : const Text('Sign Up & Continue', style: TextStyle(color: Colors.white, fontSize: 16.0)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            ),
                            GestureDetector(
                              onTap: _isLoading ? null : _handleLoginLinkClick,
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
