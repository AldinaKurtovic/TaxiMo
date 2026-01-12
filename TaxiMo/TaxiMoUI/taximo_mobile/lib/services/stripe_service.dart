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
  static final StripeService instance = StripeService._();
  
  StripeService._();

  /// Initialize Stripe with publishable key from .env
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      if (dotenv.env.isEmpty) {
        throw Exception('dotenv.env is empty');
      }

      final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      
      if (publishableKey == null || publishableKey.isEmpty) {
        throw Exception('STRIPE_PUBLISHABLE_KEY is not set in .env file');
      }

      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StripeService] Init failed: $e');
      }
      rethrow;
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
      final amountInCents = (amount * 100).round();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/Stripe/create-payment-intent');
      final body = jsonEncode({
        'amount': amountInCents,
        'currency': currency.toLowerCase(),
        'rideId': rideId,
        'paymentId': paymentId,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Basic bW9iaWxlOnRlc3Q=',
      };

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final clientSecret = jsonData['clientSecret'] as String?;

        if (clientSecret == null || clientSecret.isEmpty) {
          throw Exception('Client secret not found in response');
        }

        return clientSecret;
      } else {
        throw Exception('Failed to create payment intent: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StripeService] createPaymentIntent error: $e');
      }
      rethrow;
    }
  }

  /// Extract PaymentIntent ID from client secret
  /// Client secret format: pi_<payment_intent_id>_secret_<secret>
  String? _extractPaymentIntentId(String clientSecret) {
    try {
      final parts = clientSecret.split('_secret_');
      if (parts.isNotEmpty && parts[0].startsWith('pi_')) {
        return parts[0];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Confirm payment with backend after successful PaymentIntent confirmation
  Future<bool> confirmPayment({
    required String paymentIntentId,
    required int paymentId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/Stripe/confirm-payment-intent');
      final body = jsonEncode({
        'paymentIntentId': paymentIntentId,
        'paymentId': paymentId,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Basic bW9iaWxlOnRlc3Q=',
      };

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonData['completed'] as bool? ?? false;
      }
        return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StripeService] confirmPayment error: $e');
      }
      return false;
    }
  }

  /// Present Stripe PaymentSheet to the user
  /// Returns PaymentResult indicating success, cancellation, or error
  Future<PaymentResult> presentPaymentSheet(String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'TaxiMo',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return PaymentResult.success;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult.cancelled;
      }
      if (kDebugMode) {
        debugPrint('[StripeService] Stripe error: ${e.error.message}');
        }
        return PaymentResult.error;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StripeService] presentPaymentSheet error: $e');
      }
      return PaymentResult.error;
    }
  }

  /// Convenience method to create payment intent, present payment sheet, and confirm payment
  /// Returns PaymentResult indicating the outcome
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required int rideId,
    required int paymentId,
  }) async {
    try {
      await init();
      final clientSecret = await createPaymentIntent(
        amount: amount,
        currency: currency,
        rideId: rideId,
        paymentId: paymentId,
      );

      final paymentIntentId = _extractPaymentIntentId(clientSecret);
      if (paymentIntentId == null) {
        return PaymentResult.error;
      }

      final result = await presentPaymentSheet(clientSecret);

      if (result == PaymentResult.success) {
        await confirmPayment(
          paymentIntentId: paymentIntentId,
          paymentId: paymentId,
        );
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StripeService] processPayment error: $e');
      }
      return PaymentResult.error;
    }
  }
}

