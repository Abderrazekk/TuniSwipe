import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../models/user.dart';

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

  // Add these flags to prevent multiple calls
  // ignore: unused_field
  bool _isInitialized = false;
  bool _isRefreshingMedia = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();

    // Use Future.microtask to ensure build is complete before refreshing
    Future.microtask(() {
      _refreshUserMedia();
    });
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

    print('🎯 Edit Profile Screen - Initialized with user data');
    print('   Name: ${user?.name}');
    print('   Age: ${user?.age}');
    print('   Bio: ${user?.bio}');
    print('   Interests: ${user?.interests}');
    print('   Photo: ${user?.photo}');
    print('   School: ${user?.school}');
    print('   Height: ${user?.height}');
    print('   Job Title: ${user?.jobTitle}');
    print('   Living In: ${user?.livingIn}');
    print('   Top Artist: ${user?.topArtist}');
    print('   Company: ${user?.company}');
    print('   Media count: ${user?.media.length ?? 0}');
    print(
      '   Token: ${user?.token != null ? '${user!.token.substring(0, min(20, user.token.length))}...' : 'null'}',
    );

    _isInitialized = true;
  }

  int min(int a, int b) => a < b ? a : b;

  // FIXED: Only refresh media when needed, not on every dependency change
  Future<void> _refreshUserMedia() async {
    // Prevent multiple simultaneous refresh calls
    if (_isRefreshingMedia) {
      print('⏳ Media refresh already in progress, skipping...');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if token exists before making API call
    if (authProvider.user?.token == null) {
      print('❌ Cannot refresh media: Token is null');
      return;
    }

    _isRefreshingMedia = true;

    try {
      print('🔄 Starting media refresh...');
      await authProvider.fetchUserMedia();

      print('✅ Media refreshed successfully');
      print('   Media count: ${authProvider.user?.media.length ?? 0}');

      // Update the interests list with fresh data
      if (authProvider.user?.interests != null) {
        setState(() {
          _interests = authProvider.user!.interests;
        });
      }
    } catch (error) {
      print('❌ Error refreshing media: $error');
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

  // Image picking methods
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        print('📸 Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      _showErrorDialog('Error selecting image: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: const Text('Select where to pick the image from'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
        ],
      ),
    );
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
        _interestController.clear();
      });
    }
  }

  void _removeInterest(int index) {
    setState(() {
      _interests.removeAt(index);
    });
  }

  // Media methods
  Future<void> _pickMediaImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentMediaCount = authProvider.user?.media.length ?? 0;

        if (currentMediaCount + pickedFiles.length > 6) {
          _showErrorDialog(
            'You can only have 6 photos maximum. You currently have $currentMediaCount and tried to add ${pickedFiles.length}.',
          );
          return;
        }

        setState(() {
          _isLoading = true;
        });

        try {
          final files = pickedFiles.map((xfile) => File(xfile.path)).toList();
          await authProvider.addUserMedia(files);

          // Refresh media after upload
          await _refreshUserMedia();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully added ${pickedFiles.length} photo(s)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (error) {
          _showErrorDialog('Failed to upload photos: $error');
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error picking media images: $e');
      _showErrorDialog('Error selecting images: $e');
    }
  }

  Future<void> _removeMedia(String filename) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              setState(() {
                _isLoading = true;
              });

              try {
                await authProvider.removeUserMedia(filename);

                // Refresh media after removal
                await _refreshUserMedia();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo removed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                _showErrorDialog('Failed to remove photo: $error');
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Validate inputs
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

    // Validate height if provided
    if (_heightController.text.trim().isNotEmpty &&
        (height == null || height < 100 || height > 250)) {
      _showErrorDialog('Please enter a valid height between 100 and 250 cm');
      return;
    }

    setState(() {
      _isLoading = true;
    });

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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.of(context).pop();
    } catch (error) {
      _showErrorDialog('Failed to update profile: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Row(
                  children: [
                    // Refresh button for manual refresh only
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshUserMedia,
                      tooltip: 'Refresh Media',
                    ),
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (user?.photo != null && user!.photo.isNotEmpty
                                ? NetworkImage(
                                    'http://10.0.2.2:5000/uploads/${user.photo}',
                                  )
                                : null),
                      child:
                          _selectedImage == null &&
                              (user?.photo == null || user!.photo.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: _showImageSourceDialog,
                        ),
                      ),
                    ),
                    if (_selectedImage != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                            onPressed: _removeSelectedImage,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _selectedImage != null
                        ? 'New photo selected'
                        : 'Tap camera to change photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSection(
                title: 'Personal Information',
                children: [
                  _buildEditableField(
                    label: 'Name',
                    controller: _nameController,
                    icon: Icons.person,
                    hintText: 'Enter your name',
                  ),
                  _buildEditableField(
                    label: 'Age',
                    controller: _ageController,
                    icon: Icons.cake,
                    hintText: 'Enter your age',
                    keyboardType: TextInputType.number,
                  ),
                  _buildEditableField(
                    label: 'School',
                    controller: _schoolController,
                    icon: Icons.school,
                    hintText: 'Enter your school',
                  ),
                  _buildEditableField(
                    label: 'Height (cm)',
                    controller: _heightController,
                    icon: Icons.height,
                    hintText: 'Enter your height in cm',
                    keyboardType: TextInputType.number,
                  ),
                  _buildEditableField(
                    label: 'Job Title',
                    controller: _jobTitleController,
                    icon: Icons.work,
                    hintText: 'Enter your job title',
                  ),
                  _buildEditableField(
                    label: 'Living In',
                    controller: _livingInController,
                    icon: Icons.location_on,
                    hintText: 'Enter your city or area',
                  ),
                  _buildEditableField(
                    label: 'Top Artist',
                    controller: _topArtistController,
                    icon: Icons.music_note,
                    hintText: 'Enter your favorite artist',
                  ),
                  _buildEditableField(
                    label: 'Company',
                    controller: _companyController,
                    icon: Icons.business,
                    hintText: 'Enter your company',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bio Section
              _buildSection(
                title: 'Bio',
                children: [
                  Text(
                    'About Me',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tell us about yourself...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Interests Section
              _buildSection(
                title: 'Interests',
                children: [
                  // Add new interest
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _interestController,
                          decoration: InputDecoration(
                            hintText: 'Add an interest...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          onSubmitted: (_) => _addInterest(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: _addInterest,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Current interests
                  if (_interests.isNotEmpty) ...[
                    Text(
                      'Your Interests:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _interests.asMap().entries.map((entry) {
                        final index = entry.key;
                        final interest = entry.value;
                        return Chip(
                          label: Text(interest),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeInterest(index),
                          backgroundColor: Colors.blue[100],
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Text(
                      'No interests added yet. Add some interests above!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Media Gallery Section
              _buildMediaSection(),

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Media Section Widget
  Widget _buildMediaSection() {
    final user = Provider.of<AuthProvider>(context).user;
    final currentMediaCount = user?.media.length ?? 0;
    final canAddMore = currentMediaCount < 6;

    print('🖼️ Building media section with $currentMediaCount items');

    return _buildSection(
      title: 'Media Gallery',
      children: [
        Text(
          'Add up to 6 photos to your profile',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 12),

        // Media counter
        Row(
          children: [
            Text(
              'Photos: $currentMediaCount/6',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: currentMediaCount >= 6 ? Colors.red : Colors.green,
              ),
            ),
            const Spacer(),
            if (canAddMore)
              ElevatedButton.icon(
                onPressed: _pickMediaImages,
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Add Photos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Media grid
        if (user?.media != null && user!.media.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: user.media.length,
            itemBuilder: (context, index) {
              final media = user.media[index];
              return _buildMediaItem(media, index);
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.photo_library, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No photos yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                if (canAddMore)
                  Text(
                    'Tap "Add Photos" to get started',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Media Item Widget
  Widget _buildMediaItem(UserMedia media, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'http://10.0.2.2:5000/uploads/${media.filename}',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('❌ Error loading image: ${media.filename} - $error');
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeMedia(media.filename),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build section containers
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Helper method to build editable fields
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
