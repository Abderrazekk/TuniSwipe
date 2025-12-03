import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math' as math;
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false; // Add initialization flag

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialized =>
      _isInitialized; // Add getter for initialization status

  AuthProvider() {
    _initialize(); // Change from _loadUser() to _initialize()
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    // Add delay to ensure SharedPreferences is ready
    await Future.delayed(const Duration(milliseconds: 100));

    await _loadUser();

    _isInitialized = true; // Mark as initialized
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');

      if (userData != null) {
        final decodedData = json.decode(userData);
        print('🔍 Loading user from storage: ${decodedData['email']}');
        print('🔍 User role from storage: ${decodedData['role']}');
        print('🔍 Token from storage: ${decodedData['token']}'); // Debug token

        if (decodedData['token'] != null && decodedData['token'].isNotEmpty) {
          _user = User.fromJson(decodedData);
          print(
            '✅ User loaded successfully with token: ${_user!.token.substring(0, math.min(20, _user!.token.length))}...',
          );
        } else {
          print(
            '❌ Token is null or empty in stored data, clearing invalid data',
          );
          await _clearInvalidData();
        }
      } else {
        print('🔍 No user data found in storage');
      }
    } catch (error) {
      print('❌ Error loading user from storage: $error');
      await _clearInvalidData();
    }
  }

  Future<void> _clearInvalidData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      _user = null;
      print('🧹 Cleared invalid user data from storage');
    } catch (error) {
      print('❌ Error clearing invalid data: $error');
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String bio = '',
    required String gender,
    required List<String> interests,
    required int age,
    File? photo,
    // REMOVED: school, height, jobTitle, livingIn, topArtist, company
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('👤 Starting signup process for: $email');
      print('📦 Signup data:');
      print('   Name: $name');
      print('   Email: $email');
      print('   Gender: $gender');
      print('   Age: $age');
      print('   Bio: $bio');
      print('   Interests: $interests');
      print('   Has photo: ${photo != null}');
      // REMOVED: Printing new fields

      // Create multipart request for signup with photo
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/api/auth/user/signup'),
      );

      // Add text fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['bio'] = bio;
      request.fields['gender'] = gender;
      request.fields['interests'] = json.encode(interests);
      request.fields['age'] = age.toString();
      // REMOVED: New fields

      print('📦 Request fields: ${request.fields}');

      // Add photo file if exists
      if (photo != null) {
        print('📸 Adding profile photo: ${photo.path}');
        var multipartFile = await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
        print('✅ Photo file added to request');
      }

      // Send request
      print('🚀 Sending signup request...');
      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var responseData = json.decode(responseString);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: $responseString');

      if (response.statusCode == 201) {
        if (responseData['success'] == true) {
          print('✅ Signup successful: ${responseData['data']['email']}');
          print('🎯 User role: ${responseData['data']['role']}');
          print(
            '🔐 Token received: ${responseData['data']['token']?.substring(0, 20)}...',
          );

          // Store user data and token
          _user = User.fromJson(responseData['data']);
          await _saveUser(responseData['data']);
          notifyListeners();

          print('✅ User account created and saved successfully!');
        } else {
          throw Exception(responseData['message'] ?? 'Signup failed');
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (error) {
      print('❌ Signup error: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          print('✅ Signin response: ${responseData['data']}');
          print('🎯 Detected role: ${responseData['data']['role']}');
          print(
            '🔐 Token received: ${responseData['data']['token']}',
          ); // Debug token

          _user = User.fromJson(responseData['data']);
          await _saveUser(responseData['data']);
          notifyListeners();
        } else {
          throw Exception(responseData['message'] ?? 'Signin failed');
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    _user = null;
    notifyListeners();
  }

  Future<void> _saveUser(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(userData));
      print('💾 User saved to storage: ${userData['email']}');
      print('💾 Role saved: ${userData['role']}');
      print('💾 Token saved: ${userData['token']}'); // Debug token saving
    } catch (error) {
      print('❌ Error saving user to storage: $error');
      rethrow;
    }
  }

  Future<void> fetchCompleteProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      // ignore: unused_local_variable
      final prefs = await SharedPreferences.getInstance();
      final token = _user?.token;

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/auth/complete-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          print('✅ Complete profile response: ${responseData['data']}');
          _user = User.fromJson(responseData['data']);
          await _saveUser(responseData['data']);
          notifyListeners();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch profile');
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (error) {
      print('❌ Complete profile fetch error: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String name,
    required int age,
    required String bio,
    required List<String> interests,
    // ADD NEW FIELDS
    required String school,
    required int? height,
    required String jobTitle,
    required String livingIn,
    required String topArtist,
    required String company,
    File? photo,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Store current token before making request
      final currentToken = _user!.token;

      print('✏️ Updating profile with:');
      print('   Name: $name');
      print('   Age: $age');
      print('   Bio: $bio');
      print('   Interests: $interests');
      print('   School: $school');
      print('   Height: $height');
      print('   Job Title: $jobTitle');
      print('   Living In: $livingIn');
      print('   Top Artist: $topArtist');
      print('   Company: $company');
      print('   Has new photo: ${photo != null}');

      // DEBUG: Check if user and token exist
      print('   User: ${_user?.email}');
      print('   Token: ${_user?.token}');

      if (_user?.token == null) {
        print('❌ No token available for authorization');
        throw Exception('No authentication token found. Please sign in again.');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://10.0.2.2:5000/api/auth/profile'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer ${_user!.token}';
      print(
        '🔐 Authorization header set with token: Bearer ${_user!.token.substring(0, 20)}...',
      );

      // Add text fields
      request.fields['name'] = name;
      request.fields['age'] = age.toString();
      request.fields['bio'] = bio;
      request.fields['interests'] = json.encode(interests);
      // ADD NEW FIELDS
      request.fields['school'] = school;
      request.fields['height'] = height?.toString() ?? '';
      request.fields['jobTitle'] = jobTitle;
      request.fields['livingIn'] = livingIn;
      request.fields['topArtist'] = topArtist;
      request.fields['company'] = company;

      print('📦 Request fields: ${request.fields}');

      // Add image file if exists
      if (photo != null) {
        print('📸 Adding photo file: ${photo.path}');
        var multipartFile = await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
        print('✅ Photo file added to request');
      }

      // Log final headers before sending
      print('📨 Final request headers: ${request.headers}');

      // Send request
      print('🚀 Sending update profile request...');
      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var responseData = json.decode(responseString);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: $responseString');

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          print('✅ Profile updated successfully: ${responseData['data']}');

          // Update the user in the provider WITH TOKEN PRESERVED
          final updatedUser = User.fromJson(responseData['data']);
          _user = updatedUser.copyWith(token: currentToken); // Preserve token

          await _saveUser(_user!.toJson());
          notifyListeners();

          print(
            // ignore: unnecessary_null_comparison
            '✅ Token preserved after profile update: ${_user!.token != null}',
          );
        } else {
          throw Exception(responseData['message'] ?? 'Profile update failed');
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (error) {
      print('❌ Profile update error: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /************** media */

  Future<void> addUserMedia(List<File> mediaFiles) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('📸 Adding ${mediaFiles.length} media files');

      if (_user?.token == null) {
        print('❌ No authentication token found');
        throw Exception('No authentication token found. Please sign in again.');
      }

      // Store current token before making request
      final currentToken = _user!.token;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/api/auth/media'),
      );

      request.headers['Authorization'] = 'Bearer ${_user!.token.trim()}';

      for (var i = 0; i < mediaFiles.length; i++) {
        var file = mediaFiles[i];
        print('📁 Adding file ${i + 1}: ${file.path}');

        var multipartFile = await http.MultipartFile.fromPath(
          'media',
          file.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      print('🚀 Sending media upload request...');
      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var responseData = json.decode(responseString);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: $responseString');

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          print('✅ Media uploaded successfully');

          // FIXED: Preserve the token when updating user
          _user = User(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
            role: _user!.role,
            token: currentToken, // PRESERVE THE ORIGINAL TOKEN
            bio: _user!.bio,
            gender: _user!.gender,
            interests: _user!.interests,
            photo: _user!.photo,
            age: _user!.age,
            // NEW FIELDS PRESERVED
            school: _user!.school,
            height: _user!.height,
            jobTitle: _user!.jobTitle,
            livingIn: _user!.livingIn,
            topArtist: _user!.topArtist,
            company: _user!.company,
            allImages: _user!.allImages,
            media: (responseData['data']['media'] as List).map((mediaJson) {
              return UserMedia.fromJson(mediaJson);
            }).toList(),
          );

          // Update stored user data WITH TOKEN
          await _saveUser(_user!.toJson());
          notifyListeners();

          print(
            // ignore: unnecessary_null_comparison
            '✅ Token preserved after media upload: ${_user!.token != null}',
          );
        } else {
          throw Exception(responseData['message'] ?? 'Media upload failed');
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (error) {
      print('❌ Media upload error: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeUserMedia(String filename) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🗑️ Removing media file: $filename');

      if (_user?.token == null) {
        throw Exception('No authentication token found');
      }

      // Store current token before making request
      final currentToken = _user!.token;

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:5000/api/auth/media/$filename'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          print('✅ Media removed successfully');

          _user = User(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
            role: _user!.role,
            token: currentToken, // PRESERVE THE ORIGINAL TOKEN
            bio: _user!.bio,
            gender: _user!.gender,
            interests: _user!.interests,
            photo: _user!.photo,
            age: _user!.age,
            // NEW FIELDS PRESERVED
            school: _user!.school,
            height: _user!.height,
            jobTitle: _user!.jobTitle,
            livingIn: _user!.livingIn,
            topArtist: _user!.topArtist,
            company: _user!.company,
            allImages: _user!.allImages,
            media: (responseData['data']['media'] as List).map((mediaJson) {
              return UserMedia.fromJson(mediaJson);
            }).toList(),
          );

          await _saveUser(_user!.toJson());
          notifyListeners();

          print(
            // ignore: unnecessary_null_comparison
            '✅ Token preserved after media removal: ${_user!.token != null}',
          );
        } else {
          throw Exception(responseData['message'] ?? 'Media removal failed');
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (error) {
      print('❌ Media removal error: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserMedia() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user?.token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/auth/media'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user!.token}',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          print(
            '✅ Media fetched successfully: ${responseData['data']['media']}',
          );
          _user = User(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
            role: _user!.role,
            token: _user!.token, // PRESERVE TOKEN
            bio: _user!.bio,
            gender: _user!.gender,
            interests: _user!.interests,
            photo: _user!.photo,
            age: _user!.age,
            // NEW FIELDS PRESERVED
            school: _user!.school,
            height: _user!.height,
            jobTitle: _user!.jobTitle,
            livingIn: _user!.livingIn,
            topArtist: _user!.topArtist,
            company: _user!.company,
            allImages: _user!.allImages,
            media: (responseData['data']['media'] as List).map((mediaJson) {
              return UserMedia.fromJson(mediaJson);
            }).toList(),
          );

          await _saveUser(_user!.toJson());
          notifyListeners();

          print('🔄 Media list updated. Count: ${_user!.media.length}');
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch media');
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (error) {
      print('❌ Media fetch error: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAgeFilter({
    required bool ageFilterEnabled,
    required int minAgeFilter,
    required int maxAgeFilter,
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final currentToken = _user!.token;

      if (currentToken.isEmpty) {
        throw Exception('No authentication token found');
      }

      print('🎂 Updating age filter settings');
      print('   Enabled: $ageFilterEnabled');
      print('   Min Age: $minAgeFilter');
      print('   Max Age: $maxAgeFilter');

      final response = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/auth/age-filter'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
        body: json.encode({
          'ageFilterEnabled': ageFilterEnabled,
          'minAgeFilter': minAgeFilter,
          'maxAgeFilter': maxAgeFilter,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ Age filter updated successfully');

        // Update the user in the provider WITH TOKEN PRESERVED
        _user = _user!.copyWith(
          ageFilterEnabled: ageFilterEnabled,
          minAgeFilter: minAgeFilter,
          maxAgeFilter: maxAgeFilter,
        );
        await _saveUser(_user!.toJson());
        notifyListeners();

        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ageFilterEnabled
                    ? 'Age filter set to $minAgeFilter-$maxAgeFilter'
                    : 'Age filter disabled',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to update age filter',
        );
      }
    } catch (error) {
      print('❌ Age filter update error: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
