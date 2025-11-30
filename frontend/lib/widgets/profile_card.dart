// widgets/profile_card.dart
import 'package:flutter/material.dart';
import '../models/user.dart';

class ProfileCard extends StatefulWidget {
  final User user;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onTap;

  const ProfileCard({
    Key? key,
    required this.user,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  double _dragPosition = 0;
  bool _isDragging = false;
  double _rotation = 0;
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: (_) {
        setState(() {
          _isDragging = true;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _dragPosition = details.delta.dx;
          _rotation = _dragPosition * 0.02; // More noticeable rotation
        });
      },
      onPanEnd: (details) {
        final double swipeThreshold = 100; // Minimum swipe distance
        
        if (_dragPosition.abs() > swipeThreshold) {
          // Swipe detected - animate card out
          setState(() {
            _opacity = 0.0;
          });
          
          // Wait for animation to complete then trigger action
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_dragPosition > 0) {
              // Swiped right - Like
              widget.onSwipeRight();
            } else {
              // Swiped left - Reject
              widget.onSwipeLeft();
            }
          });
        } else {
          // Reset if swipe wasn't far enough
          _resetCard();
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _opacity,
        child: Transform.translate(
          offset: Offset(_dragPosition, 0),
          child: Transform.rotate(
            angle: _rotation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _buildCardContent(),
            ),
          ),
        ),
      ),
    );
  }

  void _resetCard() {
    setState(() {
      _dragPosition = 0;
      _rotation = 0;
      _isDragging = false;
      _opacity = 1.0;
    });
  }

  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profile Image
        Expanded(
          flex: 7,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  image: DecorationImage(
                    image: _getProfileImage(widget.user),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              
              // Swipe indicators
              if (_isDragging) ...[
                // NOPE indicator (left)
                Positioned(
                  left: 20,
                  top: 40,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _dragPosition < -50 ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Text(
                        'NOPE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // LIKE indicator (right)
                Positioned(
                  right: 20,
                  top: 40,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _dragPosition > 50 ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Text(
                        'LIKE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              // Basic info overlay
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.user.age}',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (widget.user.jobTitle.isNotEmpty || widget.user.livingIn.isNotEmpty)
                      Row(
                        children: [
                          if (widget.user.jobTitle.isNotEmpty) ...[
                            Icon(Icons.work, size: 16, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(width: 4),
                            Text(
                              widget.user.jobTitle,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                          if (widget.user.livingIn.isNotEmpty && widget.user.jobTitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (widget.user.livingIn.isNotEmpty) ...[
                            Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(width: 4),
                            Text(
                              widget.user.livingIn,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Profile Info
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bio
                if (widget.user.bio.isNotEmpty)
                  Expanded(
                    child: Text(
                      widget.user.bio,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Interests
                if (widget.user.interests.isNotEmpty)
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.user.interests.length,
                      itemBuilder: (context, index) {
                        final interest = widget.user.interests[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.pink[100]!),
                          ),
                          child: Text(
                            interest,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.pink[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider _getProfileImage(User user) {
    if (user.photo.isNotEmpty) {
      try {
        return NetworkImage(
          'http://10.0.2.2:5000/uploads/${user.photo}',
        );
      } catch (e) {
        print('❌ Error loading network image: $e');
      }
    }
    
    // Fallback to default avatar
    return const AssetImage('assets/default_avatar.png');
  }
}