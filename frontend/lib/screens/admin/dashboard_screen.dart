import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    print('📊 Dashboard Screen - User role: ${user?.role}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, Admin ${user?.name ?? ''}!', 
                 style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text('Email: ${user?.email ?? ''}', 
                 style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            const Text('This is the admin dashboard'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add admin functionalities here
              },
              child: const Text('Admin Actions'),
            ),
          ],
        ),
      ),
    );
  }
}