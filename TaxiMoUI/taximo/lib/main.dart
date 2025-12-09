import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin/providers/admin_auth_provider.dart';
import 'admin/providers/users_provider.dart';
import 'admin/providers/drivers_provider.dart';
import 'admin/providers/promo_provider.dart';
import 'admin/providers/reviews_provider.dart';
import 'admin/screens/admin_login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => DriversProvider()),
        ChangeNotifierProvider(create: (_) => PromoProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
      ],
      child: MaterialApp(
        title: 'TaxiMo Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AdminLoginScreen(),
      ),
    );
  }
}

