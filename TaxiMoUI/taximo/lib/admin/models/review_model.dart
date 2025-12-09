class ReviewModel {
  final int reviewId;
  final int rideId;
  final int riderId;
  final int driverId;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  
  // Optional fields that might come from API if navigation properties are included
  final String? riderFirstName;
  final String? riderLastName;
  final String? driverFirstName;
  final String? driverLastName;

  ReviewModel({
    required this.reviewId,
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.riderFirstName,
    this.riderLastName,
    this.driverFirstName,
    this.driverLastName,
  });

  String get riderName {
    if (riderFirstName != null && riderLastName != null) {
      return '$riderFirstName $riderLastName';
    }
    return 'User $riderId';
  }

  String get driverName {
    if (driverFirstName != null && driverLastName != null) {
      return '$driverFirstName $driverLastName';
    }
    return 'Driver $driverId';
  }

  String get description {
    return comment ?? 'No description';
  }

  int get ratingInt => rating.round().clamp(0, 5);

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] as int,
      rideId: json['rideId'] as int,
      riderId: json['riderId'] as int,
      driverId: json['driverId'] as int,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      // Check if navigation properties are included in response
      riderFirstName: json['rider'] != null 
          ? (json['rider'] as Map<String, dynamic>)['firstName'] as String?
          : json['riderFirstName'] as String?,
      riderLastName: json['rider'] != null
          ? (json['rider'] as Map<String, dynamic>)['lastName'] as String?
          : json['riderLastName'] as String?,
      driverFirstName: json['driver'] != null
          ? (json['driver'] as Map<String, dynamic>)['firstName'] as String?
          : json['driverFirstName'] as String?,
      driverLastName: json['driver'] != null
          ? (json['driver'] as Map<String, dynamic>)['lastName'] as String?
          : json['driverLastName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'rideId': rideId,
      'riderId': riderId,
      'driverId': driverId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'reviewId': reviewId,
      'rideId': rideId,
      'riderId': riderId,
      'driverId': driverId,
      'rating': rating,
      'comment': comment,
    };
  }
}

