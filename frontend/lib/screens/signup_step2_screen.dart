import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SignUpStep2Screen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const SignUpStep2Screen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  _SignUpStep2ScreenState createState() => _SignUpStep2ScreenState();
}

class _SignUpStep2ScreenState extends State<SignUpStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;
  List<String> _selectedInterests = [];
  File? _selectedImage;

  bool _isLoading = false;

  final List<String> _availableInterests = [
    'Technology',
    'Sports',
    'Music',
    'Art',
    'Travel',
    'Food',
    'Reading',
    'Gaming',
    'Fitness',
    'Photography',
    'Movies',
    'Cooking',
  ];

  // Function to calculate age from birth date
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    final monthDifference = today.month - birthDate.month;

    if (monthDifference < 0 ||
        (monthDifference == 0 && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  void _completeSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your gender')),
        );
        return;
      }

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your birth date')),
        );
        return;
      }

      // Calculate age from selected date
      final age = _calculateAge(_selectedDate!);

      // DEBUG: Print the calculated age
      print('🎯 DEBUG: Selected date: $_selectedDate');
      print('🎯 DEBUG: Calculated age: $age');
      print('🎯 DEBUG: Gender: $_selectedGender');
      print('🎯 DEBUG: Interests: $_selectedInterests');

      setState(() => _isLoading = true);

      try {
        print('🔄 Starting signup process...');

        await Provider.of<AuthProvider>(context, listen: false).signUp(
          name: widget.name,
          email: widget.email,
          password: widget.password,
          bio: _bioController.text.trim(),
          gender: _selectedGender!,
          interests: _selectedInterests,
          age: age,
          photo: _selectedImage,
        );

        print('✅ Signup completed successfully in provider');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please sign in.'),
            backgroundColor: Colors.green,
          ),
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/signin');
      } catch (error) {
        print('❌ Signup error in screen: $error');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Profile - Step 2'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Step 2 of 2: Add your profile details',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Photo
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : null,
                          child: _selectedImage == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedImage == null
                            ? 'Tap to add profile photo'
                            : 'Photo selected. Tap to change',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      // Bio
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Bio (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      // Gender
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select your gender';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Birth Date (now used to calculate age)
                      GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Birth Date *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.cake),
                              suffixIcon: _selectedDate != null
                                  ? Text(
                                      'Age: ${_calculateAge(_selectedDate!)}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            controller: TextEditingController(
                              text: _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : '',
                            ),
                            validator: (value) {
                              if (_selectedDate == null) {
                                return 'Please select your birth date';
                              }
                              final age = _calculateAge(_selectedDate!);
                              if (age < 16) {
                                return 'You must be at least 16 years old';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Interests
                      const Text(
                        'Interests (Select at least one)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(
                            interest,
                          );
                          return FilterChip(
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (selected) => _toggleInterest(interest),
                            selectedColor: Colors.blue[100],
                            checkmarkColor: Colors.blue,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),

                      // Create Account Button
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _completeSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
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
    );
  }
}
