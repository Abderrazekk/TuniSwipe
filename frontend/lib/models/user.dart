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
  // KEEP NEW FIELDS BUT THEY WILL BE EMPTY BY DEFAULT
  final String school;
  final int? height;
  final String jobTitle;
  final String livingIn;
  final String topArtist;
  final String company;

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
    // KEEP NEW FIELDS WITH DEFAULT EMPTY VALUES
    this.school = '',
    this.height,
    this.jobTitle = '',
    this.livingIn = '',
    this.topArtist = '',
    this.company = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('👤 Creating User object from JSON:');
    print('   🆔 ID: ${json['_id']}');
    print('   📛 Name: ${json['name']}');
    print('   📧 Email: ${json['email']}');
    print('   🎯 Role: ${json['role']}');
    print('   📝 Bio: ${json['bio']}');
    print('   🚻 Gender: ${json['gender']}');
    print('   🏷️ Interests: ${json['interests']}');
    print('   📸 Photo: ${json['photo']}');
    print('   🎂 Age: ${json['age']}');
    print('   🏫 School: ${json['school']}');
    print('   📏 Height: ${json['height']}');
    print('   💼 Job Title: ${json['jobTitle']}');
    print('   🏠 Living In: ${json['livingIn']}');
    print('   🎵 Top Artist: ${json['topArtist']}');
    print('   🏢 Company: ${json['company']}');
    print(
      '   🖼️ Media count: ${json['media'] != null ? json['media'].length : 0}',
    );
    print('   🔐 Token: ${json['token']?.substring(0, 20)}...');

    // Parse age
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

    // Parse gender
    String parsedGender = '';
    if (json['gender'] != null) {
      if (json['gender'] is String) {
        parsedGender = json['gender'];
      }
    }

    // Parse interests
    List<String> parsedInterests = [];
    if (json['interests'] != null) {
      if (json['interests'] is List) {
        parsedInterests = List<String>.from(
          json['interests'].map((item) => item.toString()),
        );
      }
    }

    // Parse height
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

    // PARSE MEDIA
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
      token: json['token']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      gender: parsedGender,
      interests: parsedInterests,
      photo: json['photo']?.toString() ?? '',
      age: parsedAge,
      media: parsedMedia,
      // KEEP PARSING NEW FIELDS BUT THEY WILL BE EMPTY IF NOT PROVIDED
      school: json['school']?.toString() ?? '',
      height: parsedHeight,
      jobTitle: json['jobTitle']?.toString() ?? '',
      livingIn: json['livingIn']?.toString() ?? '',
      topArtist: json['topArtist']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
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
    // KEEP NEW FIELDS IN COPYWITH
    String? school,
    int? height,
    String? jobTitle,
    String? livingIn,
    String? topArtist,
    String? company,
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
      // KEEP NEW FIELDS
      school: school ?? this.school,
      height: height ?? this.height,
      jobTitle: jobTitle ?? this.jobTitle,
      livingIn: livingIn ?? this.livingIn,
      topArtist: topArtist ?? this.topArtist,
      company: company ?? this.company,
    );
  }

  factory User.fromProfileJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      token: '', // Not needed for profile cards
      bio: json['bio']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      photo: json['photo']?.toString() ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      media: [], // Not needed for card view
      school: json['school']?.toString() ?? '',
      height: json['height'] is int
          ? json['height']
          : int.tryParse(json['height']?.toString() ?? ''),
      jobTitle: json['jobTitle']?.toString() ?? '',
      livingIn: json['livingIn']?.toString() ?? '',
      topArtist: json['topArtist']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
    );
  }

  factory User.fromMatchJson(Map<String, dynamic> json) {
    print('👤 Creating User from match JSON:');
    print('   🆔 ID: ${json['_id']}');
    print('   📛 Name: ${json['name']}');
    print('   📧 Email: ${json['email']}');
    print('   🎯 Role: ${json['role']}');
    print('   📝 Bio: ${json['bio']}');
    print('   🚻 Gender: ${json['gender']}');
    print('   🏷️ Interests: ${json['interests']}');
    print('   📸 Photo: ${json['photo']}');
    print('   🖼️ Main Photo: ${json['mainPhoto']}');
    print('   🎂 Age: ${json['age']}');
    print('   🏫 School: ${json['school']}');
    print('   📏 Height: ${json['height']}');
    print('   💼 Job Title: ${json['jobTitle']}');
    print('   🏠 Living In: ${json['livingIn']}');
    print('   🎵 Top Artist: ${json['topArtist']}');
    print('   🏢 Company: ${json['company']}');

    // Parse age safely
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

    // Parse height safely
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

    // Parse interests safely
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

    return User(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      token: '', // Not needed for match users
      bio: json['bio']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      interests: parsedInterests,
      photo: (json['mainPhoto']?.toString() ?? json['photo']?.toString()) ?? '',
      age: parsedAge,
      media: [], // Not needed for chat
      school: json['school']?.toString() ?? '',
      height: parsedHeight,
      jobTitle: json['jobTitle']?.toString() ?? '',
      livingIn: json['livingIn']?.toString() ?? '',
      topArtist: json['topArtist']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
    );
  }
}

// NEW: UserMedia model
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
