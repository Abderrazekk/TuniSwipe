// providers/admin_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class AdminProvider with ChangeNotifier {
  // Analytics data
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? _analyticsData;
  List<dynamic>? _topCities;
  List<dynamic>? _recentMatches;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  Map<String, dynamic>? get analyticsData => _analyticsData;
  List<dynamic>? get topCities => _topCities;
  List<dynamic>? get recentMatches => _recentMatches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get complete analytics data
  Future<void> getAnalyticsData(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/admin/analytics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _analyticsData = data['data'];
        notifyListeners();
      } else {
        _error = 'Failed to load analytics: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get dashboard stats
  Future<void> getDashboardStats(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/admin/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _dashboardStats = data['data'];
        
        // Extract top cities and recent matches
        if (_dashboardStats != null) {
          _topCities = _dashboardStats!['topCities'] ?? [];
          _recentMatches = _dashboardStats!['recentMatches'] ?? [];
        }
        
        notifyListeners();
      } else {
        _error = 'Failed to load dashboard: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get historical analytics
  Future<Map<String, dynamic>> getHistoricalAnalytics(BuildContext context, {int days = 30}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/admin/analytics/historical?days=$days'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load historical data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get user activity heatmap
  Future<Map<String, dynamic>> getActivityHeatmap(BuildContext context, {int days = 7}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/admin/activity/heatmap?days=$days'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load heatmap: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Refresh all data
  Future<void> refreshAllData(BuildContext context) async {
    await Future.wait([
      getDashboardStats(context),
      getAnalyticsData(context),
    ]);
  }
}