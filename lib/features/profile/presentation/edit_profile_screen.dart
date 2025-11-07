import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../api/profiles/profiles_repository.dart';
import '../../../api/profiles/models/profile.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/ui/ui_utils.dart';
import '../../../app/theme/colors.dart';
import '../../../api/common/endpoints.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ProfilesRepository _profilesRepository = ProfilesRepository();
  final SessionManager _session = SessionManager();
  
  File? _photoFile;
  String? _currentPhotoUrl;
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _session.init();
    setState(() {
      _nameController.text = widget.profile.displayName;
      _currentPhotoUrl = widget.profile.photoUrl;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // If it's a relative path, prepend the base URL
    return '$apiBaseUrl$url';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 90,
      );
      if (picked == null) return;
      setState(() {
        _photoFile = File(picked.path);
        _currentPhotoUrl = null; // Clear current URL when new file is selected
      });
    } catch (e) {
      if (mounted) {
        UiUtils.showTopSnackBar(
          context: context,
          message: 'Failed to pick image: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_photoFile != null || _currentPhotoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove photo'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _photoFile = null;
                      _currentPhotoUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      UiUtils.showTopSnackBar(
        context: context,
        message: 'Please enter your name',
        isError: true,
      );
      return;
    }

    final userId = _session.userId;
    if (userId == null) {
      UiUtils.showTopSnackBar(
        context: context,
        message: 'User not logged in',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Update profile via API
      await _profilesRepository.updateProfile(
        userId: userId,
        displayName: name,
        photoFile: _photoFile, // Will be null if no new photo selected
      );

      // Update session with new display name
      await _session.saveUser(userId: userId, displayName: name);

      if (mounted) {
        UiUtils.showTopSnackBar(
          context: context,
          message: 'Profile updated successfully',
          isSuccess: true,
        );
        // Pop back to profile screen
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        UiUtils.showTopSnackBar(
          context: context,
          message: UiUtils.friendlyErrorMessage(e),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.outline,
                      backgroundImage: _photoFile != null
                          ? FileImage(_photoFile!)
                          : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                              ? NetworkImage(_getFullImageUrl(_currentPhotoUrl))
                              : null),
                      child: _photoFile == null &&
                              (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
                          ? const Icon(
                              Icons.person_rounded,
                              size: 56,
                              color: AppColors.textSecondary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showPickSheet,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.photo_camera,
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Display name',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _saveProfile(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

