import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin/providers/admin_auth_provider.dart';
import 'admin/providers/users_provider.dart';
import 'admin/providers/drivers_provider.dart';
import 'admin/providers/promo_provider.dart';
import 'admin/providers/reviews_provider.dart';
import 'admin/providers/statistics_provider.dart';
import 'admin/providers/rides_provider.dart';
import 'mobile/auth/providers/auth_provider.dart';
import 'mobile/auth/screens/mobile_login_screen.dart';
import 'mobile/user/screens/user_home_screen.dart';
import 'mobile/driver/screens/driver_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Mobile Auth Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Admin Providers (kept for admin functionality)
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => DriversProvider()),
        ChangeNotifierProvider(create: (_) => PromoProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => RidesProvider()),
      ],
      child: MaterialApp(
        title: 'TaxiMo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const MobileLoginScreen(),
          '/user-home': (context) => const UserHomeScreen(),
          '/driver-home': (context) => const DriverHomeScreen(),
        },
      ),
    );
  }
}

/// Wrapper widget that checks authentication state and navigates accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If authenticated, navigate to appropriate home screen based on role
        if (authProvider.isAuthenticated) {
          final userRole = authProvider.userRole;
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (userRole == 'DRIVER') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const UserHomeScreen()),
              );
            }
          });
        }

        // Show login screen if not authenticated
        return const MobileLoginScreen();
      },
    );
  }
}

