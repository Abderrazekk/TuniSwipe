import 'package:flutter/material.dart';

class PersonalInfoWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController schoolController;
  final TextEditingController heightController;
  final TextEditingController jobTitleController;
  final TextEditingController livingInController;
  final TextEditingController topArtistController;
  final TextEditingController companyController;

  const PersonalInfoWidget({
    Key? key,
    required this.nameController,
    required this.ageController,
    required this.schoolController,
    required this.heightController,
    required this.jobTitleController,
    required this.livingInController,
    required this.topArtistController,
    required this.companyController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('👤', 'Name', nameController),
          const SizedBox(height: 16),
          _buildInfoRow('🎂', 'Age', ageController, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildInfoRow('🏫', 'School', schoolController),
          const SizedBox(height: 16),
          _buildInfoRow('📏', 'Height (cm)', heightController, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildInfoRow('💼', 'Job Title', jobTitleController),
          const SizedBox(height: 16),
          _buildInfoRow('📍', 'Living In', livingInController),
          const SizedBox(height: 16),
          _buildInfoRow('🎵', 'Top Artist', topArtistController),
          const SizedBox(height: 16),
          _buildInfoRow('🏢', 'Company', companyController),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String emoji,
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'Enter your $label',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}