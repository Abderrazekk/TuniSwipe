// models/user.dart
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
  });

  // NEW: Get all image URLs (profile + media)
  List<String> get allImageUrls {
    final baseUrl = 'http://10.0.2.2:5000/uploads/';
    final urls = <String>[];
    
    // Add profile image first
    if (photo.isNotEmpty) {
      urls.add('$baseUrl$photo');
    }
    
    // Add media images
    for (final mediaItem in media) {
      if (mediaItem.filename.isNotEmpty) {
        urls.add('$baseUrl${mediaItem.filename}');
      }
    }
    
    return urls;
  }

  // NEW: Get total number of images
  int get totalImages => allImageUrls.length;

  factory User.fromJson(Map<String, dynamic> json) {
    print('👤 Creating User object from JSON');

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
    );
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
    );
  }

  factory User.fromProfileJson(Map<String, dynamic> json) {
    List<UserMedia> parsedMedia = [];
    if (json['media'] != null && json['media'] is List) {
      parsedMedia = (json['media'] as List).map((mediaJson) {
        return UserMedia.fromJson(mediaJson);
      }).toList();
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
    );
  }

  // FIXED: Updated fromMatchJson to parse media correctly
  factory User.fromMatchJson(Map<String, dynamic> json) {
    print('👤 Creating User from match JSON');
    print('📸 Media field in JSON: ${json['media']}');

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

    // FIX: Parse media array from JSON
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

    // Get the main photo (profile photo)
    String profilePhoto = '';
    if (json['photo'] != null && json['photo'].toString().isNotEmpty) {
      profilePhoto = json['photo'].toString();
    } else if (json['mainPhoto'] != null && json['mainPhoto'].toString().isNotEmpty) {
      profilePhoto = json['mainPhoto'].toString();
    }

    print('✅ Created user with:');
    print('   Name: ${json['name']}');
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
      media: parsedMedia, // This was previously empty, now contains media
      school: json['school']?.toString() ?? '',
      height: parsedHeight,
      jobTitle: json['jobTitle']?.toString() ?? '',
      livingIn: json['livingIn']?.toString() ?? '',
      topArtist: json['topArtist']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      distance: parsedDistance,
    );
  }
}

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