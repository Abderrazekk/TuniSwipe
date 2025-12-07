import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/bottom_nav_bar.dart';
import 'likes_screen.dart';
import 'conversations_screen.dart';
import 'profile_screen.dart';
import '../services/location_service.dart';
import '../widgets/location_settings_dialog.dart';
import '../widgets/profile_detail_modal.dart';
import '../widgets/age_filter_dialog.dart';
import '../widgets/home/home_app_bar.dart';
import '../widgets/home/swipe_screen.dart';
import '../widgets/home/match_dialog.dart';

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
    const ConversationsScreen(),
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
      builder: (context) => MatchDialog(
        user: user,
        matchMessage: matchMessage,
        onKeepSwiping: () => Navigator.of(context).pop(),
        onSendMessage: () {
          Navigator.of(context).pop();
          setState(() {
            _currentIndex = 2;
          });
        },
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

  Future<void> _updateAgeFilter(bool enabled, int minAge, int maxAge) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.updateAgeFilter(
        ageFilterEnabled: enabled,
        minAgeFilter: minAge,
        maxAgeFilter: maxAge,
      );

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
  return Scaffold(
    extendBody: true, // This is key! Allows body to extend behind navigation bar
    appBar: _currentIndex == 0
        ? HomeAppBar(
            currentRadius: _currentRadius,
            locationEnabled: _locationEnabled,
            onAgeFilterPressed: _showAgeFilterDialog,
            onLocationSettingsPressed: _showLocationSettings,
          )
        : null,
    body: Container(
      // Add a container to ensure content doesn't go behind navbar
      margin: EdgeInsets.only(bottom: 70), // Reserve space for nav bar
      child: _currentIndex == 0
          ? SwipeScreen(
              potentialMatches: _potentialMatches,
              isLoading: _isLoading,
              currentCardIndex: _currentCardIndex,
              locationEnabled: _locationEnabled,
              showNavigationGuide: _showNavigationGuide,
              onSwipeLeft: _handleSwipeLeft,
              onSwipeRight: _handleSwipeRight,
              onRefreshLocation: _refreshLocationAndMatches,
              onAgeFilterPressed: _showAgeFilterDialog,
              onProfileDetailPressed: () {
                if (_potentialMatches.isNotEmpty &&
                    _currentCardIndex < _potentialMatches.length) {
                  _showProfileDetail(_potentialMatches[_currentCardIndex]);
                }
              },
              onLoadMore: _loadPotentialMatches,
              onResetAndReload: () {
                setState(() {
                  _currentCardIndex = 0;
                  _swipedUserIds.clear();
                });
                _loadPotentialMatches();
              },
            )
          : _screens[_currentIndex],
    ),
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