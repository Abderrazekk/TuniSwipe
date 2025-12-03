// models/user.dart - COMPLETE FILE
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String token;
  final String bio;
  final String gender;
  final List<String> interests;
  final String photo;
  final int age;
  final List<UserMedia> media;
  final String school;
  final int? height;
  final String jobTitle;
  final String livingIn;
  final String topArtist;
  final String company;
  final double? distance;
  final List<ProfileImage> allImages; // NEW: Unified images list

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    required this.bio,
    required this.gender,
    required this.interests,
    required this.photo,
    required this.age,
    required this.media,
    this.school = '',
    this.height,
    this.jobTitle = '',
    this.livingIn = '',
    this.topArtist = '',
    this.company = '',
    this.distance,
    required this.allImages, // REQUIRED: Unified images
  });

  // NEW: Get all image URLs (from unified images list)
  List<String> get allImageUrls {
    final baseUrl = 'http://10.0.2.2:5000/uploads/';
    return allImages
        .where((img) => img.filename.isNotEmpty)
        .map((img) => '$baseUrl${img.filename}')
        .toList();
  }

  // NEW: Get profile image URL (first image)
  String get profileImageUrl {
    if (allImages.isNotEmpty) {
      final baseUrl = 'http://10.0.2.2:5000/uploads/';
      return '$baseUrl${allImages.first.filename}';
    }
    return '';
  }

  // NEW: Get total number of images
  int get totalImages => allImages.length;

  // NEW: Check if user has images
  bool get hasImages => allImages.isNotEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    print('👤 Creating User object from JSON');
    print('📸 Checking for unified images field...');

    int parsedAge = 0;
    if (json['age'] != null) {
      if (json['age'] is int) {
        parsedAge = json['age'];
      } else if (json['age'] is String) {
        parsedAge = int.tryParse(json['age']) ?? 0;
      } else if (json['age'] is double) {
        parsedAge = json['age'].toInt();
      }
    }

    String parsedGender = '';
    if (json['gender'] != null) {
      if (json['gender'] is String) {
        parsedGender = json['gender'];
      }
    }

    List<String> parsedInterests = [];
    if (json['interests'] != null) {
      if (json['interests'] is List) {
        parsedInterests = List<String>.from(
          json['interests'].map((item) => item.toString()),
        );
      }
    }

    int? parsedHeight;
    if (json['height'] != null) {
      if (json['height'] is int) {
        parsedHeight = json['height'];
      } else if (json['height'] is String) {
        parsedHeight = int.tryParse(json['height']);
      } else if (json['height'] is double) {
        parsedHeight = json['height'].toInt();
      }
    }

    List<UserMedia> parsedMedia = [];
    if (json['media'] != null && json['media'] is List) {
      parsedMedia = (json['media'] as List).map((mediaJson) {
        return UserMedia.fromJson(mediaJson);
      }).toList();
    }

    double? parsedDistance;
    if (json['distance'] != null) {
      if (json['distance'] is double) {
        parsedDistance = json['distance'];
      } else if (json['distance'] is int) {
        parsedDistance = json['distance'].toDouble();
      } else if (json['distance'] is String) {
        parsedDistance = double.tryParse(json['distance']);
      }
    }

    // NEW: Parse unified images array (profile + media combined)
    List<ProfileImage> parsedAllImages = [];
    if (json['images'] != null && json['images'] is List) {
      print('✅ Found unified images field with ${json['images'].length} items');
      parsedAllImages = (json['images'] as List).map((imgJson) {
        return ProfileImage.fromJson(imgJson);
      }).toList();
    } else {
      // Fallback: Combine profile photo and media manually
      print('⚠️ No unified images field, combining profile + media');
      parsedAllImages = _parseLegacyImages(json);
    }

    // Log image information
    print('📊 Image Summary:');
    print('   Total unified images: ${parsedAllImages.length}');
    print('   Profile image: ${parsedAllImages.isNotEmpty ? parsedAllImages.first.filename : "none"}');
    print('   Media count: ${parsedMedia.length}');

    return User(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      token: json['token']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      gender: parsedGender,
      interests: parsedInterests,
      photo: json['photo']?.toString() ?? '',
      age: parsedAge,
      media: parsedMedia,
      school: json['school']?.toString() ?? '',
      height: parsedHeight,
      jobTitle: json['jobTitle']?.toString() ?? '',
      livingIn: json['livingIn']?.toString() ?? '',
      topArtist: json['topArtist']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      distance: parsedDistance,
      allImages: parsedAllImages, // Use unified images
    );
  }

  // Helper method to parse legacy format (profile + separate media)
  static List<ProfileImage> _parseLegacyImages(Map<String, dynamic> json) {
    final images = <ProfileImage>[];
    
    // Add profile photo as first image
    String profilePhoto = '';
    if (json['photo'] != null && json['photo'].toString().isNotEmpty) {
      profilePhoto = json['photo'].toString();
    }
    
    if (profilePhoto.isNotEmpty) {
      images.add(ProfileImage(
        id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        filename: profilePhoto,
        type: 'profile',
        isProfile: true,
        uploadDate: DateTime.now(),
      ));
      print('📸 Added profile image: $profilePhoto');
    }

    // Add media images
    if (json['media'] != null && json['media'] is List) {
      final mediaList = json['media'] as List;
      print('🖼️ Found ${mediaList.length} media items');
      
      for (var mediaJson in mediaList) {
        try {
          images.add(ProfileImage.fromJson({
            ...mediaJson,
            'type': 'media',
            'isProfile': false,
          }));
        } catch (e) {
          print('❌ Error parsing media item: $e');
        }
      }
    }

    return images;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'token': token,
      'bio': bio,
      'gender': gender,
      'interests': interests,
      'photo': photo,
      'age': age,
      'school': school,
      'height': height,
      'jobTitle': jobTitle,
      'livingIn': livingIn,
      'topArtist': topArtist,
      'company': company,
      'distance': distance,
      'media': media
          .map(
            (m) => {
              'filename': m.filename,
              'originalName': m.originalName,
              'uploadDate': m.uploadDate.toIso8601String(),
            },
          )
          .toList(),
      'images': allImages // NEW: Include unified images
          .map(
            (img) => {
              'id': img.id,
              'filename': img.filename,
              'type': img.type,
              'isProfile': img.isProfile,
              'uploadDate': img.uploadDate.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? token,
    String? bio,
    String? gender,
    List<String>? interests,
    String? photo,
    int? age,
    List<UserMedia>? media,
    String? school,
    int? height,
    String? jobTitle,
    String? livingIn,
    String? topArtist,
    String? company,
    double? distance,
    List<ProfileImage>? allImages, // NEW
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      photo: photo ?? this.photo,
      age: age ?? this.age,
      media: media ?? this.media,
      school: school ?? this.school,
      height: height ?? this.height,
      jobTitle: jobTitle ?? this.jobTitle,
      livingIn: livingIn ?? this.livingIn,
      topArtist: topArtist ?? this.topArtist,
      company: company ?? this.company,
      distance: distance ?? this.distance,
      allImages: allImages ?? this.allImages, // NEW
    );
  }

  factory User.fromProfileJson(Map<String, dynamic> json) {
    List<UserMedia> parsedMedia = [];
    if (json['media'] != null && json['media'] is List) {
      parsedMedia = (json['media'] as List).map((mediaJson) {
        return UserMedia.fromJson(mediaJson);
      }).toList();
    }

    // NEW: Parse unified images
    List<ProfileImage> parsedAllImages = [];
    if (json['images'] != null && json['images'] is List) {
      parsedAllImages = (json['images'] as List).map((imgJson) {
        return ProfileImage.fromJson(imgJson);
      }).toList();
    } else {
      parsedAllImages = _parseLegacyImages(json);
    }

    return User(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      token: '',
      bio: json['bio']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      photo: json['photo']?.toString() ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      media: parsedMedia,
      school: json['school']?.toString() ?? '',
      height: json['height'] is int
          ? json['height']
          : int.tryParse(json['height']?.toString() ?? ''),
      jobTitle: json['jobTitle']?.toString() ?? '',
      livingIn: json['livingIn']?.toString() ?? '',
      topArtist: json['topArtist']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      distance: json['distance'] is double
          ? json['distance']
          : double.tryParse(json['distance']?.toString() ?? ''),
      allImages: parsedAllImages, // NEW
    );
  }

  // FIXED: Updated fromMatchJson to parse unified images
  factory User.fromMatchJson(Map<String, dynamic> json) {
    print('👤 Creating User from match JSON');
    print('📸 Checking images field: ${json['images'] != null}');

    int parsedAge = 0;
    if (json['age'] != null) {
      if (json['age'] is int) {
        parsedAge = json['age'];
      } else if (json['age'] is String) {
        parsedAge = int.tryParse(json['age']) ?? 0;
      } else if (json['age'] is double) {
        parsedAge = json['age'].toInt();
      }
    }

    int? parsedHeight;
    if (json['height'] != null) {
      if (json['height'] is int) {
        parsedHeight = json['height'];
      } else if (json['height'] is String) {
        parsedHeight = int.tryParse(json['height']);
      } else if (json['height'] is double) {
        parsedHeight = json['height'].toInt();
      }
    }

    List<String> parsedInterests = [];
    if (json['interests'] != null && json['interests'] is List) {
      try {
        parsedInterests = List<String>.from(
          json['interests'].map((item) => item?.toString() ?? ''),
        );
      } catch (e) {
        print('❌ Error parsing interests: $e');
        parsedInterests = [];
      }
    }

    List<UserMedia> parsedMedia = [];
    if (json['media'] != null && json['media'] is List) {
      print('📸 Parsing media array with ${json['media'].length} items');
      try {
        parsedMedia = (json['media'] as List).map((mediaJson) {
          return UserMedia.fromJson(mediaJson);
        }).toList();
      } catch (e) {
        print('❌ Error parsing media: $e');
        parsedMedia = [];
      }
    }

    // NEW: Parse unified images array (backend should send this)
    List<ProfileImage> parsedAllImages = [];
    if (json['images'] != null && json['images'] is List) {
      print('✅ Using unified images array with ${json['images'].length} items');
      try {
        parsedAllImages = (json['images'] as List).map((imgJson) {
          return ProfileImage.fromJson(imgJson);
        }).toList();
      } catch (e) {
        print('❌ Error parsing unified images: $e');
        // Fallback to legacy format
        parsedAllImages = _parseLegacyImages(json);
      }
    } else {
      // Fallback to legacy format
      print('⚠️ No unified images field, using legacy format');
      parsedAllImages = _parseLegacyImages(json);
    }

    double? parsedDistance;
    if (json['distance'] != null) {
      if (json['distance'] is double) {
        parsedDistance = json['distance'];
      } else if (json['distance'] is int) {
        parsedDistance = json['distance'].toDouble();
      } else if (json['distance'] is String) {
        parsedDistance = double.tryParse(json['distance']);
      }
    }

    // Get the main photo (profile photo) for backward compatibility
    String profilePhoto = '';
    if (json['photo'] != null && json['photo'].toString().isNotEmpty) {
      profilePhoto = json['photo'].toString();
    } else if (json['mainPhoto'] != null && json['mainPhoto'].toString().isNotEmpty) {
      profilePhoto = json['mainPhoto'].toString();
    } else if (parsedAllImages.isNotEmpty) {
      // Use first image from unified list
      profilePhoto = parsedAllImages.first.filename;
    }

    print('✅ Created user with:');
    print('   Name: ${json['name']}');
    print('   Age: $parsedAge');
    print('   Unified images count: ${parsedAllImages.length}');
    print('   Profile Photo: $profilePhoto');
    print('   Media count: ${parsedMedia.length}');

    return User(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      token: '',
      bio: json['bio']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      interests: parsedInterests,
      photo: profilePhoto,
      age: parsedAge,
      media: parsedMedia,
      school: json['school']?.toString() ?? '',
      height: parsedHeight,
      jobTitle: json['jobTitle']?.toString() ?? '',
      livingIn: json['livingIn']?.toString() ?? '',
      topArtist: json['topArtist']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      distance: parsedDistance,
      allImages: parsedAllImages, // This is the important new field
    );
  }

  // NEW: Helper to get default user (for empty states)
  factory User.defaultUser() {
    return User(
      id: '',
      name: '',
      email: '',
      role: 'user',
      token: '',
      bio: '',
      gender: '',
      interests: [],
      photo: '',
      age: 0,
      media: [],
      school: '',
      height: null,
      jobTitle: '',
      livingIn: '',
      topArtist: '',
      company: '',
      distance: null,
      allImages: [],
    );
  }
}

