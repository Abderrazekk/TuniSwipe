// screens/admin/dashboard_screen.dart (UPDATED)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/admin/stat_card.dart';
import '../../widgets/admin/city_card.dart';
import '../../widgets/admin/recent_match_card.dart';
import '../../widgets/admin/analytics_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Provider.of<AdminProvider>(context, listen: false).refreshAllData(context);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final adminProvider = Provider.of<AdminProvider>(context);

    print('📊 Dashboard Screen - User role: ${user?.role}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 30,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, Admin ${user?.name ?? ''}!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'admin@admin.com',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (adminProvider.dashboardStats != null)
                              Text(
                                'Last updated: ${adminProvider.dashboardStats?['lastUpdated'] != null ? _formatLastUpdated(adminProvider.dashboardStats!['lastUpdated']) : 'Just now'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Loading/Error State
              if (adminProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (adminProvider.error != null)
                Card(
                  color: AppColors.errorLight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          adminProvider.error!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refreshData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (adminProvider.dashboardStats == null)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No data available'),
                  ),
                )
              else
                // Main Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Stats Grid
                    const Text(
                      'Summary Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        StatCard(
                          title: 'Total Users',
                          value: (adminProvider.dashboardStats?['totalUsers'] ?? 0).toString(),
                          icon: Icons.people,
                          iconColor: AppColors.primary,
                          subtitle: adminProvider.dashboardStats?['newUsersToday'] != null
                              ? '+${adminProvider.dashboardStats!['newUsersToday']} today'
                              : null,
                        ),
                        StatCard(
                          title: 'Online Users',
                          value: (adminProvider.dashboardStats?['onlineUsers'] ?? 0).toString(),
                          icon: Icons.online_prediction,
                          iconColor: AppColors.success,
                        ),
                        StatCard(
                          title: 'Daily Swipes',
                          value: (adminProvider.dashboardStats?['dailySwipes'] ?? 0).toString(),
                          icon: Icons.swipe,
                          iconColor: AppColors.info,
                          subtitle: 'Last hour: ${adminProvider.dashboardStats?['swipesLastHour'] ?? 0}',
                        ),
                        StatCard(
                          title: 'Match Rate',
                          value: adminProvider.dashboardStats?['matchRate'] ?? '0%',
                          icon: Icons.favorite,
                          iconColor: AppColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Matches
                    const Text(
                      'Recent Matches',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (adminProvider.recentMatches != null &&
                        adminProvider.recentMatches!.isNotEmpty)
                      ...adminProvider.recentMatches!
                          .take(5)
                          .map((match) => RecentMatchCard(
                                match: match,
                                onTap: () {
                                  // Navigate to match details
                                },
                              ))
                          .toList()
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'No recent matches',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Top Cities
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Top Cities by Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to full cities list
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (adminProvider.topCities != null &&
                        adminProvider.topCities!.isNotEmpty)
                      ...adminProvider.topCities!
                          .asMap()
                          .entries
                          .map((entry) => CityCard(
                                city: entry.value['city'] ?? 'Unknown',
                                userCount: entry.value['userCount'] ?? 0,
                                rank: entry.key + 1,
                                onTap: () {
                                  // Navigate to city details
                                },
                              ))
                          .toList()
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'No city data available',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Gender Distribution (if available in analytics)
                    if (adminProvider.analyticsData != null &&
                        adminProvider.analyticsData!['genderDistribution'] != null)
                      _buildGenderDistribution(adminProvider.analyticsData!['genderDistribution']),
                  ],
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Dashboard',
      ),
    );
  }

  Widget _buildGenderDistribution(Map<String, dynamic> genderData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gender Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGenderChip(
                  'Male',
                  genderData['male'] ?? 0,
                  AppColors.info,
                ),
                _buildGenderChip(
                  'Female',
                  genderData['female'] ?? 0,
                  AppColors.pink,
                ),
                _buildGenderChip(
                  'Other',
                  genderData['other'] ?? 0,
                  AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatLastUpdated(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}