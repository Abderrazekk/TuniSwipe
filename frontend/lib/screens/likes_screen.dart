import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/like.dart';
import 'conversations_screen.dart';
import '../providers/chat_provider.dart';
import '../widgets/profile_detail_modal.dart'; // Import the modern profile modal
import '../constants/app_colors.dart'; // Import AppColors

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  List<Like> _likes = [];
  List<Like> _matches = [];
  bool _isLoading = true;
  int _currentTab = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLikesAndMatches();
  }

  // Keep all your existing API functions exactly as they are
  Future<void> _fetchLikesAndMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      print('🔄 Fetching likes and matches...');

      // Fetch likes
      final likesResponse = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/auth/matches/likes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (likesResponse.statusCode != 200) {
        throw Exception('Failed to load likes: ${likesResponse.statusCode}');
      }

      final likesData = json.decode(likesResponse.body);

      if (likesData['success'] == true) {
        final likesList = likesData['data']['likes'] as List? ?? [];
        final parsedLikes = <Like>[];

        for (var likeData in likesList) {
          try {
            parsedLikes.add(Like.fromJson(likeData));
          } catch (e) {
            print('❌ Skipping invalid like data: $e');
          }
        }

        setState(() {
          _likes = parsedLikes;
        });
        print('✅ Loaded ${_likes.length} non-mutual likes');
      } else {
        throw Exception(likesData['message'] ?? 'Failed to load likes');
      }

      // Fetch matches
      final matchesResponse = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/auth/matches/matches'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (matchesResponse.statusCode != 200) {
        throw Exception(
          'Failed to load matches: ${matchesResponse.statusCode}',
        );
      }

      final matchesData = json.decode(matchesResponse.body);

      if (matchesData['success'] == true) {
        final matchesList = matchesData['data']['matches'] as List? ?? [];
        final parsedMatches = <Like>[];

        for (var matchData in matchesList) {
          try {
            parsedMatches.add(Like.fromJson(matchData));
          } catch (e) {
            print('❌ Skipping invalid match data: $e');
          }
        }

        setState(() {
          _matches = parsedMatches;
        });
        print('✅ Loaded ${_matches.length} mutual matches');
      } else {
        throw Exception(matchesData['message'] ?? 'Failed to load matches');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      print('❌ Error loading likes and matches: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _showUserProfile(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailModal(
        user: user,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  ImageProvider _getProfileImage(User user) {
    if (user.photo.isNotEmpty) {
      try {
        return NetworkImage('http://10.0.2.2:5000/uploads/${user.photo}');
      } catch (e) {
        print('❌ Error loading network image: $e');
      }
    }

    // Fallback to default avatar
    return const AssetImage('assets/default_avatar.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _errorMessage != null
          ? _buildErrorState()
          : _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                const SizedBox(height: 35),
                // Modern Tab Bar
                _buildModernTabBar(),

                // Content
                Expanded(
                  child: _currentTab == 0
                      ? _buildLikesTab()
                      : _buildMatchesTab(),
                ),
              ],
            ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModernTabButton(
              'Likes',
              0,
              _likes.length,
              Icons.favorite_border_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildModernTabButton(
              'Matches',
              1,
              _matches.length,
              Icons.people_alt_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabButton(
    String title,
    int tabIndex,
    int count,
    IconData icon,
  ) {
    final isSelected = _currentTab == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tabIndex;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Connections',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding people who like you...',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesTab() {
    if (_likes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline_rounded,
        title: 'No Likes Yet',
        message: "When someone likes you,\nthey'll appear here.",
        gradientColors: [Color(0xFFFEE2E2), Color(0xFFFECACA)],
      );
    }

    return RefreshIndicator(
      backgroundColor: AppColors.background,
      color: AppColors.primary,
      onRefresh: _fetchLikesAndMatches,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _likes.length,
        itemBuilder: (context, index) {
          final like = _likes[index];
          return _buildModernLikeCard(like, false);
        },
      ),
    );
  }

  Widget _buildMatchesTab() {
    if (_matches.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Matches Yet',
        message: "When you and someone\nlike each other, it's a match!",
        gradientColors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
      );
    }

    return RefreshIndicator(
      backgroundColor: AppColors.background,
      color: AppColors.primary,
      onRefresh: _fetchLikesAndMatches,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          return _buildModernLikeCard(match, true);
        },
      ),
    );
  }

  Widget _buildModernLikeCard(Like like, bool isMatch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showUserProfile(like.user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image with Badge
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        image: DecorationImage(
                          image: _getProfileImage(like.user),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (isMatch)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            like.user.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${like.user.age}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Job and Location
                      if (like.user.jobTitle.isNotEmpty ||
                          like.user.livingIn.isNotEmpty)
                        Row(
                          children: [
                            if (like.user.jobTitle.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.work_outline_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    like.user.jobTitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            if (like.user.jobTitle.isNotEmpty &&
                                like.user.livingIn.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.textSecondary.withOpacity(
                                      0.5,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (like.user.livingIn.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    like.user.livingIn,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                          ],
                        ),

                      const SizedBox(height: 6),

                      // Time ago
                      Text(
                        _timeAgo(like.likedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Button
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isMatch
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isMatch
                          ? Icons.chat_bubble_outline_rounded
                          : Icons.favorite_outline_rounded,
                      color: isMatch ? AppColors.primary : AppColors.accent,
                      size: 24,
                    ),
                    onPressed: isMatch
                        ? () {
                            print('💬 Start chat with ${like.user.name}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ConversationsScreen(),
                              ),
                            );
                          }
                        : () {
                            _likeBack(like);
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Keep all your existing _likeBack function exactly as it is
  Future<void> _likeBack(Like like) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      print('❤️ Liking back ${like.user.name}');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/matches/swipe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'targetUserId': like.user.id, 'action': 'like'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to like back: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        final isMatch = responseData['data']['isMatch'] == true;

        if (isMatch) {
          // Force refresh the chat conversations to include the new match
          await chatProvider.getConversations();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 It\'s a match with ${like.user.name}!'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          setState(() {
            _likes.removeWhere((l) => l.user.id == like.user.id);
            _matches.insert(0, Like(user: like.user, likedAt: DateTime.now()));
            _currentTab = 1;
          });

          print('✅ User ${like.user.name} moved from likes to matches');

          // Show option to start chatting
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMatchSuccessDialog(like.user);
          });
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to like back');
      }
    } catch (error) {
      print('❌ Error liking back: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to like back: ${error.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showMatchSuccessDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'It\'s a Match! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You and ${user.name} have liked each other!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: AppColors.background,
                        ),
                        child: Text(
                          'Later',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Chat Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Issue',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load connections',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchLikesAndMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required List<Color> gradientColors,
  }) {
    return RefreshIndicator(
      backgroundColor: AppColors.background,
      color: AppColors.primary,
      onRefresh: _fetchLikesAndMatches,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 50, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _fetchLikesAndMatches,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: AppColors.primary),
                    ),
                    child: Text(
                      'Refresh',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
