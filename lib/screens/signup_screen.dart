import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/user_profile_model.dart';
import 'package:bharatconnect/main.dart'; // Import WhatsAppHome
import 'package:bharatconnect/screens/login_screen.dart'; // Import LoginScreen
import 'package:bharatconnect/widgets/logo.dart'; // Import the new Logo widget

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

  void _trySubmit() async {
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus();

    if (isValid != null && isValid) {
      _formKey.currentState?.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (_password != _confirmPassword) {
        setState(() {
          _errorMessage = 'Passwords do not match.';
          _isLoading = false;
        });
        return;
      }
      if (_password.length < 6) {
        setState(() {
          _errorMessage = 'Password should be at least 6 characters.';
          _isLoading = false;
        });
        return;
      }

      // try {
      //   UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      //     email: _email,
      //     password: _password,
      //   );
      //   // Create initial user profile in Firestore
      //   if (userCredential.user != null) {
      //     await FirebaseFirestore.instance
      //         .collection('bharatConnectUsers')
      //         .doc(userCredential.user!.uid)
      //         .set(UserProfile(
      //           id: userCredential.user!.uid,
      //           email: _email,
      //           onboardingComplete: false,
      //         ).toFirestore());
      //     // After successful signup and initial profile creation, pop to login or directly to profile setup
      //     Navigator.of(context).pop(); // Go back to login screen
      //   }
      // } on FirebaseAuthException catch (e) {
      //   String message;
      //   if (e.code == 'email-already-in-use') {
      //     message = 'This email is already registered. Please login or use a different email.';
      //   } else if (e.code == 'weak-password') {
      //     message = 'Password is too weak. Please choose a stronger password.';
      //   } else if (e.code == 'invalid-email') {
      //     message = 'Invalid email format. Please check your email address.';
      //   } else if (e.code == 'network-request-failed') {
      //     message = 'Network error. Please check your connection and try again.';
      //   } else {
      //     message = 'An unexpected error occurred during signup. Please try again.';
      //   }
      //   setState(() {
      //     _errorMessage = message;
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
      // Placeholder for signup logic
      await Future.delayed(const Duration(seconds: 1)); // Simulate network request
      if (_email == "new@example.com" && _password == "password") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WhatsAppHome()),
        );
      } else {
        setState(() {
          _errorMessage = 'An unexpected error occurred during signup. Please try again.';
        });
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLoginLinkClick() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          _email = value!;
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
                        ),
                        obscureText: true,
                        onSaved: (value) {
                          _password = value!;
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
                          if (value != _password) {
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
                        ),
                        obscureText: true,
                        onSaved: (value) {
                          _confirmPassword = value!;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                      )
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
