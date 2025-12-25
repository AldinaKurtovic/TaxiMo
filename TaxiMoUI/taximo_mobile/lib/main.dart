import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'auth/providers/mobile_auth_provider.dart';
import 'auth/screens/login_screen.dart';
import 'driver/providers/driver_provider.dart';
import 'user/screens/user_home_screen.dart';
import 'user/screens/ride_reservation_screen.dart';
import 'user/screens/choose_ride_screen.dart';
import 'user/screens/voucher_screen.dart';
import 'user/screens/payment_screen.dart';
import 'user/screens/payment_history_screen.dart';
import 'user/screens/rate_trip_screen.dart';
import 'user/screens/reviews_screen.dart';
import 'user/screens/promo_codes_screen.dart';
import 'user/screens/trip_history_screen.dart';
import 'driver/screens/driver_home_screen.dart';
import 'driver/providers/driver_provider.dart';
import 'driver/providers/ride_requests_provider.dart';
import 'driver/providers/active_rides_provider.dart';
import 'driver/providers/driver_reviews_provider.dart';
import 'driver/screens/ride_requests_screen.dart';
import 'driver/screens/active_ride_screen.dart';
import 'driver/screens/active_ride_driver_screen.dart';
import 'driver/screens/driver_reviews_screen.dart';
import 'driver/screens/driver_statistics_screen.dart';
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
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => RideRequestsProvider()),
        ChangeNotifierProvider(create: (_) => ActiveRidesProvider()),
        ChangeNotifierProvider(create: (_) => DriverReviewsProvider()),
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
          '/payment-history': (context) => const PaymentHistoryScreen(),
          '/rate-trip': (context) => const RateTripScreen(),
          '/reviews': (context) => const ReviewsScreen(),
          '/promo-codes': (context) => const PromoCodesScreen(),
          '/trip-history': (context) => const TripHistoryScreen(),
          '/ride-requests': (context) => const RideRequestsScreen(),
          '/active-ride': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final rideId = args is int ? args : null;
            return ActiveRideScreen(rideId: rideId);
          },
          '/active-ride-driver': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final rideId = args is int ? args : null;
            return ActiveRideDriverScreen(rideId: rideId);
          },
          '/driver-reviews': (context) {
            return const DriverReviewsScreen();
          },
          '/driver-statistics': (context) {
            return const DriverStatisticsScreen();
          },
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MobileAuthProvider, DriverProvider>(
      builder: (context, authProvider, driverProvider, child) {
        // Check driver authentication first
        if (driverProvider.isAuthenticated && driverProvider.currentDriver != null) {
          return const DriverHomeScreen();
        }

        // Check user authentication
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          final user = authProvider.currentUser!;
          if (user.isUser) {
            return const UserHomeScreen();
          }
        }

        // Show login screen if not authenticated
        return const LoginScreen();
      },
    );
  }
}
