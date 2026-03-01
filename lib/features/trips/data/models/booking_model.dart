class Booking {
  final String id;
  final String userId;
  final String? accommodationId;
  final String? experienceId;
  final String startDate;
  final String endDate;
  final double totalPrice;
  final String status;
  final String? createdAt;
  // Populated references
  final Map<String, dynamic>? accommodation;
  final Map<String, dynamic>? experience;
  final Map<String, dynamic>? user;

  Booking({
    required this.id,
    required this.userId,
    this.accommodationId,
    this.experienceId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.status = 'pending',
    this.createdAt,
    this.accommodation,
    this.experience,
    this.user,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    String? accommodationId;
    Map<String, dynamic>? accommodation;
    if (json['accommodationId'] is Map<String, dynamic>) {
      accommodation = json['accommodationId'];
      accommodationId = accommodation?['_id']?.toString();
    } else {
      accommodationId = json['accommodationId']?.toString();
    }

    String? experienceId;
    Map<String, dynamic>? experience;
    if (json['experienceId'] is Map<String, dynamic>) {
      experience = json['experienceId'];
      experienceId = experience?['_id']?.toString();
    } else {
      experienceId = json['experienceId']?.toString();
    }

    String userId;
    Map<String, dynamic>? userMap;
    if (json['userId'] is Map<String, dynamic>) {
      userMap = json['userId'];
      userId = userMap?['_id']?.toString() ?? '';
    } else {
      userId = json['userId']?.toString() ?? '';
    }

    return Booking(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: userId,
      accommodationId: accommodationId,
      experienceId: experienceId,
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt']?.toString(),
      accommodation: accommodation,
      experience: experience,
      user: userMap,
    );
  }

  String get itemTitle {
    if (accommodation != null) return accommodation!['title'] ?? 'Stay';
    if (experience != null) return experience!['title'] ?? 'Experience';
    return 'Booking';
  }

  String get itemLocation {
    if (accommodation != null) return accommodation!['location'] ?? '';
    if (experience != null) return experience!['location'] ?? '';
    return '';
  }

  List<String> get itemImages {
    if (accommodation != null) {
      return List<String>.from(accommodation!['images'] ?? []);
    }
    if (experience != null) {
      return List<String>.from(experience!['images'] ?? []);
    }
    return [];
  }

  bool get isStay => accommodationId != null && accommodationId!.isNotEmpty;
  bool get isExperience => experienceId != null && experienceId!.isNotEmpty;
}
