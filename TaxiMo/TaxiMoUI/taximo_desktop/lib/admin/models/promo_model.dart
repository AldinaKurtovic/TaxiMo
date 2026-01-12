class PromoModel {
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

  PromoModel({
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

  bool get isActive => status.toLowerCase() == 'active';

  String get discountDisplay {
    if (discountType.toLowerCase() == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}%';
    } else {
      return r'$' + discountValue.toStringAsFixed(2);
    }
  }

  String get periodDisplay {
    final from = '${validFrom.month.toString().padLeft(2, '0')}/${validFrom.day.toString().padLeft(2, '0')}/${validFrom.year}';
    final until = '${validUntil.month.toString().padLeft(2, '0')}/${validUntil.day.toString().padLeft(2, '0')}/${validUntil.year}';
    return '$from - $until';
  }

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      promoId: json['promoId'] as int,
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      discountType: json['discountType'] as String? ?? '',
      discountValue: (json['discountValue'] as num).toDouble(),
      usageLimit: json['usageLimit'] as int?,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      status: json['status'] as String? ?? 'Inactive',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promoId': promoId,
      'code': code,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'usageLimit': usageLimit,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'code': code,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'usageLimit': usageLimit,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'status': status,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'promoId': promoId,
      'code': code,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'usageLimit': usageLimit,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'status': status,
    };
  }
}

