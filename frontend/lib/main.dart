import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_step1_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/likes_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile.dart';
import 'models/user.dart';
import 'services/location_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpStep1Screen(),
          '/home': (context) => const HomeScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/likes': (context) => const LikesScreen(),
          '/chat': (context) => const ChatScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit_profile': (context) => const EditProfileScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChatInitialized = false;
  bool _isLocationInitialized = false;
  final LocationService _locationService = LocationService();
  bool _isRequestingPermission = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    if (authProvider.isLoading || !authProvider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isAuthenticated) {
      final user = authProvider.user;

      if (user?.role == 'admin') {
        return const DashboardScreen();
      }

      // Initialize chat when user is authenticated
      if (user != null && !_isChatInitialized) {
        _initializeChat(chatProvider, user);
        _isChatInitialized = true;
      }

      // Initialize location when user is authenticated
      if (user != null && !_isLocationInitialized && !_isRequestingPermission) {
        _initializeLocation(authProvider, user);
      }

      return const HomeScreen();
    }

    // Reset initializations when user signs out
    if (_isChatInitialized || _isLocationInitialized) {
      _isChatInitialized = false;
      _isLocationInitialized = false;
      chatProvider.disposeSocket();
    }

    return const SignInScreen();
  }

  Future<void> _initializeLocation(AuthProvider authProvider, User user) async {
    if (_isRequestingPermission) return;
    
    _isRequestingPermission = true;
    
    print('📍 Initializing location system...');
    
    try {
      // Check location permission status
      var status = await Permission.location.status;
      
      if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
        print('📍 Requesting location permission...');
        
        // Show explanation dialog first
        bool? shouldRequest = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission'),
            content: const Text(
              'This app needs access to your location to show you nearby people. '
              'Your location will only be used to find matches within your selected radius.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Allow'),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          status = await Permission.location.request();
          
          if (!status.isGranted && !status.isLimited) {
            print('❌ Location permission denied');
            _isRequestingPermission = false;
            return;
          }
        } else {
          _isRequestingPermission = false;
          return;
        }
      }

      if (status.isGranted || status.isLimited) {
        print('✅ Location permission granted');
        
        // Get current location
        final location = await _locationService.getCurrentLocation();
        
        if (location != null) {
          // Send location to backend
          final success = await _locationService.sendLocationToBackend(
            token: user.token,
            latitude: location.latitude!,
            longitude: location.longitude!,
            accuracy: location.accuracy,
            provider: 'gps',
            forceUpdate: false,
          );
          
          if (success) {
            print('✅ Location system initialized successfully');
            _isLocationInitialized = true;
          } else {
            print('❌ Failed to send location to backend');
          }
        } else {
          print('❌ Could not get current location');
        }
      }
    } catch (error) {
      print('❌ Error initializing location: $error');
    } finally {
      _isRequestingPermission = false;
    }
  }

  void _initializeChat(ChatProvider chatProvider, User user) {
    print('🚀 Initializing chat system...');
    chatProvider.setCurrentUser(user);
    chatProvider.setAuthToken(user.token);
    chatProvider.initializeSocket();
    print('✅ Chat system initialization completed');
  }
}