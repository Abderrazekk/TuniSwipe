import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
      title: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Text('$currentRadius KM', style: TextStyle(fontSize: 16)),
          if (user?.ageFilterEnabled ?? false)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.pink[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${user!.minAgeFilter}-${user.maxAgeFilter}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.pink[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (!locationEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.location_off,
                color: Colors.grey,
                size: 16,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.cake, color: Colors.pink),
          onPressed: onAgeFilterPressed,
        ),
        IconButton(
          icon: Icon(Icons.settings, color: Colors.blue),
          onPressed: onLocationSettingsPressed,
        ),
      ],
    );
  }
}