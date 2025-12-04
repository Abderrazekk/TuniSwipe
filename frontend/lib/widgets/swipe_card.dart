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
  // ignore: unused_field
  bool _showProfileButton = true;
  final double _swipeThreshold = 100.0;
  // ignore: unused_field
  final LocationService _locationService = LocationService();

  // New: Tap detection variables
  Offset? _tapDownPosition;
  double _tapThreshold = 50.0; // Minimum drag to consider as swipe vs tap

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
    _positionAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0.0)).animate(
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
      _tapDownPosition = null;
    });
  }

  // **FIXED: Handle both tap and swipe gestures properly**
  void _handlePanStart(DragStartDetails details) {
    _tapDownPosition = details.globalPosition;
    setState(() {
      _isSwiping = true;
      _showProfileButton = false;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // Update drag distance for swiping
    setState(() {
      _dragDistance += details.delta.dx;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    // If it's a small drag (tap), handle as image navigation
    if (_dragDistance.abs() < _tapThreshold && _tapDownPosition != null) {
      _handleTapForImageNavigation();
    }
    // If it's a large drag (swipe), handle as card swiping
    else if (_dragDistance.abs() > _swipeThreshold) {
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
      _tapDownPosition = null;
    });
  }

  void _handleTapForImageNavigation() {
    if (_tapDownPosition == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(_tapDownPosition!);
    final cardWidth = renderBox.size.width;

    // Divide card into 3 vertical sections
    final sectionWidth = cardWidth / 3;

    if (localPosition.dx < sectionWidth) {
      // Left section - previous image
      _previousImage();
    } else if (localPosition.dx > 2 * sectionWidth) {
      // Right section - next image
      _nextImage();
    }
    // Middle section - do nothing (reserved for profile tap)
  }

  void _swipeRight() {
    _positionAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0.0)).animate(
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
    _positionAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.5, 0.0)).animate(
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

  Widget _buildDotIndicator() {
    final totalImages = widget.user.totalImages;

    if (totalImages <= 1) return const SizedBox.shrink();

    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalImages, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _currentImageIndex == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContentForCurrentImage() {
    final imageUrls = widget.user.allImageUrls;

    // Determine content based on image index
    if (_currentImageIndex == 0) {
      // First image: Name, Age, Distance only
      return _buildBasicInfo();
    } else if (_currentImageIndex == 1 && imageUrls.length > 1) {
      // Second image: Add Bio
      return _buildInfoWithBio();
    } else {
      // Third image onwards: Add Interests
      return _buildInfoWithInterests();
    }
  }

  Widget _buildBasicInfo() {
    return Positioned(
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
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.user.age}',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Distance only for first image
          if (widget.showDistance && widget.user.distance != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${widget.user.distance?.toStringAsFixed(1)} km away',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoWithBio() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio (with fade effect)
          if (widget.user.bio.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.user.bio,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoWithInterests() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interests
          if (widget.user.interests.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interests',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.user.interests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
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
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
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
          // Image Gallery (Full Card) - WITH PHYSICS DISABLED
          Positioned.fill(
            child: PageView.builder(
              controller: _imageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable swipe on PageView
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
                              Icon(
                                Icons.broken_image,
                                size: 60,
                                color: Colors.grey,
                              ),
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

          // Dot Indicator (Top Center)
          _buildDotIndicator(),

          // Dynamic Content Based on Image Index
          _buildContentForCurrentImage(),

          // Tap Navigation Visual Indicators (Faded)
          if (widget.user.totalImages > 1)
            Positioned.fill(
              child: Row(
                children: [
                  // Middle section (reserved for swiping)
                  Expanded(child: Container(color: Colors.transparent)),
                ],
              ),
            ),

          // Swipe Indicators (Only for card swiping)
          if (_isSwiping && _dragDistance.abs() > _swipeThreshold) ...[
            if (_dragDistance > _swipeThreshold)
              Positioned(
                top: 50,
                left: 30,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.greenAccent.withOpacity(0.95),
                          Colors.green.withOpacity(0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'LIKE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (_dragDistance < -_swipeThreshold)
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
