import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

enum PaymentResult {
  success,
  cancelled,
  error,
}

class StripeService {
  static bool _initialized = false;

  /// Initialize Stripe with publishable key from .env
  Future<void> init() async {
    if (_initialized) {
      debugPrint('[StripeService] Already initialized, skipping');
      return;
    }

    try {
      // Validate dotenv is loaded
      if (dotenv.env.isEmpty) {
        throw Exception('dotenv.env is empty. Ensure dotenv.load() is called before Stripe.init()');
      }

      // Load publishable key from .env
      final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      
      if (publishableKey == null || publishableKey.isEmpty) {
        throw Exception('STRIPE_PUBLISHABLE_KEY is not set in .env file');
      }

      // Log masked publishable key (first 6 chars)
      final maskedKey = publishableKey.length > 6 
          ? '${publishableKey.substring(0, 6)}...' 
          : '***';
      debugPrint('[StripeService] Initializing with publishable key: $maskedKey');

      // Set Stripe publishable key
      Stripe.publishableKey = publishableKey;
      
      // Apply Stripe settings (optional but recommended)
      await Stripe.instance.applySettings();

      _initialized = true;
      debugPrint('[StripeService] Successfully initialized');
    } catch (e) {
      debugPrint('[StripeService] Initialization failed: $e');
      throw Exception('Failed to initialize Stripe: $e');
    }
  }

  /// Create a PaymentIntent by calling the backend endpoint
  /// Returns the clientSecret from the backend response
  Future<String> createPaymentIntent({
    required double amount,
    required String currency,
    required int rideId,
    required int paymentId,
  }) async {
    try {
      debugPrint('[StripeService] createPaymentIntent - amount: $amount, currency: $currency, rideId: $rideId, paymentId: $paymentId');

      // Convert amount to cents (long - Dart int is 64-bit)
      final amountInCents = (amount * 100).round();
      debugPrint('[StripeService] Amount in cents: $amountInCents');

      // Call backend endpoint
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/Stripe/create-payment-intent');
      final body = jsonEncode({
        'amount': amountInCents,
        'currency': currency.toLowerCase(),
        'rideId': rideId,
        'paymentId': paymentId,
      });

      debugPrint('[StripeService] Request URL: $uri');
      debugPrint('[StripeService] Request body: $body');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Basic bW9iaWxlOnRlc3Q=',
      };

      final response = await http.post(uri, headers: headers, body: body);

      debugPrint('[StripeService] Response status: ${response.statusCode}');
      debugPrint('[StripeService] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final clientSecret = jsonData['clientSecret'] as String?;

        if (clientSecret == null || clientSecret.isEmpty) {
          debugPrint('[StripeService] ERROR: Client secret not found in response');
          throw Exception('Client secret not found in response');
        }

        // Log clientSecret presence (not full value)
        final clientSecretPreview = clientSecret.length > 20 
            ? '${clientSecret.substring(0, 20)}...' 
            : '***';
        debugPrint('[StripeService] Client secret received: $clientSecretPreview (length: ${clientSecret.length})');

        return clientSecret;
      } else {
        final errorBody = response.body;
        debugPrint('[StripeService] ERROR: Failed to create payment intent: ${response.statusCode} - $errorBody');
        throw Exception('Failed to create payment intent: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      debugPrint('[StripeService] EXCEPTION in createPaymentIntent: $e');
      throw Exception('Error creating payment intent: $e');
    }
  }

  /// Present Stripe PaymentSheet to the user
  /// Returns PaymentResult indicating success, cancellation, or error
  Future<PaymentResult> presentPaymentSheet(String clientSecret) async {
    try {
      debugPrint('[StripeService] presentPaymentSheet called');
      debugPrint('[StripeService] Client secret length: ${clientSecret.length}');

      // Initialize PaymentSheet
      debugPrint('[StripeService] Initializing PaymentSheet...');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'TaxiMo',
        ),
      );
      debugPrint('[StripeService] PaymentSheet initialized successfully');

      // Present PaymentSheet
      debugPrint('[StripeService] Presenting PaymentSheet...');
      await Stripe.instance.presentPaymentSheet();
      debugPrint('[StripeService] PaymentSheet presented successfully - Payment successful');

      // Payment was successful
      return PaymentResult.success;
    } on StripeException catch (e) {
      // Handle Stripe-specific errors with detailed logging
      debugPrint('[StripeService] StripeException caught');
      debugPrint('[StripeService] Error code: ${e.error.code}');
      debugPrint('[StripeService] Error message: ${e.error.message}');
      debugPrint('[StripeService] Error localized message: ${e.error.localizedMessage}');
      debugPrint('[StripeService] Error type: ${e.error.type}');
      
      if (e.error.code == FailureCode.Canceled) {
        // User cancelled the payment
        debugPrint('[StripeService] User cancelled payment');
        return PaymentResult.cancelled;
      } else {
        // Other Stripe errors - distinguish between config and PaymentIntent errors
        if (e.error.code == FailureCode.Failed || 
            e.error.code == FailureCode.Unknown ||
            e.error.message?.toLowerCase().contains('payment') == true) {
          debugPrint('[StripeService] PaymentIntent error detected');
        } else {
          debugPrint('[StripeService] Stripe configuration error detected');
        }
        return PaymentResult.error;
      }
    } catch (e, stackTrace) {
      // Handle other errors with stack trace
      debugPrint('[StripeService] General exception in presentPaymentSheet: $e');
      debugPrint('[StripeService] Stack trace: $stackTrace');
      return PaymentResult.error;
    }
  }

  /// Convenience method to create payment intent and present payment sheet
  /// Returns PaymentResult indicating the outcome
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required int rideId,
    required int paymentId,
  }) async {
    try {
      debugPrint('[StripeService] processPayment called');
      debugPrint('[StripeService] Parameters: amount=$amount, currency=$currency, rideId=$rideId, paymentId=$paymentId');

      // Ensure Stripe is initialized
      debugPrint('[StripeService] Ensuring Stripe is initialized...');
      await init();

      // Create payment intent
      debugPrint('[StripeService] Creating payment intent...');
      final clientSecret = await createPaymentIntent(
        amount: amount,
        currency: currency,
        rideId: rideId,
        paymentId: paymentId,
      );

      // Present payment sheet
      debugPrint('[StripeService] Presenting payment sheet...');
      final result = await presentPaymentSheet(clientSecret);
      debugPrint('[StripeService] processPayment completed with result: $result');
      return result;
    } catch (e, stackTrace) {
      // Return error if anything fails with detailed logging
      debugPrint('[StripeService] EXCEPTION in processPayment: $e');
      debugPrint('[StripeService] Stack trace: $stackTrace');
      return PaymentResult.error;
    }
  }
}

