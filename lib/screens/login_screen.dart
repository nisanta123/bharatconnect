import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/user_profile_model.dart';
import 'package:bharatconnect/screens/signup_screen.dart';
import 'package:bharatconnect/main.dart';
import 'package:bharatconnect/widgets/logo.dart'; // Import the new Logo widget

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
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
      // try {
      //   await FirebaseAuth.instance.signInWithEmailAndPassword(
      //     email: _email,
      //     password: _password,
      //   );
      // } on FirebaseAuthException catch (e) {
      //   String message;
      //   if (e.code == 'user-not-found' || e.code == 'wrong-password') {
      //     message = 'Incorrect email or password. If you\'re new, please Sign Up!';
      //   } else if (e.code == 'invalid-email') {
      //     message = 'Invalid email format.';
      //   } else if (e.code == 'network-request-failed') {
      //     message = 'Network error. Please check your connection.';
      //   } else if (e.code == 'too-many-requests') {
      //     message = 'Access to this account has been temporarily disabled due to many failed login attempts. You can immediately restore it by resetting your password or you can try again later.';
      //   } else {
      //     message = 'An unexpected error occurred during login.';
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
      // Placeholder for login logic
      await Future.delayed(const Duration(seconds: 1)); // Simulate network request
      if (_email == "test@example.com" && _password == "password") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WhatsAppHome()),
        );
      } else {
        setState(() {
          _errorMessage = 'Incorrect email or password. If you\'re new, please Sign Up!';
        });
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Google Sign-In will be available soon.")),
    );
  }

  void _forgotPassword() async {
    if (_email.isEmpty || !_email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email to reset password.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    // try {
    //   await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Password reset email sent to $_email')),
    //   );
    // } on FirebaseAuthException catch (e) {
    //   String message;
    //   if (e.code == 'user-not-found' || e.code == 'invalid-email') {
    //     message = 'No user found with this email. Please sign up if you are new.';
    //   } else {
    //     message = 'Failed to send password reset email.';
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
    await Future.delayed(const Duration(seconds: 1)); // Simulate network request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('If an account exists for $_email, a password reset link has been sent.')),
    );
    setState(() {
      _isLoading = false;
    });
  }

  void _handleSignUpClick() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SignupScreen()),
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
                        'Welcome to BharatConnect',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in or create an account to continue.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0), side: BorderSide(color: Theme.of(context).dividerColor)),
                          elevation: 0,
                        ),
                        child: const Text('Sign in with Google (Coming Soon)'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: <Widget>[
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
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
                        onChanged: (value) {
                          _email = value;
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
                          _password = value!;
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
                              : const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16.0)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading ? null : _forgotPassword,
                        child: Text('Forgot Password?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don\'t have an account? ",
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          GestureDetector(
                            onTap: _isLoading ? null : _handleSignUpClick,
                            child: Text(
                              'Sign Up',
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
