import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'auth/providers/mobile_auth_provider.dart';
import 'auth/screens/login_screen.dart';
import 'user/screens/user_home_screen.dart';
import 'user/screens/ride_reservation_screen.dart';
import 'user/screens/choose_ride_screen.dart';
import 'user/screens/voucher_screen.dart';
import 'user/screens/payment_screen.dart';
import 'driver/screens/driver_home_screen.dart';
import 'services/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  debugPrint('[main] Loading .env file...');
  await dotenv.load(fileName: ".env");
  debugPrint('[main] .env file loaded. Keys available: ${dotenv.env.keys.length}');
  
  // Validate STRIPE_PUBLISHABLE_KEY exists
  if (dotenv.env['STRIPE_PUBLISHABLE_KEY'] == null || 
      dotenv.env['STRIPE_PUBLISHABLE_KEY']!.isEmpty) {
    debugPrint('[main] WARNING: STRIPE_PUBLISHABLE_KEY is not set in .env file');
  } else {
    final maskedKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!.length > 6
        ? '${dotenv.env['STRIPE_PUBLISHABLE_KEY']!.substring(0, 6)}...'
        : '***';
    debugPrint('[main] STRIPE_PUBLISHABLE_KEY found: $maskedKey');
  }
  
  // Initialize Stripe (after dotenv.load())
  debugPrint('[main] Initializing Stripe...');
  final stripeService = StripeService();
  try {
    await stripeService.init();
    debugPrint('[main] Stripe initialized successfully');
  } catch (e) {
    // Log error but don't crash the app
    debugPrint('[main] ERROR: Failed to initialize Stripe: $e');
  }
  
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
          '/payment': (context) => const PaymentScreen(),
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
