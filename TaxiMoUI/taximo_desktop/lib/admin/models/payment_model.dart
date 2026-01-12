class PaymentModel {
  final int paymentId;
  final int rideId;
  final int userId;
  final double amount;
  final String currency;
  final String method;
  final String status;
  final String? transactionRef;
  final DateTime? paidAt;

  PaymentModel({
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

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['paymentId'] as int,
      rideId: json['rideId'] as int,
      userId: json['userId'] as int,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      method: json['method'] as String,
      status: json['status'] as String,
      transactionRef: json['transactionRef'] as String?,
      paidAt: json['paidAt'] != null && json['paidAt'] is String
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'rideId': rideId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': status,
      'transactionRef': transactionRef,
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}