// Original UserMedia class (kept for backward compatibility)
class UserMedia {
  final String filename;
  final String originalName;
  final DateTime uploadDate;

  UserMedia({
    required this.filename,
    required this.originalName,
    required this.uploadDate,
  });

  factory UserMedia.fromJson(Map<String, dynamic> json) {
    return UserMedia(
      filename: json['filename']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'])
          : DateTime.now(),
    );
  }

  String get imageUrl => 'http://10.0.2.2:5000/uploads/$filename';
}

// NEW: ProfileImage class for unified image handling
class ProfileImage {
  final String id;
  final String filename;
  final String type; // 'profile' or 'media'
  final bool isProfile;
  final DateTime uploadDate;
  
  ProfileImage({
    required this.id,
    required this.filename,
    this.type = 'media',
    this.isProfile = false,
    required this.uploadDate,
  });
  
  factory ProfileImage.fromJson(Map<String, dynamic> json) {
    return ProfileImage(
      id: json['id']?.toString() ?? 
          json['_id']?.toString() ?? 
          json['filename']?.toString() ?? 
          DateTime.now().millisecondsSinceEpoch.toString(),
      filename: json['filename']?.toString() ?? '',
      type: json['type']?.toString() ?? 'media',
      isProfile: json['isProfile'] ?? false,
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'])
          : DateTime.now(),
    );
  }
  
  String get imageUrl => 'http://10.0.2.2:5000/uploads/$filename';
  
  // Convert to map for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'type': type,
      'isProfile': isProfile,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }
  
  @override
  String toString() {
    return 'ProfileImage(id: $id, filename: $filename, type: $type, isProfile: $isProfile)';
  }
}

// NEW: Helper class for swipe card data
class SwipeCardData {
  final String userId;
  final String name;
  final int age;
  final String bio;
  final List<String> interests;
  final List<String> imageUrls;
  final String jobTitle;
  final String school;
  final String livingIn;
  final double? distance;
  
  SwipeCardData({
    required this.userId,
    required this.name,
    required this.age,
    required this.bio,
    required this.interests,
    required this.imageUrls,
    required this.jobTitle,
    required this.school,
    required this.livingIn,
    this.distance,
  });
  
  factory SwipeCardData.fromUser(User user) {
    return SwipeCardData(
      userId: user.id,
      name: user.name,
      age: user.age,
      bio: user.bio,
      interests: user.interests,
      imageUrls: user.allImageUrls,
      jobTitle: user.jobTitle,
      school: user.school,
      livingIn: user.livingIn,
      distance: user.distance,
    );
  }
}