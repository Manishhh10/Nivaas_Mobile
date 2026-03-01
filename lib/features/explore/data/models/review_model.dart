class Review {
  final String id;
  final String userId;
  final String? accommodationId;
  final String? experienceId;
  final int rating;
  final String comment;
  final String? createdAt;
  final Map<String, dynamic>? user;

  Review({
    required this.id,
    required this.userId,
    this.accommodationId,
    this.experienceId,
    required this.rating,
    this.comment = '',
    this.createdAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String userId;
    Map<String, dynamic>? userMap;
    if (json['userId'] is Map<String, dynamic>) {
      userMap = json['userId'];
      userId = userMap?['_id']?.toString() ?? '';
    } else {
      userId = json['userId']?.toString() ?? '';
    }

    // Handle populated accommodationId (object with _id) vs plain string
    String? accommodationId;
    if (json['accommodationId'] is Map<String, dynamic>) {
      accommodationId = (json['accommodationId'] as Map<String, dynamic>)['_id']?.toString();
    } else {
      accommodationId = json['accommodationId']?.toString();
    }

    // Handle populated experienceId (object with _id) vs plain string
    String? experienceId;
    if (json['experienceId'] is Map<String, dynamic>) {
      experienceId = (json['experienceId'] as Map<String, dynamic>)['_id']?.toString();
    } else {
      experienceId = json['experienceId']?.toString();
    }

    return Review(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: userId,
      accommodationId: accommodationId,
      experienceId: experienceId,
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt']?.toString(),
      user: userMap,
    );
  }
}
