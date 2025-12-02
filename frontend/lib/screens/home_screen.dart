// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/swipe_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'likes_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import '../services/location_service.dart';
import '../widgets/location_settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<User> _potentialMatches = [];
  bool _isLoading = true;
  List<String> _swipedUserIds = [];
  int _currentCardIndex = 0;
  int _currentRadius = 50;
  bool _locationEnabled = true;
  final LocationService _locationService = LocationService();

  final List<Widget> _screens = [
    const HomeTab(),
    const LikesScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadLocationSettings();
    _loadPotentialMatches();
  }

  Future<void> _loadLocationSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;
    
    if (token != null) {
      final settings = await _locationService.getLocationSettings(token);
      
      if (settings != null) {
        setState(() {
          _currentRadius = settings['locationRadius'] ?? 50;
          _locationEnabled = settings['locationEnabled'] ?? true;
        });
        print('📍 Loaded location settings: ${_currentRadius}KM');
      }
    }
  }

  Future<void> _loadPotentialMatches() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) {
        print('❌ No token available');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('🔄 Loading potential matches...');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/auth/matches/potential'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final newUsers = (responseData['data'] as List)
            .map((userData) => User.fromMatchJson(userData))
            .where((user) => !_swipedUserIds.contains(user.id))
            .toList();

        print('✅ Loaded ${newUsers.length} potential matches');

        setState(() {
          _potentialMatches = newUsers;
          _currentCardIndex = 0;
          _isLoading = false;
        });
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load matches');
      }
    } catch (error) {
      print('❌ Error loading matches: $error');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load profiles: $error');
    }
  }

  void _handleSwipeRight() {
    if (_potentialMatches.isEmpty ||
        _currentCardIndex >= _potentialMatches.length) {
      _checkAndLoadMoreProfiles();
      return;
    }

    final currentUser = _potentialMatches[_currentCardIndex];
    print('❤️ Swiped right - Like ${currentUser.name}');
    _processSwipe('like', currentUser);
  }

  void _handleSwipeLeft() {
    if (_potentialMatches.isEmpty ||
        _currentCardIndex >= _potentialMatches.length) {
      _checkAndLoadMoreProfiles();
      return;
    }

    final currentUser = _potentialMatches[_currentCardIndex];
    print('💔 Swiped left - Reject ${currentUser.name}');
    _processSwipe('dislike', currentUser);
  }

  void _processSwipe(String action, User user) {
    if (_potentialMatches.isEmpty) {
      _checkAndLoadMoreProfiles();
      return;
    }

    print('🔄 Processing $action for ${user.name}');

    _swipedUserIds.add(user.id);

    setState(() {
      _currentCardIndex++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == 'like'
              ? '❤️ Liked ${user.name}'
              : '💔 Passed on ${user.name}',
        ),
        backgroundColor: action == 'like' ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );

    _sendSwipeToServer(action, user);
    _checkCardAvailability();
  }

  void _checkCardAvailability() {
    if (_currentCardIndex >= _potentialMatches.length) {
      _loadPotentialMatches();
    }
  }

  void _checkAndLoadMoreProfiles() {
    final remainingCards = _potentialMatches.length - _currentCardIndex;
    if (remainingCards <= 1) {
      _loadPotentialMatches();
    }
  }

  Future<void> _sendSwipeToServer(String action, User user) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null) return;

      print('📡 Sending swipe: $action for ${user.name}');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/matches/swipe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'targetUserId': user.id, 'action': action}),
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        final isMatch = responseData['data']['isMatch'] == true;

        if (isMatch) {
          final matchMessage = responseData['data']['matchMessage'];
          final targetUser = responseData['data']['targetUser'];

          print('💑 MATCH FOUND with ${targetUser['name']}');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMatchDialog(user, matchMessage);
          });
        }
      }
    } catch (error) {
      print('❌ Error sending swipe: $error');
    }
  }

  void _showMatchDialog(User user, String matchMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "It's a Match! 🎉",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user.photo.isNotEmpty
                  ? NetworkImage('http://10.0.2.2:5000/uploads/${user.photo}')
                  : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
            ),
            const SizedBox(height: 16),
            Text(
              matchMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Swiping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentIndex = 2;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRadius(int newRadius) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;
    
    if (token != null) {
      final success = await _locationService.updateLocationRadius(
        token: token,
        radius: newRadius,
      );
      
      if (success) {
        setState(() {
          _currentRadius = newRadius;
        });
        
        _loadPotentialMatches();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search radius updated to $newRadius KM'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _toggleLocationEnabled(bool enabled) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;
    
    if (token != null) {
      final success = await _locationService.toggleLocationEnabled(
        token: token,
        enabled: enabled,
      );
      
      if (success) {
        setState(() {
          _locationEnabled = enabled;
        });
        
        _loadPotentialMatches();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location ${enabled ? 'enabled' : 'disabled'}'),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    }
  }

  void _showLocationSettings() {
    showDialog(
      context: context,
      builder: (context) => LocationSettingsDialog(
        currentRadius: _currentRadius,
        locationEnabled: _locationEnabled,
        onRadiusChanged: _updateRadius,
        onLocationToggled: _toggleLocationEnabled,
      ),
    );
  }

  Future<void> _refreshLocationAndMatches() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;
    
    if (token != null) {
      final location = await _locationService.getCurrentLocation();
      
      if (location != null) {
        await _locationService.sendLocationToBackend(
          token: token,
          latitude: location.latitude!,
          longitude: location.longitude!,
          accuracy: location.accuracy,
          forceUpdate: true,
        );
        
        _loadPotentialMatches();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated - Refreshing matches'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 
          ? AppBar(
              title: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '$_currentRadius KM',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (!_locationEnabled) 
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.location_off, color: Colors.grey, size: 16),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.blue),
                  onPressed: _showLocationSettings,
                ),
              ],
            )
          : null,
      body: _currentIndex == 0 ? _buildSwipeScreen() : _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildSwipeScreen() {
    if (_isLoading && _potentialMatches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading profiles...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_potentialMatches.isEmpty ||
        _currentCardIndex >= _potentialMatches.length) {
      return _buildEmptyState();
    }

    final currentUser = _potentialMatches[_currentCardIndex];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.pink[50]!, Colors.blue[50]!],
            ),
          ),
        ),

        Positioned(
          top: 50,
          left: 16,
          right: 16,
          bottom: 120,
          child: SwipeCard(
            key: ValueKey(currentUser.id),
            user: currentUser,
            onSwipeLeft: _handleSwipeLeft,
            onSwipeRight: _handleSwipeRight,
            onTap: () => _showProfileDetail(currentUser),
            showDistance: true,
            isSmallCard: true,
          ),
        ),

        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.close, Colors.red, _handleSwipeLeft),
              _buildActionButton(
                Icons.refresh,
                Colors.blue,
                _refreshLocationAndMatches,
              ),
              _buildActionButton(
                Icons.favorite,
                Colors.green,
                _handleSwipeRight,
              ),
            ],
          ),
        ),

        if (!_locationEnabled)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Location disabled - Showing all users',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.pink[100]!, Colors.blue[100]!],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 120, color: Colors.pink[300]),
              const SizedBox(height: 30),
              Text(
                "No More Profiles",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "You've seen all available profiles!\nCheck back later for new matches.",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentCardIndex = 0;
                        _swipedUserIds.clear();
                      });
                      _loadPotentialMatches();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Reset & Reload'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _loadPotentialMatches,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Load More'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDetail(User user) {
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
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                image: DecorationImage(
                  image: user.photo.isNotEmpty
                      ? NetworkImage(
                          'http://10.0.2.2:5000/uploads/${user.photo}',
                        )
                      : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            user.distance != null 
                                ? '${user.distance!.toStringAsFixed(1)} km away'
                                : 'Distance unknown',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _buildDetailGrid(user),
                  const SizedBox(height: 20),
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

  Widget _buildDetailGrid(User user) {
    final details = [
      if (user.distance != null)
        _buildDetailItem(Icons.location_on, 'Distance', '${user.distance!.toStringAsFixed(1)} km'),
      if (user.school.isNotEmpty)
        _buildDetailItem(Icons.school, 'School', user.school),
      if (user.jobTitle.isNotEmpty)
        _buildDetailItem(Icons.work, 'Job', user.jobTitle),
      if (user.livingIn.isNotEmpty)
        _buildDetailItem(Icons.location_city, 'Location', user.livingIn),
      if (user.company.isNotEmpty)
        _buildDetailItem(Icons.business, 'Company', user.company),
      if (user.height != null)
        _buildDetailItem(Icons.height, 'Height', '${user.height} cm'),
      if (user.topArtist.isNotEmpty)
        _buildDetailItem(Icons.music_note, 'Top Artist', user.topArtist),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: details.length,
      itemBuilder: (context, index) => details[index],
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome, ${user?.name ?? 'User'}!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Role: ${user?.role ?? 'Unknown'}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}