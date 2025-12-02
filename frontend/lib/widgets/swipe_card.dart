// widgets/swipe_card.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/location_service.dart';

class SwipeCard extends StatefulWidget {
  final User user;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onTap;
  final bool showDistance;
  final bool isSmallCard;

  const SwipeCard({
    Key? key,
    required this.user,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onTap,
    this.showDistance = true,
    this.isSmallCard = false,
  }) : super(key: key);

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;

  bool _isSwiping = false;
  double _dragDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _resetAnimations();
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

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _resetCardCompletely();
    }
  }

  void _resetCardCompletely() {
    _animationController.reset();
    _resetAnimations();
    setState(() {
      _dragDistance = 0.0;
      _isSwiping = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isSwiping = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance += details.delta.dx;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    const double swipeThreshold = 100.0;

    if (_dragDistance.abs() > swipeThreshold) {
      if (_dragDistance > 0) {
        _swipeRight();
      } else {
        _swipeLeft();
      }
    } else {
      _resetCard();
    }

    setState(() {
      _isSwiping = false;
    });
  }

  void _swipeRight() {
    _animationController.forward().then((_) {
      widget.onSwipeRight();
    });
  }

  void _swipeLeft() {
    _positionAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.5, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: -0.1,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    _animationController.forward().then((_) {
      widget.onSwipeLeft();
    });
  }

  void _resetCard() {
    _animationController.reset();
    setState(() {
      _dragDistance = 0.0;
      _isSwiping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
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
            child: _buildCardContent(),
          );
        },
      ),
    );
  }

  Widget _buildCardContent() {
    final cardHeight = widget.isSmallCard 
        ? MediaQuery.of(context).size.height * 0.6
        : MediaQuery.of(context).size.height * 0.75;
    
    final imageHeight = widget.isSmallCard
        ? cardHeight * 0.65
        : cardHeight * 0.7;

    return Container(
      height: cardHeight,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: widget.isSmallCard ? 7 : 8,
            child: Stack(
              children: [
                Container(
                  height: imageHeight,
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

                if (widget.showDistance && widget.user.distance != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            LocationService.formatDistance(widget.user.distance),
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

                if (_isSwiping && _dragDistance.abs() > 50) ...[
                  if (_dragDistance < -50)
                    Positioned(
                      left: 20,
                      top: 40,
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

                  if (_dragDistance > 50)
                    Positioned(
                      right: 20,
                      top: 40,
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
                ],

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
                            style: TextStyle(
                              fontSize: widget.isSmallCard ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${widget.user.age}',
                            style: TextStyle(
                              fontSize: widget.isSmallCard ? 24 : 28,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      
                      if (widget.showDistance && widget.user.distance != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${widget.user.distance?.toStringAsFixed(1)} km away',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      
                      if (widget.user.jobTitle.isNotEmpty ||
                          widget.user.livingIn.isNotEmpty)
                        Row(
                          children: [
                            if (widget.user.jobTitle.isNotEmpty) ...[
                              Icon(
                                Icons.work,
                                size: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              SizedBox(width: 4),
                              Text(
                                widget.user.jobTitle,
                                style: TextStyle(
                                  fontSize: widget.isSmallCard ? 13 : 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                            if (widget.user.livingIn.isNotEmpty &&
                                widget.user.jobTitle.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (widget.user.livingIn.isNotEmpty) ...[
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              SizedBox(width: 4),
                              Text(
                                widget.user.livingIn,
                                style: TextStyle(
                                  fontSize: widget.isSmallCard ? 13 : 16,
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

          Expanded(
            flex: widget.isSmallCard ? 3 : 4,
            child: Padding(
              padding: EdgeInsets.all(widget.isSmallCard ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.user.bio.isNotEmpty)
                    Expanded(
                      child: Text(
                        widget.user.bio,
                        style: TextStyle(
                          fontSize: widget.isSmallCard ? 14 : 16,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: widget.isSmallCard ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  SizedBox(height: widget.isSmallCard ? 8 : 12),
                  if (widget.user.interests.isNotEmpty)
                    SizedBox(
                      height: widget.isSmallCard ? 28 : 32,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.user.interests.length,
                        itemBuilder: (context, index) {
                          final interest = widget.user.interests[index];
                          return Container(
                            margin: EdgeInsets.only(right: 6),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.pink[100]!),
                            ),
                            child: Text(
                              interest,
                              style: TextStyle(
                                fontSize: widget.isSmallCard ? 11 : 12,
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
    return const AssetImage('assets/default_avatar.png');
  }
}