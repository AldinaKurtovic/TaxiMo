import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin/providers/admin_auth_provider.dart';
import 'admin/providers/users_provider.dart';
import 'admin/providers/drivers_provider.dart';
import 'admin/providers/promo_provider.dart';
import 'admin/providers/reviews_provider.dart';
import 'admin/providers/statistics_provider.dart';
import 'admin/providers/rides_provider.dart';
import 'admin/providers/payments_provider.dart';
import 'admin/providers/admin_profile_provider.dart';
// Note: File still named admin_profile_provider.dart but class is UserProfileProvider
import 'admin/screens/admin_login_screen.dart';
import 'admin/screens/home/home_screen.dart';
import 'admin/layout/master_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Admin Providers
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => DriversProvider()),
        ChangeNotifierProvider(create: (_) => PromoProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => RidesProvider()),
        ChangeNotifierProvider(create: (_) => PaymentsProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: MaterialApp(
        title: 'TaxiMo Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const AdminLoginScreen(),
          '/home': (context) => const HomeScreen(),
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
    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If authenticated, navigate to admin home screen with master layout
        if (authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const MasterScreen(
                  child: HomeScreen(),
                  currentRoute: '/home',
                ),
              ),
            );
          });
          // Show a loading indicator while navigating
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show login screen if not authenticated
        return const AdminLoginScreen();
      },
    );
  }
}

