import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final User? otherUser;

  const ChatScreen({super.key, this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('🚀 Initializing chat screen...');

    // Ensure chat provider has the current user data
    if (authProvider.user != null) {
      chatProvider.setCurrentUser(authProvider.user!);
      chatProvider.setAuthToken(authProvider.user!.token);
    }

    // Initialize socket if not connected
    if (!chatProvider.isConnected && !chatProvider.isSocketReady()) {
      print('🔄 Socket not ready, initializing...');
      chatProvider.initializeSocket();
    }

    if (widget.otherUser != null) {
      // Load chat history and join room
      _loadChatHistory(chatProvider);
    } else {
      // Load conversations list
      _loadConversations(chatProvider);
    }

    _isInitialized = true;
  }

  void _loadChatHistory(ChatProvider chatProvider) {
    chatProvider
        .getChatHistory(widget.otherUser!.id)
        .then((_) {
          // Wait a bit for socket to be ready, then join room
          Future.delayed(const Duration(milliseconds: 500), () {
            if (chatProvider.isConnected) {
              chatProvider.joinChatRoom(widget.otherUser!.id);
              print('✅ Joined chat room with ${widget.otherUser!.name}');
            } else {
              print('❌ Socket not connected, cannot join room');
            }
          });
          _scrollToBottom();
        })
        .catchError((error) {
          print('❌ Error loading chat history: $error');
        });
  }

  void _loadConversations(ChatProvider chatProvider) {
    chatProvider.getConversations().catchError((error) {
      print('❌ Error loading conversations: $error');
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || widget.otherUser == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (chatProvider.isSocketReady()) {
      chatProvider.sendMessage(widget.otherUser!.id, message);
      _messageController.clear();
      _scrollToBottom();
    } else {
      print('❌ Socket not ready, cannot send message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection lost. Please wait...'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMessageBubble(Message message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isMe = message.senderId == authProvider.user!.id;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'http://10.0.2.2:5000/uploads/${message.sender.photo}',
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.sender.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'http://10.0.2.2:5000/uploads/${authProvider.user!.photo}',
              ),
            ),
          ],
        ],
      ),
    );
  }

Widget _buildConversationsList() {
  final chatProvider = Provider.of<ChatProvider>(context);

  return RefreshIndicator(
    onRefresh: () async {
      await chatProvider.getConversations();
    },
    child: chatProvider.conversations.isEmpty
        ? _buildEmptyConversationsState()
        : ListView.builder(
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              final otherUser = conversation['otherUser'];
              final lastMessage = conversation['lastMessage'];
              final unreadCount = conversation['unreadCount'] ?? 0;
              final isMatchWithoutMessages = conversation['isMatchWithoutMessages'] ?? false;

              String lastMessageText = 'No messages yet';
              String lastMessageTime = 'Just matched';
              
              if (lastMessage != null) {
                lastMessageText = lastMessage['message'] ?? 'No messages yet';
                final messageDate = DateTime.parse(lastMessage['createdAt']);
                lastMessageTime = _formatLastMessageTime(messageDate);
              } else if (isMatchWithoutMessages) {
                lastMessageText = 'Start the conversation!';
              }

              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(
                    'http://10.0.2.2:5000/uploads/${otherUser['mainPhoto'] ?? otherUser['photo']}',
                  ),
                ),
                title: Text(
                  otherUser['name'],
                  style: TextStyle(
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        color: lastMessage == null ? Colors.grey : null,
                        fontStyle: lastMessage == null ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    Text(
                      lastMessageTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : isMatchWithoutMessages
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.pink),
                            ),
                            child: Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.pink,
                            ),
                          )
                        : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUser: User.fromJson(otherUser),
                      ),
                    ),
                  );
                },
              );
            },
          ),
  );
}

Widget _buildEmptyConversationsState() {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: Container(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'No conversations yet',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
              const SizedBox(height: 15),
              Text(
                'When you match with someone, they will appear here automatically.',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                  chatProvider.getConversations();
                },
                child: const Text('Refresh'),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  // Navigate to likes screen to see matches
                  Navigator.pushNamed(context, '/likes');
                },
                child: const Text('View Your Matches'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  String _formatLastMessageTime(DateTime messageDate) {
    final now = DateTime.now();
    final difference = now.difference(messageDate);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildChatScreen() {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  'http://10.0.2.2:5000/uploads/${widget.otherUser!.photo}',
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.otherUser!.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!chatProvider.isConnected)
                Icon(Icons.signal_wifi_off, color: Colors.red, size: 20),
            ],
          ),
        ),

        // Messages List
        Expanded(
          child: chatProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : chatProvider.messages.isEmpty
              ? const Center(
                  child: Text('No messages yet. Start the conversation!'),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    // Handle typing indicators
                    final chatProvider = Provider.of<ChatProvider>(
                      context,
                      listen: false,
                    );
                    final roomId = _getRoomId(widget.otherUser!.id);

                    if (value.isNotEmpty && !_isTyping) {
                      _isTyping = true;
                      chatProvider.startTyping(roomId);
                    } else if (value.isEmpty && _isTyping) {
                      _isTyping = false;
                      chatProvider.stopTyping(roomId);
                    }
                  },
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRoomId(String otherUserId) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user!.id;
    final sortedIds = [currentUserId, otherUserId]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    // Show connection status
    if (!chatProvider.isConnected && _isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reconnecting to chat...'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: widget.otherUser != null
            ? Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundImage: NetworkImage(
                      'http://10.0.2.2:5000/uploads/${widget.otherUser!.photo}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(widget.otherUser!.name),
                  if (!chatProvider.isConnected) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.signal_wifi_off,
                      size: 16,
                      color: Colors.red,
                    ),
                  ],
                ],
              )
            : const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: widget.otherUser != null
          ? _buildChatScreen()
          : _buildConversationsList(),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
