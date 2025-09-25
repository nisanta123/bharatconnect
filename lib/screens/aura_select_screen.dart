import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/models/aura_models.dart';
import 'package:bharatconnect/models/user_profile_model.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

class AuraSelectScreen extends StatefulWidget {
  const AuraSelectScreen({super.key});

  @override
  State<AuraSelectScreen> createState() => _AuraSelectScreenState();
}

class _AuraSelectScreenState extends State<AuraSelectScreen> {
  UserProfile? _currentUserProfile;
  DisplayAura? _currentUserActiveAura;
  bool _isLoadingAuraStatus = true;
  bool _isSavingAura = false;
  String? _pageError;

  @override
  void initState() {
    super.initState();
    _fetchUserProfileAndAura();
  }

  Future<void> _fetchUserProfileAndAura() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _pageError = 'User not authenticated.';
        _isLoadingAuraStatus = false;
      });
      return;
    }

    try {
      // Fetch user profile
      final userDoc = await FirebaseFirestore.instance.collection('bharatConnectUsers').doc(user.uid).get();
      if (userDoc.exists) {
        _currentUserProfile = UserProfile.fromFirestore(userDoc);
      }

      // Listen for aura changes
      FirebaseFirestore.instance.collection('auras').doc(user.uid).snapshots().listen((auraDocSnap) {
        if (auraDocSnap.exists) {
          final data = auraDocSnap.data() as Map<String, dynamic>;
          final firestoreAura = FirestoreAura.fromFirestore(auraDocSnap);

          final createdAtDate = firestoreAura.createdAt.toDate();
          const auraDurationMs = 60 * 60 * 1000; // 1 hour

          if (DateTime.now().millisecondsSinceEpoch - createdAtDate.millisecondsSinceEpoch < auraDurationMs) {
            final auraStyle = AURA_OPTIONS.firstWhereOrNull((opt) => opt.id == firestoreAura.auraOptionId);
            setState(() {
              _currentUserActiveAura = DisplayAura(
                id: auraDocSnap.id,
                userId: firestoreAura.userId,
                userName: _currentUserProfile?.displayName ?? _currentUserProfile?.username ?? 'You',
                userProfileAvatarUrl: _currentUserProfile?.avatarUrl,
                auraOptionId: firestoreAura.auraOptionId,
                createdAt: createdAtDate,
                auraStyle: auraStyle,
              );
            });
          } else {
            // Aura expired
            setState(() {
              _currentUserActiveAura = null;
            });
          }
        } else {
          // No active aura document
          setState(() {
            _currentUserActiveAura = null;
          });
        }
        setState(() {
          _isLoadingAuraStatus = false;
        });
      });
    } catch (e) {
      setState(() {
        _pageError = 'Failed to load aura status: ${e.toString()}';
        _isLoadingAuraStatus = false;
      });
      print(e);
    }
  }

  Future<void> _handleSetAura(UserAura selectedAuraOption) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSavingAura = true;
      _pageError = null;
    });

    try {
      final auraData = FirestoreAura(
        userId: user.uid,
        auraOptionId: selectedAuraOption.id,
        createdAt: Timestamp.now(),
      );
      await FirebaseFirestore.instance.collection('auras').doc(user.uid).set(auraData.toFirestore());
      Navigator.of(context).pop(); // Go back to previous screen (WhatsAppHome)
    } on FirebaseException catch (e) {
      setState(() {
        _pageError = 'Failed to set aura: ${e.message}';
      });
      print(e);
    } catch (e) {
      setState(() {
        _pageError = 'An unexpected error occurred: ${e.toString()}';
      });
      print(e);
    } finally {
      setState(() {
        _isSavingAura = false;
      });
    }
  }

  Future<void> _handleClearAura() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUserActiveAura == null) return;

    setState(() {
      _isSavingAura = true;
      _pageError = null;
    });

    try {
      await FirebaseFirestore.instance.collection('auras').doc(user.uid).delete();
    } on FirebaseException catch (e) {
      setState(() {
        _pageError = 'Failed to clear aura: ${e.message}';
      });
      print(e);
    } catch (e) {
      setState(() {
        _pageError = 'An unexpected error occurred: ${e.toString()}';
      });
      print(e);
    } finally {
      setState(() {
        _isSavingAura = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuraStatus) {
      return const Scaffold(
        appBar: AppBar(title: Text('Aura Setup')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pageError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aura Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  _pageError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Go back
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUserActiveAura != null ? 'Your Active Aura' : 'Set Your Aura'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_currentUserActiveAura != null) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 24.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey,
                        backgroundImage: _currentUserActiveAura!.userProfileAvatarUrl != null &&
                                _currentUserActiveAura!.userProfileAvatarUrl!.isNotEmpty
                            ? NetworkImage(_currentUserActiveAura!.userProfileAvatarUrl!)
                            : null,
                        child: _currentUserActiveAura!.userProfileAvatarUrl == null ||
                                _currentUserActiveAura!.userProfileAvatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentUserActiveAura!.auraStyle?.name ?? 'Active Aura',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Active until ${DateTime.fromMillisecondsSinceEpoch(_currentUserActiveAura!.createdAt.millisecondsSinceEpoch + (60 * 60 * 1000)).toLocaleTimeString()}',
                        style: Theme.of(context).textTheme.bodySmall,
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
              _currentUserActiveAura != null ? 'Change Your Aura Vibe' : 'Choose Your Aura Vibe',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Adjust as needed
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0, // Make items square
              ),
              itemCount: AURA_OPTIONS.length,
              itemBuilder: (context, index) {
                final option = AURA_OPTIONS[index];
                final isActive = _currentUserActiveAura?.auraOptionId == option.id;
                return GestureDetector(
                  onTap: _isSavingAura ? null : () => _handleSetAura(option),
                  child: Card(
                    color: isActive ? option.primaryColor : Theme.of(context).cardColor,
                    elevation: isActive ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isActive ? BorderSide(color: option.secondaryColor, width: 2) : BorderSide.none,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(option.iconUrl, width: 40, height: 40),
                        const SizedBox(height: 8),
                        Text(
                          option.name,
                          style: TextStyle(
                            color: isActive ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isSavingAura && _currentUserActiveAura?.auraOptionId == option.id)
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
