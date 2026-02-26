class Review {
  final int id;
  final int userId;
  final String username;
  final int productId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.username,
    required this.productId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String? ?? '',
      productId: json['productId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ProductReviewSummary {
  final int productId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final List<Review> reviews;

  ProductReviewSummary({
    required this.productId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.reviews,
  });

  factory ProductReviewSummary.fromJson(Map<String, dynamic> json) {
    final dist = json['ratingDistribution'] as Map<String, dynamic>? ?? {};
    return ProductReviewSummary(
      productId: json['productId'] as int,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      ratingDistribution: dist.map((k, v) => MapEntry(int.parse(k), v as int)),
      reviews: (json['reviews'] as List?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
