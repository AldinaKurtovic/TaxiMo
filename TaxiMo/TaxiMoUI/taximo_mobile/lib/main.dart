import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'auth/providers/mobile_auth_provider.dart';
import 'auth/screens/login_screen.dart';
import 'auth/screens/register_screen.dart';
import 'driver/providers/driver_provider.dart';
import 'user/screens/user_home_screen.dart';
import 'user/layout/user_main_navigation.dart';
import 'user/providers/user_profile_provider.dart';
import 'user/providers/notification_provider.dart';
import 'user/providers/user_active_rides_provider.dart';
import 'user/screens/ride_reservation_screen.dart';
import 'user/screens/choose_ride_screen.dart';
import 'user/screens/voucher_screen.dart';
import 'user/screens/payment_screen.dart';
import 'user/screens/payment_history_screen.dart';
import 'user/screens/rate_trip_screen.dart';
import 'user/screens/reviews_screen.dart';
import 'user/screens/promo_codes_screen.dart';
import 'user/screens/trip_history_screen.dart';
import 'user/screens/notifications_screen.dart';
import 'driver/layout/driver_main_navigation.dart';
import 'driver/providers/driver_provider.dart';
import 'driver/providers/driver_profile_provider.dart';
import 'driver/providers/ride_requests_provider.dart';
import 'driver/providers/active_rides_provider.dart';
import 'driver/providers/driver_reviews_provider.dart';
import 'driver/providers/notification_provider.dart';
import 'driver/screens/ride_requests_screen.dart';
import 'driver/screens/notifications_screen.dart';
import 'driver/screens/active_ride_screen.dart';
import 'driver/screens/active_ride_driver_screen.dart';
import 'driver/screens/driver_reviews_screen.dart';
import 'driver/screens/driver_statistics_screen.dart';
import 'services/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file asynchronously without blocking
  await dotenv.load(fileName: ".env");
  
  // Defer Stripe initialization - don't block startup
  // Stripe will be initialized when needed (first payment)
  StripeService.instance.init().catchError((_) {
    // Silent error - Stripe will retry when needed
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers - always needed
        ChangeNotifierProvider(create: (_) => MobileAuthProvider(), lazy: false),
        // 🔥 KORAK 2: DriverProvider NIKAD NE SMIJE UTICATI NA ROOT
        // DriverProvider se koristi TEK NAKON što si u HomeScreen, ne u AuthWrapper
        ChangeNotifierProvider(create: (_) => DriverProvider(), lazy: true),
        // User providers - lazy load, created only when accessed
        ChangeNotifierProvider(create: (_) => UserProfileProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => NotificationProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => UserActiveRidesProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DriverProfileProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => RideRequestsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => ActiveRidesProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DriverReviewsProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DriverNotificationProvider(), lazy: true),
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
          '/register': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            return RegisterScreen();
          },
          '/user-home': (context) => const UserMainNavigation(),
          '/driver-home': (context) => const DriverMainNavigation(),
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
          '/notifications': (context) {
            return const NotificationsScreen();
          },
          '/driver-notifications': (context) {
            return const DriverNotificationsScreen();
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
    final auth = context.watch<MobileAuthProvider>();

    if (auth.isAuthLocked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isAuthenticated) {
      return const UserMainNavigation();
    }

    return const LoginScreen();
  }
}
