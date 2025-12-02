// services/location_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final loc.Location _location = loc.Location();
  bool _serviceEnabled = false;
  loc.PermissionStatus? _permissionGranted;
  loc.LocationData? _currentLocation;
  StreamSubscription<loc.LocationData>? _locationSubscription;

  Future<bool> checkAndRequestPermission(BuildContext context) async {
    print('📍 Checking location permissions...');
    
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      print('❌ Location services are disabled');
      
      bool? shouldEnable = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Location Services Required'),
          content: const Text(
            'This app needs location access to show you people nearby. '
            'Please enable location services to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable Location'),
            ),
          ],
        ),
      );

      if (shouldEnable == true) {
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          return false;
        }
      } else {
        return false;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      print('📍 Requesting location permission...');
      _permissionGranted = await _location.requestPermission();
      
      if (_permissionGranted != loc.PermissionStatus.granted &&
          _permissionGranted != loc.PermissionStatus.grantedLimited) {
        print('❌ Location permission denied');
        
        bool? shouldRequest = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'To show you people near your location, we need access to your device\'s location. '
              'You can change this permission in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          await openAppSettings();
        }
        return false;
      }
    }

    print('✅ Location permission granted');
    return true;
  }

  Future<loc.LocationData?> getCurrentLocation() async {
    try {
      print('📍 Getting current location...');
      
      bool hasPermission = await _checkPermissionStatus();
      if (!hasPermission) {
        print('❌ No location permission');
        return null;
      }

      _currentLocation = await _location.getLocation();
      
      print('📍 Location obtained:');
      print('   Latitude: ${_currentLocation!.latitude}');
      print('   Longitude: ${_currentLocation!.longitude}');
      
      return _currentLocation;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  Future<bool> _checkPermissionStatus() async {
    final status = await Permission.location.status;
    return status.isGranted || status.isLimited;
  }

  Future<bool> sendLocationToBackend({
    required String token,
    required double latitude,
    required double longitude,
    double? accuracy,
    String? provider,
    bool forceUpdate = false,
  }) async {
    try {
      print('📍 Sending location to backend...');
      
      final response = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/auth/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'provider': provider ?? 'gps',
          'forceUpdate': forceUpdate,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ Location sent successfully');
        return true;
      } else {
        print('❌ Failed to send location: ${responseData['message']}');
        return false;
      }
    } catch (error) {
      print('❌ Error sending location: $error');
      return false;
    }
  }

  Future<bool> updateLocationRadius({
    required String token,
    required int radius,
  }) async {
    try {
      print('📍 Updating location radius: $radius KM');
      
      final response = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/auth/location/radius'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'radius': radius,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ Location radius updated');
        return true;
      } else {
        print('❌ Failed to update radius: ${responseData['message']}');
        return false;
      }
    } catch (error) {
      print('❌ Error updating radius: $error');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLocationSettings(String token) async {
    try {
      print('📍 Getting location settings...');
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/auth/location/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ Location settings retrieved');
        return responseData['data'];
      } else {
        print('❌ Failed to get location settings: ${responseData['message']}');
        return null;
      }
    } catch (error) {
      print('❌ Error getting location settings: $error');
      return null;
    }
  }

  Future<bool> toggleLocationEnabled({
    required String token,
    required bool enabled,
  }) async {
    try {
      print('📍 Toggling location: $enabled');
      
      final response = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/auth/location/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'enabled': enabled,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ Location toggled');
        return true;
      } else {
        print('❌ Failed to toggle location: ${responseData['message']}');
        return false;
      }
    } catch (error) {
      print('❌ Error toggling location: $error');
      return false;
    }
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  static String formatDistance(double? distance) {
    if (distance == null) return 'Unknown';
    
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    } else if (distance < 10) {
      return '${distance.toStringAsFixed(1)} km';
    } else {
      return '${distance.toStringAsFixed(0)} km';
    }
  }

  void dispose() {
    _locationSubscription?.cancel();
  }
}