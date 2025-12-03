// widgets/age_filter_dialog.dart
import 'package:flutter/material.dart';

class AgeFilterDialog extends StatefulWidget {
  final bool currentAgeFilterEnabled;
  final int currentMinAge;
  final int currentMaxAge;
  final Function(bool, int, int) onAgeFilterChanged;

  const AgeFilterDialog({
    super.key,
    required this.currentAgeFilterEnabled,
    required this.currentMinAge,
    required this.currentMaxAge,
    required this.onAgeFilterChanged,
  });

  @override
  State<AgeFilterDialog> createState() => _AgeFilterDialogState();
}

class _AgeFilterDialogState extends State<AgeFilterDialog> {
  late bool _ageFilterEnabled;
  late int _minAge;
  late int _maxAge;

  @override
  void initState() {
    super.initState();
    _ageFilterEnabled = widget.currentAgeFilterEnabled;
    _minAge = widget.currentMinAge;
    _maxAge = widget.currentMaxAge;
  }

  void _updateAgeFilter() {
    widget.onAgeFilterChanged(_ageFilterEnabled, _minAge, _maxAge);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cake, color: Colors.pink),
          SizedBox(width: 12),
          Text('Age Filter Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable/Disable Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enable Age Filter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Switch(
                  value: _ageFilterEnabled,
                  onChanged: (value) {
                    setState(() {
                      _ageFilterEnabled = value;
                    });
                    _updateAgeFilter();
                  },
                  activeColor: Colors.pink,
                ),
              ],
            ),
            
            SizedBox(height: _ageFilterEnabled ? 24 : 0),
            
            // Age Range Sliders (only show when enabled)
            if (_ageFilterEnabled) ...[
              Text(
                'Age Range',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'Set the age range you want to see',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              
              SizedBox(height: 20),
              
              // Age Range Display
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink[100]!),
                ),
                child: Center(
                  child: Text(
                    '$_minAge - $_maxAge years',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[800],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Minimum Age Slider
              Text(
                'Minimum Age: $_minAge',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Slider(
                value: _minAge.toDouble(),
                min: 10,
                max: _maxAge.toDouble(),
                divisions: (_maxAge - 10),
                label: '$_minAge',
                onChanged: (value) {
                  setState(() {
                    _minAge = value.round();
                  });
                },
                onChangeEnd: (value) {
                  _updateAgeFilter();
                },
                activeColor: Colors.pink,
                inactiveColor: Colors.grey[300],
              ),
              
              SizedBox(height: 24),
              
              // Maximum Age Slider
              Text(
                'Maximum Age: $_maxAge',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Slider(
                value: _maxAge.toDouble(),
                min: _minAge.toDouble(),
                max: 100,
                divisions: (100 - _minAge),
                label: '$_maxAge',
                onChanged: (value) {
                  setState(() {
                    _maxAge = value.round();
                  });
                },
                onChangeEnd: (value) {
                  _updateAgeFilter();
                },
                activeColor: Colors.pink,
                inactiveColor: Colors.grey[300],
              ),
              
              SizedBox(height: 16),
              
              // Quick Age Presets
              Text(
                'Quick Settings:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAgePreset(10, 25),
                  _buildAgePreset(10, 35),
                  _buildAgePreset(10, 50),
                  _buildAgePreset(25, 35),
                  _buildAgePreset(25, 50),
                  _buildAgePreset(30, 45),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Reset to Default Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _ageFilterEnabled = false;
                    _minAge = 10;
                    _maxAge = 100;
                  });
                  _updateAgeFilter();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey[700],
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Reset to Default (No Filter)'),
              ),
            ] else ...[
              // When filter is disabled
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.filter_alt_off, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Age filter is currently disabled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enable the filter to set an age range for potential matches',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildAgePreset(int min, int max) {
    final isSelected = _minAge == min && _maxAge == max;
    return FilterChip(
      label: Text('$min-$max'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _minAge = min;
          _maxAge = max;
        });
        _updateAgeFilter();
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.pink[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.pink : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}