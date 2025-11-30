import 'user.dart';

class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User sender;
  final User receiver;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    required this.sender,
    required this.receiver,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['sender'] is String ? json['sender'] : json['sender']['_id'] ?? '',
      receiverId: json['receiver'] is String ? json['receiver'] : json['receiver']['_id'] ?? '',
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? 'text',
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      sender: User.fromJson(json['sender'] is String ? {} : json['sender']),
      receiver: User.fromJson(json['receiver'] is String ? {} : json['receiver']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'sender': senderId,
      'receiver': receiverId,
      'message': message,
      'messageType': messageType,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? receiverId,
    String? message,
    String? messageType,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? sender,
    User? receiver,
  }) {
    return Message(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
    );
  }
}