import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    // Wait for both loading to complete AND initialization to complete
    if (authProvider.isLoading || !authProvider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      print('🎯 User Role: ${user?.role}');
      print('🔐 User Token: ${user?.token}');

      // Initialize chat socket when user is authenticated (only once)
      if (user != null && !_isChatInitialized) {
        _initializeChat(chatProvider, user);
        _isChatInitialized = true;
      }

      if (user?.role == 'admin') {
        return const DashboardScreen();
      } else {
        return const HomeScreen();
      }
    }

    // Reset chat initialization when user signs out
    if (_isChatInitialized) {
      _isChatInitialized = false;
      chatProvider.disposeSocket();
    }

    return const SignInScreen();
  }

  void _initializeChat(ChatProvider chatProvider, User user) {
    print('🚀 Initializing chat system...');

    // Set user and token first
    chatProvider.setCurrentUser(user);
    chatProvider.setAuthToken(user.token);

    // Then initialize socket
    chatProvider.initializeSocket();

    print('✅ Chat system initialization completed');
  }
}
