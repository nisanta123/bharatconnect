import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bharatconnect/widgets/default_avatar.dart';
import 'package:bharatconnect/widgets/custom_toast.dart';
import 'package:bharatconnect/models/user_profile_model.dart';
import 'package:bharatconnect/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile initialProfile;

  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  final UserService _userService = UserService();
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  double _uploadProgress = 0.0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(text: widget.initialProfile.displayName);
    _usernameCtrl = TextEditingController(text: widget.initialProfile.username);
    _bioCtrl = TextEditingController(text: widget.initialProfile.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _pickedImage?.delete();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final result = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 60);
      if (result != null) {
        setState(() => _pickedImage = File(result.path));
      }
    } catch (e) {
      // ignore image pick errors for now
      print('Image pick error: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final updates = {
      'displayName': _displayNameCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
    };

    // If user picked a new image, upload it first and include avatarUrl in updates
    if (_pickedImage != null) {
      if (mounted) setState(() => _uploadProgress = 0.0);
      final url = await _userService.uploadUserAvatar(widget.initialProfile.id, _pickedImage!, onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      });
      if (url != null) {
        updates['avatarUrl'] = url;
      } else {
        if (mounted) showCustomToast(context, 'Failed to upload avatar', isError: true);
      }
      if (mounted) setState(() => _uploadProgress = 0.0);
    }

    final ok = await _userService.updateUserProfile(widget.initialProfile.id, updates);
    if (mounted) setState(() => _saving = false);
    if (ok) {
      if (mounted) Navigator.of(context).pop(true);
    } else {
      if (mounted) showCustomToast(context, 'Failed to update profile', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar preview and pick buttons
              Center(
                child: Column(
                  children: [
                    // If a new image was picked, preview it from file. Otherwise use DefaultAvatar
                    _pickedImage != null
                        ? CircleAvatar(
                            radius: 44,
                            backgroundImage: FileImage(_pickedImage!) as ImageProvider,
                          )
                        : DefaultAvatar(
                            avatarUrl: widget.initialProfile.avatarUrl,
                            radius: 44,
                          ),
                    const SizedBox(height: 8),
                    if (_uploadProgress > 0.0 && _uploadProgress < 1.0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(width: 120, child: LinearProgressIndicator(value: _uploadProgress)),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              TextFormField(
                controller: _displayNameCtrl,
                decoration: const InputDecoration(labelText: 'Display name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter display name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter username' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioCtrl,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator() : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
