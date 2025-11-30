import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/message.dart';

class ChatProvider with ChangeNotifier {
  IO.Socket? _socket;
  User? _currentUser;
  List<Message> _messages = [];
  List<dynamic> _conversations = [];
  bool _isConnected = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _authToken;

  // Getters
  IO.Socket? get socket => _socket;
  List<Message> get messages => _messages;
  List<dynamic> get conversations => _conversations;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Set auth token (call this after user login/signup)
  void setAuthToken(String token) {
    _authToken = token;
    print('🔐 Auth token set in ChatProvider: ${token.substring(0, 20)}...');
  }

  // Set current user
  void setCurrentUser(User user) {
    _currentUser = user;
    print('👤 Current user set in ChatProvider: ${user.email}');
  }

  // Initialize socket connection
  void initializeSocket() {
    if (_authToken == null || _authToken!.isEmpty) {
      print('❌ Cannot initialize socket: No auth token available');
      _errorMessage = 'Authentication required';
      notifyListeners();
      return;
    }

    if (_currentUser == null) {
      print('❌ Cannot initialize socket: No current user');
      _errorMessage = 'User data required';
      notifyListeners();
      return;
    }

    try {
      print('🚀 Initializing socket connection...');
      
      _socket = IO.io(
        'http://10.0.2.2:5000',
        IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setAuth({'token': _authToken})
          .setQuery({'token': _authToken})
          .build(),
      );

      _setupSocketListeners();
      
      // Manually connect after setting up listeners
      _socket!.connect();
      
    } catch (error) {
      print('💥 Socket initialization error: $error');
      _errorMessage = 'Failed to initialize chat connection';
      notifyListeners();
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('✅ Socket connected successfully');
      _isConnected = true;
      _errorMessage = null;
      
      // Mark user as online
      _socket!.emit('user_online');
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
      _isConnected = false;
      notifyListeners();
    });

    _socket!.onConnectError((data) {
      print('💥 Socket connection error: $data');
      _errorMessage = 'Connection failed: $data';
      notifyListeners();
    });

    _socket!.onConnectTimeout((data) {
      print('⏰ Socket connection timeout: $data');
      _errorMessage = 'Connection timeout';
      notifyListeners();
    });

    _socket!.onError((error) {
      print('💥 Socket error: $error');
      _errorMessage = 'Connection error: $error';
      notifyListeners();
    });

    // Chat events
    _socket!.on('new_message', (data) {
      print('📨 New message received: ${data['success']}');
      if (data['success'] == true && data['data'] != null) {
        try {
          final message = Message.fromJson(data['data']);
          _addMessage(message);
          print('✅ Message added: ${message.message}');
        } catch (e) {
          print('❌ Error parsing message: $e');
        }
      }
    });

    _socket!.on('message_notification', (data) {
      print('🔔 Message notification received');
      // Handle notification
    });

    _socket!.on('user_typing', (data) {
      print('✍️ User typing: ${data['isTyping']}');
      // Handle typing indicator
    });

    _socket!.on('messages_read', (data) {
      print('📖 Messages read in room: ${data['roomId']}');
      _markMessagesAsRead(data['roomId']);
    });

    _socket!.on('user_status_changed', (data) {
      print('🟢 User status changed: ${data['userId']} - ${data['isOnline']}');
      // Update user status in UI
    });
  }

  // Join chat room
  void joinChatRoom(String otherUserId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_chat_room', otherUserId);
      print('🚪 Joined chat room with user: $otherUserId');
    } else {
      print('❌ Cannot join room: Socket not connected');
      _reconnectSocket();
    }
  }

  // Send message
  void sendMessage(String receiverId, String message) {
    if (_socket != null && _isConnected) {
      final messageData = {
        'receiverId': receiverId,
        'message': message.trim(),
        'messageType': 'text',
      };

      _socket!.emit('send_message', messageData);
      print('📤 Message sent to $receiverId: ${message.trim()}');
    } else {
      print('❌ Cannot send message: Socket not connected');
      _reconnectSocket();
    }
  }

  // Start typing indicator
  void startTyping(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing_start', {'roomId': roomId});
    }
  }

  // Stop typing indicator
  void stopTyping(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing_stop', {'roomId': roomId});
    }
  }

  // Mark messages as read
  void markMessagesAsRead(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('mark_messages_read', {'roomId': roomId});
    }
  }

  // Reconnect socket if disconnected
  void _reconnectSocket() {
    if (!_isConnected && _authToken != null) {
      print('🔄 Attempting to reconnect socket...');
      initializeSocket();
    }
  }

  // Add message to local list
  void _addMessage(Message message) {
    _messages.add(message);
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }

  // Mark messages as read locally
  void _markMessagesAsRead(String roomId) {
    bool updated = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].roomId == roomId && !_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        updated = true;
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  // Get chat history from API
  Future<void> getChatHistory(String otherUserId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final token = _authToken ?? _currentUser?.token;

      if (token == null) {
        throw Exception('No authentication token available');
      }

      print('📡 Fetching chat history for user: $otherUserId');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/auth/chat/history/$otherUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final messagesData = responseData['data']['messages'] as List;
        _messages = messagesData.map((msg) => Message.fromJson(msg)).toList();
        print('✅ Loaded ${_messages.length} messages for chat');
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load chat history');
      }
    } catch (error) {
      print('❌ Chat history error: $error');
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMatches() async {
  try {
    _isLoading = true;
    notifyListeners();

    final token = _authToken ?? _currentUser?.token;

    if (token == null) {
      throw Exception('No authentication token available');
    }

    print('🔄 Forcibly refreshing matches and conversations...');

    // First, get conversations (which now includes matches)
    await getConversations();
    
    print('✅ Matches and conversations refreshed');

  } catch (error) {
    print('❌ Error refreshing matches: $error');
    _errorMessage = error.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // Get conversations list
  Future<void> getConversations() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final token = _authToken ?? _currentUser?.token;

      if (token == null) {
        throw Exception('No authentication token available');
      }

      print('📡 Fetching conversations list...');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/auth/chat/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _conversations = responseData['data']['conversations'];
        print('✅ Loaded ${_conversations.length} conversations');
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load conversations');
      }
    } catch (error) {
      print('❌ Conversations error: $error');
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Check if socket is ready
  bool isSocketReady() {
    return _socket != null && _isConnected && _authToken != null;
  }

  // Dispose socket connection
  void disposeSocket() {
    print('🔌 Disposing socket connection...');
    _socket?.disconnect();
    _socket?.dispose();
    _isConnected = false;
    _socket = null;
  }
}