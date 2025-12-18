class PromoCodeDto {
  final int promoId;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final int? usageLimit;
  final DateTime validFrom;
  final DateTime validUntil;
  final String status;
  final DateTime createdAt;

  const PromoCodeDto({
    required this.promoId,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.usageLimit,
    required this.validFrom,
    required this.validUntil,
    required this.status,
    required this.createdAt,
  });

  factory PromoCodeDto.fromJson(Map<String, dynamic> json) {
    return PromoCodeDto(
      promoId: json['promoId'] as int,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountType: json['discountType'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      usageLimit: json['usageLimit'] as int?,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isPercentage => discountType.toLowerCase() == 'percentage';
  bool get isFixed => discountType.toLowerCase() == 'fixed';
}

