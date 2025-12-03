// Create new file: widgets/profile_detail_modal.dart

import 'package:flutter/material.dart';
import '../models/user.dart';

class ProfileDetailModal extends StatefulWidget {
  final User user;
  final VoidCallback onClose;

  const ProfileDetailModal({
    Key? key,
    required this.user,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ProfileDetailModal> createState() => _ProfileDetailModalState();
}

class _ProfileDetailModalState extends State<ProfileDetailModal> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentImageIndex = 0;
  PageController? _imageController;

  @override
  void initState() {
    super.initState();
    
    if (widget.user.allImageUrls.isNotEmpty) {
      _imageController = PageController();
    }
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _imageController?.dispose();
    super.dispose();
  }

  void _closeModal() {
    _controller.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            color: Colors.black.withOpacity(0.5),
            child: Column(
              children: [
                // Drag Handle
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 10) {
                      _closeModal();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: CustomScrollView(
                      slivers: [
                        // Image Gallery
                        if (widget.user.allImageUrls.isNotEmpty)
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
                                    itemCount: widget.user.allImageUrls.length,
                                    itemBuilder: (context, index) {
                                      return Image.network(
                                        widget.user.allImageUrls[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      );
                                    },
                                  ),
                                  
                                  // Image Counter
                                  Positioned(
                                    top: 20,
                                    right: 20,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_currentImageIndex + 1}/${widget.user.allImageUrls.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Navigation Arrows
                                  if (widget.user.allImageUrls.length > 1) ...[
                                    if (_currentImageIndex > 0)
                                      Positioned(
                                        left: 10,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.chevron_left,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                            onPressed: () {
                                              _imageController?.previousPage(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    
                                    if (_currentImageIndex < widget.user.allImageUrls.length - 1)
                                      Positioned(
                                        right: 10,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.chevron_right,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                            onPressed: () {
                                              _imageController?.nextPage(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        
                        // Profile Details
                        SliverList(
                          delegate: SliverChildListDelegate([
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name and Age
                                  Row(
                                    children: [
                                      Text(
                                        widget.user.name,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${widget.user.age}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Quick Info Grid
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
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
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Bio
                                  if (widget.user.bio.isNotEmpty) ...[
                                    const Text(
                                      'About',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.user.bio,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  
                                  // Interests
                                  if (widget.user.interests.isNotEmpty) ...[
                                    const Text(
                                      'Interests',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
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
                                  
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}