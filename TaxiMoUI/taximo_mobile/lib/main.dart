import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/providers/mobile_auth_provider.dart';
import 'auth/screens/login_screen.dart';
import 'user/screens/user_home_screen.dart';
import 'user/screens/ride_reservation_screen.dart';
import 'user/screens/choose_ride_screen.dart';
import 'user/screens/voucher_screen.dart';
import 'driver/screens/driver_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MobileAuthProvider()),
      ],
      child: MaterialApp(
        title: 'TaxiMo Mobile',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/user-home': (context) => const UserHomeScreen(),
          '/driver-home': (context) => const DriverHomeScreen(),
          '/ride-reservation': (context) => const RideReservationScreen(),
          '/choose-ride': (context) => const ChooseRideScreen(),
          '/voucher': (context) => const VoucherScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileAuthProvider>(
      builder: (context, authProvider, child) {
        // Show login screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Navigate based on user role
        final user = authProvider.currentUser;
        if (user == null) {
          return const LoginScreen();
        }

        if (user.isUser) {
          return const UserHomeScreen();
        } else if (user.isDriver) {
          return const DriverHomeScreen();
        } else {
          // Unknown role, show login
          return const LoginScreen();
        }
      },
    );
  }
}
