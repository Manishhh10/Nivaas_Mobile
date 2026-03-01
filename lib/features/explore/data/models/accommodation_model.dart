class Accommodation {
  final String id;
  final String hostId;
  final String title;
  final String location;
  final double price;
  final double? weekendPrice;
  final double? weekendPremium;
  final String description;
  final List<String> highlights;
  final List<String> amenities;
  final List<String> standoutAmenities;
  final List<String> safetyItems;
  final List<String> images;
  final int maxGuests;
  final int bedrooms;
  final int beds;
  final int bathrooms;
  final String bookingType;
  final Map<String, String>? residentialAddress;
  final bool isPublished;
  final String? createdAt;
  // Populated host data
  final Map<String, dynamic>? hostProfile;

  /// Resolved host display name from populated data
  String get hostName {
    if (hostProfile == null) return 'Host';
    // Try userId.name first (populated user document)
    final userId = hostProfile!['userId'];
    if (userId is Map<String, dynamic> && userId['name'] != null) {
      return userId['name'].toString();
    }
    // Fall back to legalName from host profile
    if (hostProfile!['legalName'] != null && hostProfile!['legalName'].toString().trim().isNotEmpty) {
      return hostProfile!['legalName'].toString();
    }
    // Fall back to direct name field
    if (hostProfile!['name'] != null) {
      return hostProfile!['name'].toString();
    }
    return 'Host';
  }

  /// Resolved host profile image URL from populated data
  String? get hostImage {
    if (hostProfile == null) return null;
    final userId = hostProfile!['userId'];
    if (userId is Map<String, dynamic> && userId['image'] != null) {
      return userId['image'].toString();
    }
    return null;
  }

  /// The host's User document _id (needed for messaging recipientId)
  String? get hostUserId {
    if (hostProfile == null) return null;
    final userId = hostProfile!['userId'];
    if (userId is Map<String, dynamic>) {
      return userId['_id']?.toString();
    }
    return null;
  }

  Accommodation({
    required this.id,
    required this.hostId,
    required this.title,
    required this.location,
    required this.price,
    this.weekendPrice,
    this.weekendPremium,
    this.description = '',
    this.highlights = const [],
    this.amenities = const [],
    this.standoutAmenities = const [],
    this.safetyItems = const [],
    this.images = const [],
    required this.maxGuests,
    required this.bedrooms,
    required this.beds,
    required this.bathrooms,
    this.bookingType = 'instant',
    this.residentialAddress,
    this.isPublished = false,
    this.createdAt,
    this.hostProfile,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    final hostId = json['hostId'];
    String hostIdStr = '';
    Map<String, dynamic>? hostProfile;

    if (hostId is Map<String, dynamic>) {
      hostIdStr = hostId['_id']?.toString() ?? '';
      hostProfile = hostId;
    } else {
      hostIdStr = hostId?.toString() ?? '';
    }

    return Accommodation(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      hostId: hostIdStr,
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      weekendPrice: json['weekendPrice']?.toDouble(),
      weekendPremium: json['weekendPremium']?.toDouble(),
      description: json['description'] ?? '',
      highlights: List<String>.from(json['highlights'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      standoutAmenities: List<String>.from(json['standoutAmenities'] ?? []),
      safetyItems: List<String>.from(json['safetyItems'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      maxGuests: json['maxGuests'] ?? 1,
      bedrooms: json['bedrooms'] ?? 1,
      beds: json['beds'] ?? 1,
      bathrooms: json['bathrooms'] ?? 1,
      bookingType: json['bookingType'] ?? 'instant',
      residentialAddress: json['residentialAddress'] != null
          ? Map<String, String>.from(
              (json['residentialAddress'] as Map).map(
                (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
              ),
            )
          : null,
      isPublished: json['isPublished'] ?? false,
      createdAt: json['createdAt']?.toString(),
      hostProfile: hostProfile,
    );
  }

  String get firstImage {
    if (images.isEmpty) return '';
    return images.first;
  }
}
