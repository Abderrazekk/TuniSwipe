import 'package:flutter/material.dart';

class BioAndInterestsWidget extends StatefulWidget {
  final TextEditingController bioController;
  final TextEditingController interestController;
  final List<String> interests;
  final Function(String) onAddInterest;
  final Function(int) onRemoveInterest;

  const BioAndInterestsWidget({
    Key? key,
    required this.bioController,
    required this.interestController,
    required this.interests,
    required this.onAddInterest,
    required this.onRemoveInterest,
  }) : super(key: key);

  @override
  State<BioAndInterestsWidget> createState() => _BioAndInterestsWidgetState();
}

class _BioAndInterestsWidgetState extends State<BioAndInterestsWidget> {
  void _addInterest() {
    final interest = widget.interestController.text.trim();
    if (interest.isNotEmpty) {
      widget.onAddInterest(interest);
      widget.interestController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBioSection(),
        const SizedBox(height: 20),
        _buildInterestsSection(),
      ],
    );
  }

  Widget _buildBioSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About Me',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: widget.bioController,
                maxLines: 5,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                decoration: const InputDecoration(
                  hintText: 'Tell us about yourself...',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share your personality, hobbies, or what you\'re looking for',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tag_outlined,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Interests & Hobbies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add Interest Input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: widget.interestController,
                      decoration: const InputDecoration(
                        hintText: 'Add an interest...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addInterest(),
                    ),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    onPressed: _addInterest,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'Tap to add interests that describe you',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 16),

          // Interests Grid
          if (widget.interests.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.interests.asMap().entries.map((entry) {
                final index = entry.key;
                final interest = entry.value;
                return Container(
                  decoration: BoxDecoration(
                    color: _getInterestColor(index).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getInterestColor(index).withOpacity(0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          interest,
                          style: TextStyle(
                            color: _getInterestColor(index),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => widget.onRemoveInterest(index),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: _getInterestColor(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_emotions_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No interests yet',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add interests to help others know you better',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getInterestColor(int index) {
    final colors = [
      const Color(0xFF7C3AED), // Purple
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Violet
    ];
    return colors[index % colors.length];
  }
}
