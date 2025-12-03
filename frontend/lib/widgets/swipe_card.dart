import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/location_service.dart';

class SwipeCard extends StatefulWidget {
  final User user;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onProfileTap;
  final bool showDistance;
  final bool isSmallCard;

  const SwipeCard({
    Key? key,
    required this.user,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onProfileTap,
    this.showDistance = true,
    this.isSmallCard = false,
  }) : super(key: key);

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late PageController _imageController;
  late AnimationController _animationController;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  
  int _currentImageIndex = 0;
  double _dragDistance = 0.0;
  bool _isSwiping = false;
  bool _showProfileButton = true;
  final double _swipeThreshold = 100.0;
  // ignore: unused_field
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    _initializeAnimations();
    _resetAnimations();
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _resetCard();
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _resetAnimations() {
    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _resetCard() {
    _imageController.jumpToPage(0);
    _animationController.reset();
    setState(() {
      _currentImageIndex = 0;
      _dragDistance = 0.0;
      _isSwiping = false;
    });
  }

  // 🖼️ Image Navigation with Tinder-like Gestures
  void _handleImagePanStart(DragStartDetails details) {
    setState(() {
      _isSwiping = false; // Not card swiping, image panning
    });
  }

  void _handleImagePanUpdate(DragUpdateDetails details) {
    // Allow horizontal drag for image navigation
    if (details.delta.dx.abs() > details.delta.dy.abs()) {
      // Horizontal drag - for next/previous image
      final newPage = _currentImageIndex - (details.delta.dx / 50);
      _imageController.jumpToPage(newPage.round());
    }
  }

  void _handleImagePanEnd(DragEndDetails details) {
    // Snap to nearest image
    if (_currentImageIndex < 0) _currentImageIndex = 0;
    if (_currentImageIndex >= widget.user.totalImages - 1) {
      _currentImageIndex = widget.user.totalImages - 1;
    }
  }

  // 🃏 Card Swiping (Tinder-style)
  void _handleCardPanStart(DragStartDetails details) {
    setState(() {
      _isSwiping = true;
      _showProfileButton = false;
    });
  }

  void _handleCardPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance += details.delta.dx;
    });
  }

  void _handleCardPanEnd(DragEndDetails details) {
    if (_dragDistance.abs() > _swipeThreshold) {
      if (_dragDistance > 0) {
        _swipeRight();
      } else {
        _swipeLeft();
      }
    } else {
      _resetCardPosition();
    }

    setState(() {
      _isSwiping = false;
      _showProfileButton = true;
    });
  }

  void _swipeRight() {
    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward().then((_) {
      widget.onSwipeRight();
    });
  }

  void _swipeLeft() {
    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: -0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward().then((_) {
      widget.onSwipeLeft();
    });
  }

  void _resetCardPosition() {
    _animationController.reverse();
    setState(() {
      _dragDistance = 0.0;
    });
  }

  void _nextImage() {
    if (_currentImageIndex < widget.user.totalImages - 1) {
      _imageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _imageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 📍 Location Service Helper Methods
  String _formatDistance(double? distance) {
    return LocationService.formatDistance(distance);
  }

  Widget _buildDistanceBadge() {
    if (!widget.showDistance || widget.user.distance == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDistance(widget.user.distance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    if (widget.user.distance == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          '${widget.user.distance?.toStringAsFixed(1)} km away',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _imageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handleCardPanStart,
      onPanUpdate: _handleCardPanUpdate,
      onPanEnd: _handleCardPanEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          double rotation = _rotationAnimation.value;
          Offset position = _positionAnimation.value;

          if (_isSwiping && _animationController.value == 0.0) {
            rotation = (_dragDistance * 0.001).clamp(-0.1, 0.1);
            position = Offset(
              _dragDistance / MediaQuery.of(context).size.width,
              0.0,
            );
          }

          return Transform(
            transform: Matrix4.identity()
              ..translate(position.dx * MediaQuery.of(context).size.width)
              ..rotateZ(rotation),
            child: _buildTinderCard(),
          );
        },
      ),
    );
  }

  Widget _buildTinderCard() {
    final cardHeight = widget.isSmallCard
        ? MediaQuery.of(context).size.height * 0.65
        : MediaQuery.of(context).size.height * 0.75;
    
    final imageUrls = widget.user.allImageUrls;

    return Container(
      height: cardHeight,
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
      child: Stack(
        children: [
          // Image Gallery (Full Card)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _handleImagePanStart,
              onPanUpdate: _handleImagePanUpdate,
              onPanEnd: _handleImagePanEnd,
              child: PageView.builder(
                controller: _imageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 60, color: Colors.grey),
                                const SizedBox(height: 10),
                                Text(
                                  'Image ${index + 1}',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),
          
          // Distance Badge (Top Left)
          _buildDistanceBadge(),
          
          // Profile Info (Bottom)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Age
                Row(
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.user.age}',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Info Row
                Row(
                  children: [
                    // Distance
                    if (widget.showDistance) _buildLocationInfo(),
                    
                    const SizedBox(width: 12),
                    
                    // Job Title
                    if (widget.user.jobTitle.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.work, size: 14, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            widget.user.jobTitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    
                    // School
                    if (widget.user.school.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.school, size: 14, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            widget.user.school,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Bio (Limited)
                if (widget.user.bio.isNotEmpty)
                  Text(
                    widget.user.bio.length > 100
                        ? '${widget.user.bio.substring(0, 100)}...'
                        : widget.user.bio,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 8),
                
                // Interests Chips
                if (widget.user.interests.isNotEmpty)
                  SizedBox(
                    height: 30,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.user.interests.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.user.interests[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Top Controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Image Counter
                if (imageUrls.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                const Spacer(),
                
                // Profile Button (Only when not swiping)
                if (_showProfileButton && !_isSwiping)
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'View Profile',
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
            ),
          ),
          
          // Image Navigation Arrows (Only when multiple images)
          if (imageUrls.length > 1) ...[
            // Left Arrow
            if (_currentImageIndex > 0)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _previousImage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Right Arrow
            if (_currentImageIndex < imageUrls.length - 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _nextImage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          
          // Swipe Indicator
          if (_isSwiping && _dragDistance.abs() > 50) ...[
            if (_dragDistance > 50)
              Positioned(
                top: 50,
                right: 30,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
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
            
            if (_dragDistance < -50)
              Positioned(
                top: 50,
                left: 30,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
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
          ],
        ],
      ),
    );
  }
}