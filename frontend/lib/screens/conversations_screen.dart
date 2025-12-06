import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user.dart';
import 'chat_room_screen.dart';
import '../constants/app_colors.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isSearching = false;

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

    if (authProvider.user != null) {
      chatProvider.setCurrentUser(authProvider.user!);
      chatProvider.setAuthToken(authProvider.user!.token);
    }

    if (!chatProvider.isConnected && !chatProvider.isSocketReady()) {
      chatProvider.initializeSocket();
    }

    _loadConversations(chatProvider);
    _isInitialized = true;
  }

  void _loadConversations(ChatProvider chatProvider) {
    chatProvider.getConversations().catchError((error) {
      print('❌ Error loading conversations: $error');
    });
  }

  void _filterConversations(String query, List<Map<String, dynamic>> conversations) {
    if (query.isEmpty) {
      setState(() {
        _filteredConversations = conversations;
        _isSearching = false;
      });
      return;
    }

    final filtered = conversations.where((conversation) {
      final otherUser = conversation['otherUser'];
      final name = otherUser['name'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredConversations = filtered;
      _isSearching = true;
    });
  }

  String _formatLastMessageTime(DateTime messageDate) {
    final now = DateTime.now();
    final difference = now.difference(messageDate);

    if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  Widget _buildSearchBar(ChatProvider chatProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _filterConversations('', chatProvider.conversations.cast<Map<String, dynamic>>());
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          _filterConversations(value, chatProvider.conversations.cast<Map<String, dynamic>>());
        },
      ),
    );
  }

  Widget _buildConversationsList(ChatProvider chatProvider) {
    final conversations = _isSearching ? _filteredConversations : chatProvider.conversations;

    if (conversations.isEmpty && _isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations found',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different name',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (conversations.isEmpty) {
      return _buildEmptyConversationsState();
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: conversations.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: AppColors.border.withOpacity(0.3),
        indent: 80,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final otherUser = conversation['otherUser'];
        final lastMessage = conversation['lastMessage'];
        final unreadCount = conversation['unreadCount'] ?? 0;
        final isMatchWithoutMessages = conversation['isMatchWithoutMessages'] ?? false;

        String lastMessageText = 'Say hello! 👋';
        String lastMessageTime = 'New match';

        if (lastMessage != null) {
          lastMessageText = lastMessage['message'] ?? 'Say hello! 👋';
          final messageDate = DateTime.parse(lastMessage['createdAt']);
          lastMessageTime = _formatLastMessageTime(messageDate);
        } else if (isMatchWithoutMessages) {
          lastMessageText = 'Start the conversation!';
        }

        return _buildConversationItem(
          otherUser: otherUser,
          lastMessageText: lastMessageText,
          lastMessageTime: lastMessageTime,
          unreadCount: unreadCount,
          isMatchWithoutMessages: isMatchWithoutMessages,
        );
      },
    );
  }

  Widget _buildConversationItem({
    required Map<String, dynamic> otherUser,
    required String lastMessageText,
    required String lastMessageTime,
    required int unreadCount,
    required bool isMatchWithoutMessages,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isMatchWithoutMessages
                    ? AppColors.accent
                    : AppColors.border.withOpacity(0.3),
                width: isMatchWithoutMessages ? 2 : 1,
              ),
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.surface,
              backgroundImage: NetworkImage(
                'http://10.0.2.2:5000/uploads/${otherUser['mainPhoto'] ?? otherUser['photo']}',
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUser['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            lastMessageTime,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lastMessageText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  color: unreadCount > 0
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isMatchWithoutMessages && unreadCount == 0)
              Icon(
                Icons.favorite,
                size: 16,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              otherUser: User.fromJson(otherUser),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyConversationsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'When you match with someone, they will appear here automatically.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/likes');
              },
              child: Text(
                'View Your Matches',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    if (!_isInitialized && chatProvider.conversations.isNotEmpty) {
      _filteredConversations = List.from(chatProvider.conversations);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
      children: [
        const SizedBox(height: 35),
        _buildSearchBar(chatProvider),
        Expanded(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
          await chatProvider.getConversations();
          if (_searchController.text.isNotEmpty) {
            _filterConversations(
            _searchController.text,
            chatProvider.conversations.cast<Map<String, dynamic>>(),
            );
          }
          },
          child: _buildConversationsList(chatProvider),
        ),
        ),
      ],
      ),
    );
  }
}