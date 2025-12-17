import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/mobile_auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaxiMo - Driver'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              final provider = Provider.of<MobileAuthProvider>(context, listen: false);
              provider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Consumer<MobileAuthProvider>(
        builder: (context, provider, child) {
          final user = provider.currentUser;
          
          if (user == null) {
            return const Center(child: Text('No user data available'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user.fullName}!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${user.email}'),
                        if (user.phone != null) Text('Phone: ${user.phone}'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: user.roles.map((role) {
                            return Chip(
                              label: Text(role.name),
                              backgroundColor: Colors.deepPurple[100],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Driver Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Driver-specific features will be implemented here.'),
              ],
            ),
          );
        },
      ),
    );
  }
}

