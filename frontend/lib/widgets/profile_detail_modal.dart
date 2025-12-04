import 'package:flutter/material.dart';
import '../models/user.dart';
import '../constants/app_colors.dart';

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
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Stack(
            children: [
              // Blurred background
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeModal,
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),

              // Main content
              Positioned.fill(
                child: Column(
                  children: [
                    const Spacer(),
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Drag handle
                            Container(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 8,
                              ),
                              child: Container(
                                width: 60,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),

                            // Header with close button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_back_rounded,
                                      color: AppColors.textSecondary,
                                      size: 28,
                                    ),
                                    onPressed: _closeModal,
                                  ),
                                  Text(
                                    'Profile Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 48), // For balance
                                ],
                              ),
                            ),

                            Expanded(
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  // Image Gallery
                                  if (widget.user.allImageUrls.isNotEmpty)
                                    SliverAppBar(
                                      expandedHeight: 350,
                                      pinned: false,
                                      floating: false,
                                      backgroundColor: Colors.transparent,
                                      flexibleSpace: FlexibleSpaceBar(
                                        background: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 15,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Stack(
                                              children: [
                                                PageView.builder(
                                                  controller: _imageController,
                                                  onPageChanged: (index) {
                                                    setState(() {
                                                      _currentImageIndex =
                                                          index;
                                                    });
                                                  },
                                                  itemCount: widget
                                                      .user
                                                      .allImageUrls
                                                      .length,
                                                  itemBuilder: (context, index) {
                                                    return Image.network(
                                                      widget
                                                          .user
                                                          .allImageUrls[index],
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                    );
                                                  },
                                                ),

                                                // Gradient overlay at bottom
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment
                                                            .bottomCenter,
                                                        end:
                                                            Alignment.topCenter,
                                                        colors: [
                                                          Colors.black
                                                              .withOpacity(0.4),
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Image Counter with modern design
                                                Positioned(
                                                  bottom: 16,
                                                  right: 16,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          blurRadius: 10,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      '${_currentImageIndex + 1}/${widget.user.allImageUrls.length}',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textPrimary,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Navigation Arrows
                                                if (widget
                                                        .user
                                                        .allImageUrls
                                                        .length >
                                                    1) ...[
                                                  if (_currentImageIndex > 0)
                                                    Positioned(
                                                      left: 10,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: Center(
                                                        child: Container(
                                                          width: 44,
                                                          height: 44,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.9,
                                                                ),
                                                            shape:
                                                                BoxShape.circle,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                blurRadius: 10,
                                                              ),
                                                            ],
                                                          ),
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .chevron_left_rounded,
                                                              color: AppColors
                                                                  .primary,
                                                              size: 28,
                                                            ),
                                                            onPressed: () {
                                                              _imageController?.previousPage(
                                                                duration:
                                                                    const Duration(
                                                                      milliseconds:
                                                                          300,
                                                                    ),
                                                                curve: Curves
                                                                    .easeInOut,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                  if (_currentImageIndex <
                                                      widget
                                                              .user
                                                              .allImageUrls
                                                              .length -
                                                          1)
                                                    Positioned(
                                                      right: 10,
                                                      top: 0,
                                                      bottom: 0,
                                                      child: Center(
                                                        child: Container(
                                                          width: 44,
                                                          height: 44,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.9,
                                                                ),
                                                            shape:
                                                                BoxShape.circle,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                blurRadius: 10,
                                                              ),
                                                            ],
                                                          ),
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .chevron_right_rounded,
                                                              color: AppColors
                                                                  .primary,
                                                              size: 28,
                                                            ),
                                                            onPressed: () {
                                                              _imageController?.nextPage(
                                                                duration:
                                                                    const Duration(
                                                                      milliseconds:
                                                                          300,
                                                                    ),
                                                                curve: Curves
                                                                    .easeInOut,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Profile Details
                                  SliverList(
                                    delegate: SliverChildListDelegate([
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 10),

                                            // Name and Age with badge
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            widget.user.name,
                                                            style: TextStyle(
                                                              fontSize: 32,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppColors
                                                                  .textPrimary,
                                                              height: 1.1,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              gradient: AppColors
                                                                  .primaryGradient,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              '${widget.user.age}',
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (widget
                                                              .user
                                                              .jobTitle
                                                              .isNotEmpty ||
                                                          widget
                                                              .user
                                                              .livingIn
                                                              .isNotEmpty)
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                      if (widget
                                                              .user
                                                              .jobTitle
                                                              .isNotEmpty ||
                                                          widget
                                                              .user
                                                              .livingIn
                                                              .isNotEmpty)
                                                        Row(
                                                          children: [
                                                            if (widget
                                                                .user
                                                                .jobTitle
                                                                .isNotEmpty)
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .work_outline_rounded,
                                                                    size: 16,
                                                                    color: AppColors
                                                                        .textSecondary,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Text(
                                                                    widget
                                                                        .user
                                                                        .jobTitle,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: AppColors
                                                                          .textSecondary,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            if (widget
                                                                    .user
                                                                    .jobTitle
                                                                    .isNotEmpty &&
                                                                widget
                                                                    .user
                                                                    .livingIn
                                                                    .isNotEmpty)
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                    ),
                                                                child: Container(
                                                                  width: 4,
                                                                  height: 4,
                                                                  decoration: BoxDecoration(
                                                                    color: AppColors
                                                                        .textSecondary
                                                                        .withOpacity(
                                                                          0.5,
                                                                        ),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                ),
                                                              ),
                                                            if (widget
                                                                .user
                                                                .livingIn
                                                                .isNotEmpty)
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .location_on_outlined,
                                                                    size: 16,
                                                                    color: AppColors
                                                                        .textSecondary,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Text(
                                                                    widget
                                                                        .user
                                                                        .livingIn,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: AppColors
                                                                          .textSecondary,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 24),

                                            // Quick Info Grid
                                            GridView.count(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 3.2,
                                              children: [
                                                if (widget
                                                    .user
                                                    .jobTitle
                                                    .isNotEmpty)
                                                  _buildDetailItem(
                                                    Icons.work_outline_rounded,
                                                    'Profession',
                                                    widget.user.jobTitle,
                                                  ),
                                                if (widget
                                                    .user
                                                    .school
                                                    .isNotEmpty)
                                                  _buildDetailItem(
                                                    Icons.school_outlined,
                                                    'Education',
                                                    widget.user.school,
                                                  ),
                                                if (widget
                                                    .user
                                                    .company
                                                    .isNotEmpty)
                                                  _buildDetailItem(
                                                    Icons.business_outlined,
                                                    'Company',
                                                    widget.user.company,
                                                  ),
                                                if (widget.user.height != null)
                                                  _buildDetailItem(
                                                    Icons.height_outlined,
                                                    'Height',
                                                    '${widget.user.height} cm',
                                                  ),
                                                if (widget
                                                    .user
                                                    .topArtist
                                                    .isNotEmpty)
                                                  _buildDetailItem(
                                                    Icons.music_note_outlined,
                                                    'Top Artist',
                                                    widget.user.topArtist,
                                                  ),
                                                // You can add more items or customize as needed
                                              ],
                                            ),

                                            const SizedBox(height: 28),

                                            // Bio
                                            if (widget.user.bio.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  20,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 4,
                                                          height: 20,
                                                          decoration: BoxDecoration(
                                                            gradient: AppColors
                                                                .primaryGradient,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  2,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          'About',
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColors
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      widget.user.bio,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        height: 1.5,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                            ],

                                            // Interests
                                            if (widget
                                                .user
                                                .interests
                                                .isNotEmpty) ...[
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Interests',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Wrap(
                                                    spacing: 10,
                                                    runSpacing: 10,
                                                    children: widget.user.interests.map((
                                                      interest,
                                                    ) {
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 10,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          gradient: AppColors
                                                              .primaryGradient,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: AppColors
                                                                  .primary
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Text(
                                                          interest,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                            ],

                                            // Spacing at bottom
                                            const SizedBox(height: 40),

                                            // Action Button
                                            Container(
                                              width: double.infinity,
                                              margin: const EdgeInsets.only(
                                                bottom: 30,
                                              ),
                                              child: ElevatedButton(
                                                onPressed: _closeModal,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 18,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                  shadowColor:
                                                      Colors.transparent,
                                                ),
                                                child: const Text(
                                                  'Close Profile',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
