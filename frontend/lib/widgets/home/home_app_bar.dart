import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

import '../../constants/app_colors.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentRadius;
  final bool locationEnabled;
  final VoidCallback onAgeFilterPressed;
  final VoidCallback onLocationSettingsPressed;

  const HomeAppBar({
    super.key,
    required this.currentRadius,
    required this.locationEnabled,
    required this.onAgeFilterPressed,
    required this.onLocationSettingsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.surface,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          boxShadow: AppColors.shadowSmall,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.shadowSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: AppColors.textInverse, size: 16),
                SizedBox(width: 6),
                Text(
                  '$currentRadius KM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textInverse,
                  ),
                ),
              ],
            ),
          ),
          if (user?.ageFilterEnabled ?? false)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.pink.withOpacity(0.15),
                      AppColors.pink.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.pink.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cake_outlined, color: AppColors.pink, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '${user!.minAgeFilter}-${user.maxAgeFilter}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.pink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!locationEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.pink.withOpacity(0.1),
                AppColors.pink.withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.cake_outlined, color: AppColors.pink, size: 22),
            onPressed: onAgeFilterPressed,
            tooltip: 'Age Filter',
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 4, right: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: AppColors.secondary,
              size: 22,
            ),
            onPressed: onLocationSettingsPressed,
            tooltip: 'Settings',
          ),
        ),
      ],
    );
  }
}
