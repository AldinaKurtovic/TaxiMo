import 'package:flutter/material.dart';

class PaymentHistoryDto {
  final int paymentId;
  final int rideId;
  final int userId;
  final double amount;
  final String currency;
  final String method;
  final String status;
  final String? transactionRef;
  final DateTime? paidAt;

  PaymentHistoryDto({
    required this.paymentId,
    required this.rideId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    this.transactionRef,
    this.paidAt,
  });

  factory PaymentHistoryDto.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryDto(
      paymentId: json['paymentId'] as int,
      rideId: json['rideId'] as int,
      userId: json['userId'] as int,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      method: json['method'] as String,
      status: json['status'] as String,
      transactionRef: json['transactionRef'] as String?,
      paidAt: json['paidAt'] != null 
          ? DateTime.parse(json['paidAt'] as String) 
          : null,
    );
  }

  // Get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Get method icon
  IconData get methodIcon {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'online':
        return Icons.payment;
      default:
        return Icons.credit_card;
    }
  }
}
