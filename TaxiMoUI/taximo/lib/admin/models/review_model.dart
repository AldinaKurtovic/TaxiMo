class ReviewModel {
  final int reviewId;
  final int userId;
  final String userName;
  final String driverName;
  final String? description;
  final double rating;

  ReviewModel({
    required this.reviewId,
    required this.userId,
    required this.userName,
    required this.driverName,
    this.description,
    required this.rating,
  });

  int get ratingInt => rating.round().clamp(0, 5);

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      driverName: json['driverName'] as String,
      description: json['description'] as String?,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'userId': userId,
      'userName': userName,
      'driverName': driverName,
      'description': description,
      'rating': rating,
    };
  }
}

