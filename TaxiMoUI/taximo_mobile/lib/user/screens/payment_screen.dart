import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride_request_dto.dart';
import '../models/payment_history_dto.dart';
import '../services/ride_service.dart';
import '../services/payment_service.dart';
import '../../auth/providers/mobile_auth_provider.dart';
import '../../services/stripe_service.dart';
import 'payment_history_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  bool _isCreatingRide = false;
  bool _isProcessingPayment = false;
  bool _hasNavigated = false; // Prevent multiple navigations
  final RideService _rideService = RideService();
  final StripeService _stripeService = StripeService();
  
  // Cached payment arguments
  Map<String, dynamic>? _paymentArgs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paymentArgs == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _paymentArgs = args;
        _selectedPaymentMethod ??= 'cash'; // Default to cash
      }
    }
  }

  Future<void> _createRideWithPayment() async {
    if (_selectedPaymentMethod == null || _paymentArgs == null) {
      return;
    }

    final args = _paymentArgs!;

    final authProvider = Provider.of<MobileAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to book a ride'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isCreatingRide = true;
    });

    try {
      // Map payment method: cash -> "cash", online -> "online"
      final paymentMethod = _selectedPaymentMethod == 'cash' ? 'cash' : 'online';

      // Extract ride booking data from arguments
      final pickupLocationData = args['pickupLocation'] as Map<String, dynamic>;
      final dropoffLocationData = args['dropoffLocation'] as Map<String, dynamic>;

      final bookingRequest = RideRequestDto(
        riderId: args['riderId'] as int,
        driverId: args['driverId'] as int,
        pickupLocation: LocationRequest(
          name: pickupLocationData['name'] as String,
          addressLine: pickupLocationData['addressLine'] as String?,
          city: pickupLocationData['city'] as String?,
          lat: (pickupLocationData['lat'] as num).toDouble(),
          lng: (pickupLocationData['lng'] as num).toDouble(),
        ),
        dropoffLocation: LocationRequest(
          name: dropoffLocationData['name'] as String,
          addressLine: dropoffLocationData['addressLine'] as String?,
          city: dropoffLocationData['city'] as String?,
          lat: (dropoffLocationData['lat'] as num).toDouble(),
          lng: (dropoffLocationData['lng'] as num).toDouble(),
        ),
        distanceKm: (args['distanceKm'] as num).toDouble(),
        durationMin: args['durationMin'] as int,
        fareEstimate: (args['fareEstimate'] as num).toDouble(),
        fareFinal: (args['fareFinal'] as num).toDouble(),
        promoCodeId: args['promoCodeId'] as int?,
        paymentMethod: paymentMethod,
      );

      final response = await _rideService.bookRide(bookingRequest);

      if (!mounted) return;

      // Handle payment based on payment method
      if (paymentMethod == 'cash') {
        // Cash payment - show success and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your ride has been successfully booked. Please wait for driver confirmation.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate to home screen (single atomic operation)
        await Future.delayed(Duration.zero);
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/user-home',
          (route) => false,
        );
      } else if (paymentMethod == 'online') {
        // Online payment - process Stripe payment
        await _processStripePayment(response);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book ride: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRide = false;
        });
      }
    }
  }

  Future<void> _processStripePayment(RideBookingResponse response) async {
    if (!mounted) return;
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Yield UI thread to prevent blocking
      await Future.delayed(Duration.zero);
      
      if (!mounted) return;
      
      // Use EUR for Stripe (backend returns KM, but Stripe needs EUR)
      final stripeCurrency = 'eur';
      
      // Create payment intent and present payment sheet
      final paymentResult = await _stripeService.processPayment(
        amount: response.totalAmount,
        currency: stripeCurrency,
        rideId: response.rideId,
        paymentId: response.paymentId,
      );

      if (!mounted) return;

      switch (paymentResult) {
        case PaymentResult.success:
          // Payment successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful. Your ride has been booked.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );

          // Navigate to home screen (single atomic operation)
          await Future.delayed(Duration.zero);
          if (!mounted || _hasNavigated) return;
          _hasNavigated = true;
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/user-home',
            (route) => false,
          );
          break;

        case PaymentResult.cancelled:
          // User cancelled payment
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment was cancelled. Your ride is still booked.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          break;

        case PaymentResult.error:
          // Payment error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed. Your ride is still booked. Please try again later.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // If no arguments, show payment history screen
    if (_paymentArgs == null) {
      return const PaymentHistoryScreen();
    }

    final fareFinal = (_paymentArgs!['fareFinal'] as num).toDouble();

    return AbsorbPointer(
      absorbing: _isProcessingPayment || _isCreatingRide,
      child: Scaffold(
        body: Column(
        children: [
          // Purple header
          Container(
            color: colorScheme.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Payment Method',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),

          // White content area
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Payment Method',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Cash option
                  _PaymentOptionCard(
                    icon: Icons.money,
                    title: 'Cash',
                    description: 'Prepare your cash',
                    isSelected: _selectedPaymentMethod == 'cash',
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        _selectedPaymentMethod = 'cash';
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Online payment option
                  _PaymentOptionCard(
                    icon: Icons.payment,
                    title: 'Online payment',
                    description: 'Pay with your paypal balance',
                    isSelected: _selectedPaymentMethod == 'online',
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        _selectedPaymentMethod = 'online';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_selectedPaymentMethod != null && !_isCreatingRide && !_isProcessingPayment)
                      ? () => _createRideWithPayment()
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: (_isCreatingRide || _isProcessingPayment)
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          'Next',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Radio button
              Radio<String>(
                value: title.toLowerCase().contains('cash') ? 'cash' : 'online',
                groupValue: isSelected ? (title.toLowerCase().contains('cash') ? 'cash' : 'online') : null,
                onChanged: (_) => onTap(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

