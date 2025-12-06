import 'package:flutter/material.dart';
import '../../models/user.dart';

class ProfileDetailScreen extends StatefulWidget {
  final User user;

  const ProfileDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late PageController _imageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.user.allImageUrls;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Share profile
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
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
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),

                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${imageUrls.length}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  if (imageUrls.length > 1)
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            if (_currentImageIndex > 0) {
                              _imageController.previousPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),

                  if (imageUrls.length > 1)
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            if (_currentImageIndex < imageUrls.length - 1) {
                              _imageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.user.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${widget.user.age}',
                          style: TextStyle(fontSize: 28, color: Colors.black54),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
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

                    SizedBox(height: 20),

                    if (widget.user.bio.isNotEmpty) ...[
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.user.bio,
                        style: TextStyle(fontSize: 16, height: 1.4),
                      ),
                      SizedBox(height: 20),
                    ],

                    if (widget.user.interests.isNotEmpty) ...[
                      Text(
                        'Interests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
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
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}