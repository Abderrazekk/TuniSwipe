import 'package:flutter/material.dart';

class CombinedSettingsDialog extends StatefulWidget {
  final bool currentAgeFilterEnabled;
  final int currentMinAge;
  final int currentMaxAge;
  final int currentRadius;
  final bool currentLocationEnabled;
  final Function(bool, int, int) onAgeFilterChanged;
  final Function(int) onRadiusChanged;
  final Function(bool) onLocationToggled;

  const CombinedSettingsDialog({
    super.key,
    required this.currentAgeFilterEnabled,
    required this.currentMinAge,
    required this.currentMaxAge,
    required this.currentRadius,
    required this.currentLocationEnabled,
    required this.onAgeFilterChanged,
    required this.onRadiusChanged,
    required this.onLocationToggled,
  });

  @override
  State<CombinedSettingsDialog> createState() => _CombinedSettingsDialogState();
}

class _CombinedSettingsDialogState extends State<CombinedSettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _ageFilterEnabled;
  late int _minAge;
  late int _maxAge;
  late int _radius;
  late bool _locationEnabled;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ageFilterEnabled = widget.currentAgeFilterEnabled;
    _minAge = widget.currentMinAge;
    _maxAge = widget.currentMaxAge;
    _radius = widget.currentRadius;
    _locationEnabled = widget.currentLocationEnabled;
  }

  void _updateAgeFilter() {
    widget.onAgeFilterChanged(_ageFilterEnabled, _minAge, _maxAge);
  }

  void _resetAgeFilter() {
    setState(() {
      _ageFilterEnabled = false;
      _minAge = 10;
      _maxAge = 100;
    });
    _updateAgeFilter();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings_rounded, color: Colors.blue),
          SizedBox(width: 12),
          Text('Search Settings'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey[600],
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.location_on, size: 20),
                    text: 'Location',
                  ),
                  Tab(
                    icon: Icon(Icons.cake, size: 20),
                    text: 'Age Filter',
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Location Tab
                  SingleChildScrollView(
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
                              value: _locationEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _locationEnabled = value;
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
                                onChanged: _locationEnabled
                                    ? (value) {
                                        setState(() {
                                          _radius = value.round();
                                        });
                                      }
                                    : null,
                                onChangeEnd: _locationEnabled
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
                  
                  // Age Filter Tab
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        
                        if (_ageFilterEnabled) ...[
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
                          
                          // Reset Button
                          ElevatedButton(
                            onPressed: _resetAgeFilter,
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
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
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