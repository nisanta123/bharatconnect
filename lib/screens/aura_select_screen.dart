import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/aura_models.dart';
import 'package:bharatconnect/widgets/logo.dart';
import 'package:bharatconnect/widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'dart:async'; // Import for StreamSubscription

class AuraSelectScreen extends StatefulWidget {
  const AuraSelectScreen({super.key});

  @override
  State<AuraSelectScreen> createState() => _AuraSelectScreenState();
}

class _AuraSelectScreenState extends State<AuraSelectScreen> {
  UserProfile? _currentUserProfile; // To store the fetched user profile
  DisplayAura? _activeUserAura; // The currently active aura of the user
  bool _isLoading = true;
  bool _isSavingAura = false;
  String? _errorMessage;
  StreamSubscription? _auraSubscription; // Declare StreamSubscription

  @override
  void initState() {
    super.initState();
    _fetchUserProfileAndListenForAura();
  }

  @override
  void dispose() {
    _auraSubscription?.cancel(); // Cancel the subscription in dispose
    super.dispose();
  }

  Future<void> _fetchUserProfileAndListenForAura() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not logged in.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Fetch user profile first
      final userDoc = await FirebaseFirestore.instance.collection('bharatConnectUsers').doc(user.uid).get();
      if (userDoc.exists) {
        _currentUserProfile = UserProfile.fromFirestore(userDoc);
      }

      // Then listen for aura changes
      _auraSubscription = FirebaseFirestore.instance // Assign to _auraSubscription
          .collection('auras')
          .doc(user.uid)
          .snapshots()
          .listen(
            (docSnapshot) {
              if (!mounted) return; // Check if mounted before calling setState

              if (docSnapshot.exists) {
                final firestoreAura = FirestoreAura.fromFirestore(docSnapshot);
                final now = DateTime.now();
                final createdAt = firestoreAura.createdAt.toDate();
                final expiresAt = createdAt.add(const Duration(hours: 1));

                if (now.isBefore(expiresAt)) {
                  // Aura is still active
                  final matchingAuraOption = AURA_OPTIONS.firstWhereOrNull(
                    (option) => option.id == firestoreAura.auraOptionId,
                  );
                  setState(() {
                    _activeUserAura = DisplayAura(
                      id: docSnapshot.id,
                      userId: firestoreAura.userId,
                      userName: _currentUserProfile?.displayName ?? _currentUserProfile?.username ?? 'You',
                      userProfileAvatarUrl: _currentUserProfile?.avatarUrl,
                      auraOptionId: firestoreAura.auraOptionId,
                      createdAt: createdAt,
                      auraStyle: matchingAuraOption,
                    );
                    _isLoading = false;
                  });
                } else {
                  // Aura has expired, delete it from Firestore
                  _clearAuraFromFirestore(user.uid);
                  setState(() {
                    _activeUserAura = null;
                    _isLoading = false;
                  });
                }
              } else {
                // No active aura
                setState(() {
                  _activeUserAura = null;
                  _isLoading = false;
                });
              }
            },
            onError: (error) { // Corrected onError handling
              if (!mounted) return; // Check if mounted before calling setState
              setState(() {
                _errorMessage = 'Error listening for aura: $error';
                _isLoading = false;
              });
              showCustomToast(context, 'Error: $_errorMessage', isError: true);
            },
          );
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Firebase Error: ${e.message}';
          _isLoading = false;
        });
      }
      showCustomToast(context, 'Error: $_errorMessage', isError: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
      showCustomToast(context, 'Error: $_errorMessage', isError: true);
    }
  }

  Future<void> _clearAuraFromFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('auras').doc(userId).delete();
      print('Aura document deleted for $userId');
    } catch (e) {
      print('Error deleting expired aura: $e');
    }
  }

  Future<void> _handleSetAura(UserAura selectedAura) async {
    setState(() {
      _isSavingAura = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'User not logged in.';
      showCustomToast(context, _errorMessage!, isError: true);
      setState(() => _isSavingAura = false);
      return;
    }

    try {
      final firestoreAura = FirestoreAura(
        userId: user.uid,
        auraOptionId: selectedAura.id,
        createdAt: Timestamp.now(),
      );
      await FirebaseFirestore.instance
          .collection('auras')
          .doc(user.uid)
          .set(firestoreAura.toFirestore());

      showCustomToast(context, 'Aura set to ${selectedAura.name}!');
      Navigator.of(context).pop(); // Go back to previous screen
    } on FirebaseException catch (e) {
      _errorMessage = 'Failed to set aura: ${e.message}';
      showCustomToast(context, _errorMessage!, isError: true);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      showCustomToast(context, _errorMessage!, isError: true);
    } finally {
      setState(() {
        _isSavingAura = false;
      });
    }
  }

  Future<void> _handleClearAura() async {
    setState(() {
      _isSavingAura = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'User not logged in.';
      showCustomToast(context, _errorMessage!, isError: true);
      setState(() => _isSavingAura = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('auras').doc(user.uid).delete();
      showCustomToast(context, 'Aura cleared!');
    } on FirebaseException catch (e) {
      _errorMessage = 'Failed to clear aura: ${e.message}';
      showCustomToast(context, _errorMessage!, isError: true);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      showCustomToast(context, _errorMessage!, isError: true);
    } finally {
      setState(() {
        _isSavingAura = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Logo(size: "medium")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                "Loading Auras...",
                style: GoogleFonts.playfairDisplay(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Logo(size: "medium")),
        body: Center(
          child: Text(
            _errorMessage!,
            style: GoogleFonts.playfairDisplay(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Logo(size: "medium"),
        actions: [
          if (_activeUserAura != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _handleClearAura,
              tooltip: 'Clear Aura',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Your Aura',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a temporary mood or status for your contacts to see.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            if (_activeUserAura != null) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 24.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey,
                        backgroundImage: _activeUserAura!.userProfileAvatarUrl != null &&
                                _activeUserAura!.userProfileAvatarUrl!.isNotEmpty
                            ? NetworkImage(_activeUserAura!.userProfileAvatarUrl!)
                            : null,
                        child: _activeUserAura!.userProfileAvatarUrl == null ||
                                _activeUserAura!.userProfileAvatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activeUserAura!.auraStyle?.name ?? 'Active Aura',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _activeUserAura!.auraStyle?.primaryColor ?? Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Active until ${DateTime.fromMillisecondsSinceEpoch(_activeUserAura!.createdAt.millisecondsSinceEpoch + (60 * 60 * 1000)).toLocal().hour.toString().padLeft(2, '0')}:${DateTime.fromMillisecondsSinceEpoch(_activeUserAura!.createdAt.millisecondsSinceEpoch + (60 * 60 * 1000)).toLocal().minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSavingAura ? null : _handleClearAura,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: _isSavingAura
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Clear Aura', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Text(
              _activeUserAura != null ? 'Change Your Aura Vibe' : 'Choose Your Aura Vibe',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: AURA_OPTIONS.length,
              itemBuilder: (context, index) {
                final auraOption = AURA_OPTIONS[index];
                final isSelected = _activeUserAura?.id == auraOption.id;
                return GestureDetector(
                  onTap: _isSavingAura ? null : () => _handleSetAura(auraOption),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          auraOption.primaryColor.withOpacity(isSelected ? 0.8 : 0.4),
                          auraOption.secondaryColor.withOpacity(isSelected ? 0.8 : 0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? auraOption.primaryColor : Colors.transparent,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: auraOption.primaryColor.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(auraOption.iconUrl, width: 40, height: 40), // Display icon
                        const SizedBox(height: 8),
                        Text(
                          auraOption.name,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
