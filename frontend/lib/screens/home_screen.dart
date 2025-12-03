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
import '../widgets/profile_detail_modal.dart';
import '../widgets/age_filter_dialog.dart';

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
  bool _showNavigationGuide = true;

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
    _hideNavigationGuide();
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

  void _hideNavigationGuide() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showNavigationGuide = false;
        });
      }
    });
  }

  void _showProfileDetail(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProfileDetailModal(
          user: user,
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // NEW: Show age filter dialog
  void _showAgeFilterDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    showDialog(
      context: context,
      builder: (context) => AgeFilterDialog(
        currentAgeFilterEnabled: user?.ageFilterEnabled ?? false,
        currentMinAge: user?.minAgeFilter ?? 18,
        currentMaxAge: user?.maxAgeFilter ?? 100,
        onAgeFilterChanged: (enabled, minAge, maxAge) {
          _updateAgeFilter(enabled, minAge, maxAge);
        },
      ),
    );
  }

  // NEW: Update age filter
  Future<void> _updateAgeFilter(bool enabled, int minAge, int maxAge) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.updateAgeFilter(
        ageFilterEnabled: enabled,
        minAgeFilter: minAge,
        maxAgeFilter: maxAge,
      );

      // Reload matches with new age filter
      _loadPotentialMatches();
    } catch (error) {
      print('❌ Error updating age filter: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update age filter: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('$_currentRadius KM', style: TextStyle(fontSize: 16)),
                  if (user?.ageFilterEnabled ?? false)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${user!.minAgeFilter}-${user.maxAgeFilter}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.pink[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (!_locationEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.location_off,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.cake, color: Colors.pink),
                  onPressed: _showAgeFilterDialog,
                ),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

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
            onProfileTap: () => _showProfileDetail(currentUser),
            showDistance: true,
            isSmallCard: true,
          ),
        ),

        // Age filter indicator (if enabled)
        if (user?.ageFilterEnabled ?? false)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: EdgeInsets.symmetric(horizontal: 60),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cake, color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Age filter: ${user!.minAgeFilter}-${user.maxAgeFilter}',
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

        // Location disabled indicator
        if (!_locationEnabled)
          Positioned(
            top: (user?.ageFilterEnabled ?? false) ? 40 : 10,
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
                  Icon(Icons.location_off, color: Colors.white, size: 14),
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

        // Bottom action buttons
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                Icons.close,
                Colors.red,
                _handleSwipeLeft,
                'Dislike',
              ),
              _buildActionButton(
                Icons.filter_alt,
                Colors.purple,
                _showAgeFilterDialog,
                'Age Filter',
              ),
              _buildActionButton(
                Icons.refresh,
                Colors.blue,
                _refreshLocationAndMatches,
                'Refresh',
              ),
              _buildActionButton(
                Icons.info_outline,
                Colors.orange,
                () => _showProfileDetail(currentUser),
                'Profile',
              ),
              _buildActionButton(
                Icons.favorite,
                Colors.green,
                _handleSwipeRight,
                'Like',
              ),
            ],
          ),
        ),

        // Navigation guide (hidden after 5 seconds)
        if (_showNavigationGuide)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: _showNavigationGuide ? 1.0 : 0.0,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showAgeFilterDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Adjust Age Filter'),
              ),
            ],
          ),
        ),
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

class ProfileDetailScreen extends StatefulWidget {
  final User user;

  const ProfileDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late PageController _imageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.user.allImageUrls;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Share profile
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _imageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),

                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${imageUrls.length}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  if (imageUrls.length > 1)
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            if (_currentImageIndex > 0) {
                              _imageController.previousPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),

                  if (imageUrls.length > 1)
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            if (_currentImageIndex < imageUrls.length - 1) {
                              _imageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.user.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${widget.user.age}',
                          style: TextStyle(fontSize: 28, color: Colors.black54),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3,
                      children: [
                        if (widget.user.jobTitle.isNotEmpty)
                          _buildDetailItem(
                            Icons.work,
                            'Job',
                            widget.user.jobTitle,
                          ),
                        if (widget.user.school.isNotEmpty)
                          _buildDetailItem(
                            Icons.school,
                            'School',
                            widget.user.school,
                          ),
                        if (widget.user.livingIn.isNotEmpty)
                          _buildDetailItem(
                            Icons.location_on,
                            'Location',
                            widget.user.livingIn,
                          ),
                        if (widget.user.company.isNotEmpty)
                          _buildDetailItem(
                            Icons.business,
                            'Company',
                            widget.user.company,
                          ),
                        if (widget.user.height != null)
                          _buildDetailItem(
                            Icons.height,
                            'Height',
                            '${widget.user.height} cm',
                          ),
                        if (widget.user.topArtist.isNotEmpty)
                          _buildDetailItem(
                            Icons.music_note,
                            'Top Artist',
                            widget.user.topArtist,
                          ),
                      ],
                    ),

                    SizedBox(height: 20),

                    if (widget.user.bio.isNotEmpty) ...[
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.user.bio,
                        style: TextStyle(fontSize: 16, height: 1.4),
                      ),
                      SizedBox(height: 20),
                    ],

                    if (widget.user.interests.isNotEmpty) ...[
                      Text(
                        'Interests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.user.interests.map((interest) {
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
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
