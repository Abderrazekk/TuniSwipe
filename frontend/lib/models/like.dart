// models/like.dart
import 'user.dart';

// models/like.dart - Add comprehensive null safety
class Like {
  final User user;
  final DateTime likedAt;
  final String? swipeId;

  Like({required this.user, required this.likedAt, this.swipeId});

  factory Like.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse the likedAt date
      DateTime parsedDate;
      if (json['likedAt'] != null) {
        if (json['likedAt'] is String) {
          parsedDate = DateTime.parse(json['likedAt']);
        } else if (json['likedAt'] is int) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(json['likedAt']);
        } else {
          parsedDate = DateTime.now();
          print('⚠️ Unknown date format: ${json['likedAt']}');
        }
      } else {
        parsedDate = DateTime.now();
        print('⚠️ likedAt is null, using current time');
      }

      return Like(
        user: User.fromMatchJson(json['user'] ?? {}),
        likedAt: parsedDate,
        swipeId: json['swipeId']?.toString(),
      );
    } catch (e) {
      print('❌ Error parsing Like: $e');
      print('❌ Problematic JSON: $json');
      rethrow;
    }
  }
}
