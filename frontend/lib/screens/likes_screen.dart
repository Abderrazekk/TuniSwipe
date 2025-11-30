// screens/likes_screen.dart - Replace with safer implementation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/like.dart';
import 'chat_screen.dart';
import '../providers/chat_provider.dart';

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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchLikesAndMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProfileDetailSheet(user),
    );
  }

  Widget _buildProfileDetailSheet(User user) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header with image
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                image: DecorationImage(
                  image: _getProfileImage(user),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Profile details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Age
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${user.age}',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Basic info
                  if (user.jobTitle.isNotEmpty || user.livingIn.isNotEmpty)
                    Row(
                      children: [
                        if (user.jobTitle.isNotEmpty) ...[
                          Icon(Icons.work, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            user.jobTitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (user.livingIn.isNotEmpty &&
                            user.jobTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (user.livingIn.isNotEmpty) ...[
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.livingIn,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Bio
                  if (user.bio.isNotEmpty) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.bio,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Interests
                  if (user.interests.isNotEmpty) ...[
                    const Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: Colors.blue[50],
                          labelStyle: TextStyle(color: Colors.blue[700]),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
      appBar: AppBar(
        title: const Text('Likes & Matches'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLikesAndMatches,
          ),
        ],
      ),
      body: _errorMessage != null
          ? _buildErrorState()
          : _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Loading likes and matches...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton('Likes', 0, _likes.length),
                      ),
                      Expanded(
                        child: _buildTabButton('Matches', 1, _matches.length),
                      ),
                    ],
                  ),
                ),

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

  Widget _buildTabButton(String title, int tabIndex, int count) {
    final isSelected = _currentTab == tabIndex;
    return TextButton(
      onPressed: () {
        setState(() {
          _currentTab = tabIndex;
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Colors.pink : Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? Colors.pink : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesTab() {
    if (_likes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'No Likes Yet',
        message: "When someone likes you, they'll appear here.",
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLikesAndMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _likes.length,
        itemBuilder: (context, index) {
          final like = _likes[index];
          return _buildLikeCard(like, false);
        },
      ),
    );
  }

  Widget _buildMatchesTab() {
    if (_matches.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No Matches Yet',
        message: "When you and someone like each other, it's a match!",
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLikesAndMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          return _buildLikeCard(match, true);
        },
      ),
    );
  }

  Widget _buildLikeCard(Like like, bool isMatch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: _getProfileImage(like.user),
            ),
            if (isMatch)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(
              like.user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              '${like.user.age}',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            if (isMatch) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.pink),
                ),
                child: const Text(
                  'MATCH',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (like.user.jobTitle.isNotEmpty || like.user.livingIn.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    like.user.jobTitle,
                    like.user.livingIn,
                  ].where((text) => text.isNotEmpty).join(' • '),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _timeAgo(like.likedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
        trailing: isMatch
            ? IconButton(
                icon: const Icon(Icons.chat, color: Colors.pink),
                onPressed: () {
                  print('💬 Start chat with ${like.user.name}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(otherUser: like.user),
                    ),
                  );
                },
              )
            : IconButton(
                icon: const Icon(Icons.favorite, color: Colors.grey),
                onPressed: () {
                  _likeBack(like);
                },
              ),
        onTap: () => _showUserProfile(like.user),
      ),
    );
  }

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
            backgroundColor: Colors.pink,
            duration: const Duration(seconds: 3),
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
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showMatchSuccessDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('It\'s a Match! 🎉'),
          content: Text(
            'You and ${user.name} have liked each other! Start chatting now.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(otherUser: user),
                  ),
                );
              },
              child: const Text('Chat Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return RefreshIndicator(
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
                  Icon(icon, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
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
