import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/users_info/personal_info_widget.dart';
import '../widgets/users_info/bio_interests_widget.dart';
import '../widgets/users_info/media_gallery_widget.dart';
import '../constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;
  late TextEditingController _interestController;
  late TextEditingController _schoolController;
  late TextEditingController _heightController;
  late TextEditingController _jobTitleController;
  late TextEditingController _livingInController;
  late TextEditingController _topArtistController;
  late TextEditingController _companyController;

  List<String> _interests = [];
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isRefreshingMedia = false;
  double _saveButtonOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    Future.microtask(() => _refreshUserMedia());
  }

  void _initializeUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _ageController = TextEditingController(text: user?.age.toString() ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _interestController = TextEditingController();
    _interests = user?.interests ?? [];
    _schoolController = TextEditingController(text: user?.school ?? '');
    _heightController = TextEditingController(
      text: user?.height?.toString() ?? '',
    );
    _jobTitleController = TextEditingController(text: user?.jobTitle ?? '');
    _livingInController = TextEditingController(text: user?.livingIn ?? '');
    _topArtistController = TextEditingController(text: user?.topArtist ?? '');
    _companyController = TextEditingController(text: user?.company ?? '');
  }

  Future<void> _refreshUserMedia() async {
    if (_isRefreshingMedia) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.token == null) return;

    _isRefreshingMedia = true;
    try {
      await authProvider.fetchUserMedia();
      if (authProvider.user?.interests != null) {
        setState(() {
          _interests = authProvider.user!.interests;
        });
      }
    } catch (error) {
      print('Error refreshing media: $error');
    } finally {
      _isRefreshingMedia = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _interestController.dispose();
    _schoolController.dispose();
    _heightController.dispose();
    _jobTitleController.dispose();
    _livingInController.dispose();
    _topArtistController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Error selecting image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Choose Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF3B82F6),
                ),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.secondary),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _addInterest(String interest) {
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
      });
    }
  }

  void _removeInterest(int index) {
    setState(() {
      _interests.removeAt(index);
    });
  }

  Future<void> _pickMediaImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentMediaCount = authProvider.user?.media.length ?? 0;

        if (currentMediaCount + pickedFiles.length > 6) {
          _showErrorDialog(
            'Maximum 6 photos allowed. You have $currentMediaCount photos and tried to add ${pickedFiles.length} more.',
          );
          return;
        }

        setState(() => _isLoading = true);
        try {
          final files = pickedFiles.map((xfile) => File(xfile.path)).toList();
          await authProvider.addUserMedia(files);
          await _refreshUserMedia();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Added ${pickedFiles.length} photo(s)'),
                ],
              ),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } catch (error) {
          _showErrorDialog('Failed to upload photos: $error');
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      _showErrorDialog('Error selecting images: $e');
    }
  }

  Future<void> _removeMedia(String filename) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.removeUserMedia(filename);
                await _refreshUserMedia();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Photo removed'),
                      ],
                    ),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              } catch (error) {
                _showErrorDialog('Failed to remove photo: $error');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    // Animate button press
    setState(() => _saveButtonOpacity = 0.7);
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _saveButtonOpacity = 1.0);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final bio = _bioController.text.trim();
    final school = _schoolController.text.trim();
    final height = int.tryParse(_heightController.text.trim());
    final jobTitle = _jobTitleController.text.trim();
    final livingIn = _livingInController.text.trim();
    final topArtist = _topArtistController.text.trim();
    final company = _companyController.text.trim();

    if (name.isEmpty) {
      _showErrorDialog('Please enter your name');
      return;
    }

    if (age == null || age < 13) {
      _showErrorDialog('Please enter a valid age (must be at least 13)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await authProvider.updateProfile(
        name: name,
        age: age,
        bio: bio,
        interests: _interests,
        school: school,
        height: height,
        jobTitle: jobTitle,
        livingIn: livingIn,
        topArtist: topArtist,
        company: company,
        photo: _selectedImage,
      );

      // Success animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.secondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profile updated successfully!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pop();
    } catch (error) {
      _showErrorDialog('Failed to update profile: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF475569),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: _saveProfile,
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Photo Section
                    _buildProfilePhotoSection(user),
                    const SizedBox(height: 24),

                    // Media Gallery Widget
                    MediaGalleryWidget(
                      onPickMediaImages: _pickMediaImages,
                      onRemoveMedia: _removeMedia,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 16),

                    // Bio & Interests Widget
                    BioAndInterestsWidget(
                      bioController: _bioController,
                      interestController: _interestController,
                      interests: _interests,
                      onAddInterest: _addInterest,
                      onRemoveInterest: _removeInterest,
                    ),
                    const SizedBox(height: 16),

                    // Personal Information Widget
                    PersonalInfoWidget(
                      nameController: _nameController,
                      ageController: _ageController,
                      schoolController: _schoolController,
                      heightController: _heightController,
                      jobTitleController: _jobTitleController,
                      livingInController: _livingInController,
                      topArtistController: _topArtistController,
                      companyController: _companyController,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    AnimatedOpacity(
                      opacity: _saveButtonOpacity,
                      duration: const Duration(milliseconds: 200),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (user?.photo != null && user!.photo.isNotEmpty
                            ? Image.network(
                                'http://10.0.2.2:5000/uploads/${user.photo}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(),
                              )
                            : _buildDefaultAvatar()),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (_selectedImage != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedImage != null
                ? 'New photo selected'
                : 'Tap to change photo',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(Icons.person, size: 48, color: Color(0xFFCBD5E1)),
      ),
    );
  }
}
