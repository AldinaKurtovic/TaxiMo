class ReviewDto {
  final int reviewId;
  final int rideId;
  final int riderId;
  final int driverId;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  // Optional fields from ReviewResponse
  final String? userName;
  final String? userPhotoUrl;
  final String? userFirstName;
  final String? driverName;
  final String? driverPhotoUrl;
  final String? driverFirstName;

  ReviewDto({
    required this.reviewId,
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.userName,
    this.userPhotoUrl,
    this.userFirstName,
    this.driverName,
    this.driverPhotoUrl,
    this.driverFirstName,
  });

 factory ReviewDto.fromJson(Map<String, dynamic> json) {
  // Handle both ReviewDto format (with riderId) and ReviewResponse format (with userId)
  int? riderId;
  final riderIdValue = json['riderId'];
  final userIdValue = json['userId'];
  
  if (userIdValue != null) {
    riderId = userIdValue is int ? userIdValue : (userIdValue as num?)?.toInt();
  } else if (riderIdValue != null) {
    riderId = riderIdValue is int ? riderIdValue : (riderIdValue as num?)?.toInt();
  }

  // Safely extract all fields - ReviewResponse may not have rideId, driverId, createdAt
  final reviewIdValue = json['reviewId'];
  final rideIdValue = json['rideId'];
  final driverIdValue = json['driverId'];
  final ratingValue = json['rating'];
  final createdAtValue = json['createdAt'];

  return ReviewDto(
    reviewId: reviewIdValue is int 
        ? reviewIdValue 
        : (reviewIdValue is num ? reviewIdValue.toInt() : 0),
    rideId: rideIdValue is int 
        ? rideIdValue 
        : (rideIdValue is num ? rideIdValue.toInt() : 0), // Default to 0 if missing
    riderId: riderId ?? 0,
    driverId: driverIdValue is int 
        ? driverIdValue 
        : (driverIdValue is num ? driverIdValue.toInt() : 0), // Default to 0 if missing
    rating: ratingValue is double 
        ? ratingValue 
        : (ratingValue is int 
            ? ratingValue.toDouble() 
            : (ratingValue is num ? ratingValue.toDouble() : 0.0)),
    comment: json['comment'] as String? ?? json['description'] as String?,
    createdAt: createdAtValue != null
        ? (createdAtValue is String 
            ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
            : DateTime.now())
        : DateTime.now(), // Default to now if missing
    userName: json['userName'] as String?,
    userPhotoUrl: json['userPhotoUrl'] as String?,
    userFirstName: json['userFirstName'] as String?,
    driverName: json['driverName'] as String?,
    driverPhotoUrl: json['driverPhotoUrl'] as String?,
    driverFirstName: json['driverFirstName'] as String?,
  );
}
}

class ReviewCreateDto {
  final int rideId;
  final int riderId;
  final int driverId;
  final double rating;
  final String? comment;

  ReviewCreateDto({
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'riderId': riderId,
      'driverId': driverId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}

