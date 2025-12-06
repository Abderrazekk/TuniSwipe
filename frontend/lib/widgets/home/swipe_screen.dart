import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/swipe_card.dart';
import 'action_button.dart';
import 'empty_state_widget.dart';

class SwipeScreen extends StatelessWidget {
  final List<User> potentialMatches;
  final bool isLoading;
  final int currentCardIndex;
  final bool locationEnabled;
  final bool showNavigationGuide;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onRefreshLocation;
  final VoidCallback onAgeFilterPressed;
  final VoidCallback onProfileDetailPressed;
  final VoidCallback onLoadMore;
  final VoidCallback onResetAndReload;

  const SwipeScreen({
    super.key,
    required this.potentialMatches,
    required this.isLoading,
    required this.currentCardIndex,
    required this.locationEnabled,
    required this.showNavigationGuide,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onRefreshLocation,
    required this.onAgeFilterPressed,
    required this.onProfileDetailPressed,
    required this.onLoadMore,
    required this.onResetAndReload,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (isLoading && potentialMatches.isEmpty) {
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

    if (potentialMatches.isEmpty || currentCardIndex >= potentialMatches.length) {
      return EmptyStateWidget(
        onResetAndReload: onResetAndReload,
        onLoadMore: onLoadMore,
        onAgeFilterPressed: onAgeFilterPressed,
      );
    }

    final currentUser = potentialMatches[currentCardIndex];

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
            onSwipeLeft: onSwipeLeft,
            onSwipeRight: onSwipeRight,
            onProfileTap: onProfileDetailPressed,
            showDistance: true,
            isSmallCard: true,
          ),
        ),

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

        if (!locationEnabled)
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

        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionButton(
                icon: Icons.close,
                color: Colors.red,
                onPressed: onSwipeLeft,
                tooltip: 'Dislike',
              ),
              ActionButton(
                icon: Icons.filter_alt,
                color: Colors.purple,
                onPressed: onAgeFilterPressed,
                tooltip: 'Age Filter',
              ),
              ActionButton(
                icon: Icons.refresh,
                color: Colors.blue,
                onPressed: onRefreshLocation,
                tooltip: 'Refresh',
              ),
              ActionButton(
                icon: Icons.info_outline,
                color: Colors.orange,
                onPressed: onProfileDetailPressed,
                tooltip: 'Profile',
              ),
              ActionButton(
                icon: Icons.favorite,
                color: Colors.green,
                onPressed: onSwipeRight,
                tooltip: 'Like',
              ),
            ],
          ),
        ),

        if (showNavigationGuide)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: showNavigationGuide ? 1.0 : 0.0,
            ),
          ),
      ],
    );
  }
}