// widgets/location_settings_dialog.dart
import 'package:flutter/material.dart';

class LocationSettingsDialog extends StatefulWidget {
  final int currentRadius;
  final bool locationEnabled;
  final Function(int) onRadiusChanged;
  final Function(bool) onLocationToggled;

  const LocationSettingsDialog({
    super.key,
    required this.currentRadius,
    required this.locationEnabled,
    required this.onRadiusChanged,
    required this.onLocationToggled,
  });

  @override
  State<LocationSettingsDialog> createState() => _LocationSettingsDialogState();
}

class _LocationSettingsDialogState extends State<LocationSettingsDialog> {
  late int _radius;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _radius = widget.currentRadius;
    _enabled = widget.locationEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue),
          SizedBox(width: 12),
          Text('Location Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enable Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Switch(
                  value: _enabled,
                  onChanged: (value) {
                    setState(() {
                      _enabled = value;
                    });
                    widget.onLocationToggled(value);
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),

            SizedBox(height: 24),

            Text(
              'Search Radius',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Set how far away you want to see people',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$_radius KM',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 16),

                  Slider(
                    value: _radius.toDouble(),
                    min: 0,
                    max: 150,
                    divisions: 15,
                    label: '$_radius KM',
                    onChanged: _enabled
                        ? (value) {
                            setState(() {
                              _radius = value.round();
                            });
                          }
                        : null,
                    onChangeEnd: _enabled
                        ? (value) {
                            widget.onRadiusChanged(value.round());
                          }
                        : null,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[300],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0 KM',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '150 KM',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
      ],
    );
  }
}
