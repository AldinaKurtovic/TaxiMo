class ReviewDto {
  final int reviewId;
  final int rideId;
  final int riderId;
  final int driverId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  ReviewDto({
    required this.reviewId,
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
      reviewId: json['reviewId'] as int,
      rideId: json['rideId'] as int,
      riderId: json['riderId'] as int,
      driverId: json['driverId'] as int,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
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

