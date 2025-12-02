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
  late PageController _imagePageController;
  
  bool _isSwiping = false;
  double _dragDistance = 0.0;
  int _currentImageIndex = 0;
  bool _showImageControls = false;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _resetCardCompletely();
    }
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

  void _resetCardCompletely() {
    _animationController.reset();
    _imagePageController.jumpToPage(0);
    _resetAnimations();
    setState(() {
      _dragDistance = 0.0;
      _isSwiping = false;
      _currentImageIndex = 0;
      _showImageControls = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imagePageController.dispose();
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

  void _resetCard() {
    _animationController.reset();
    setState(() {
      _dragDistance = 0.0;
      _isSwiping = false;
    });
  }

  void _nextImage() {
    if (_currentImageIndex < widget.user.totalImages - 1) {
      _imagePageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _imagePageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleImageTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.localPosition.dx;
    
    final leftZone = screenWidth * 0.2;
    final rightZone = screenWidth * 0.8;
    
    if (tapPosition < leftZone) {
      _previousImage();
    } else if (tapPosition > rightZone) {
      _nextImage();
    } else {
      setState(() {
        _showImageControls = !_showImageControls;
      });
    }
  }

  void _showProfilePreview() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildProfilePreviewSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    
    final imageUrls = widget.user.allImageUrls;

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
                  child: GestureDetector(
                    onTapDown: _handleImageTapDown,
                    child: PageView.builder(
                      controller: _imagePageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
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
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 50,
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
                
                Container(
                  height: imageHeight,
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
                
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${imageUrls.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                if (widget.showDistance && widget.user.distance != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
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
                          SizedBox(width: 4),
                          Text(
                            LocationService.formatDistance(
                              widget.user.distance,
                            ),
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
                
                if (_showImageControls && imageUrls.length > 1)
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _previousImage,
                        ),
                      ),
                    ),
                  ),
                
                if (_showImageControls && imageUrls.length > 1)
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _nextImage,
                        ),
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
                      
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showProfilePreview,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 16,
                                  ),
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
                          
                          SizedBox(width: 10),
                          
                          if (widget.user.jobTitle.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.work,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    widget.user.jobTitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildProfilePreviewSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 8, bottom: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: widget.user.photo.isNotEmpty
                          ? NetworkImage('http://10.0.2.2:5000/uploads/${widget.user.photo}')
                          : AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.user.age} years old',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              Divider(),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (widget.user.jobTitle.isNotEmpty)
                      _buildInfoChip(
                        Icons.work,
                        widget.user.jobTitle,
                      ),
                    if (widget.user.school.isNotEmpty)
                      _buildInfoChip(
                        Icons.school,
                        widget.user.school,
                      ),
                    if (widget.user.livingIn.isNotEmpty)
                      _buildInfoChip(
                        Icons.location_on,
                        widget.user.livingIn,
                      ),
                    if (widget.user.height != null)
                      _buildInfoChip(
                        Icons.height,
                        '${widget.user.height} cm',
                      ),
                  ],
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onTap();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 10),
                      Text('View Full Profile'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }
}