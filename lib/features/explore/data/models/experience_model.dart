class Experience {
  final String id;
  final String hostId;
  final String title;
  final String category;
  final double price;
  final String description;
  final String location;
  final List<String> images;
  final String duration;
  final int yearsOfExperience;
  final int maxGuests;
  final List<Map<String, String>> itinerary;
  final List<String> availableDates;
  final Map<String, String>? residentialAddress;
  final bool isPublished;
  final String? createdAt;
  final Map<String, dynamic>? hostProfile;

  /// Resolved host display name from populated data
  String get hostName {
    if (hostProfile == null) return 'Host';
    final userId = hostProfile!['userId'];
    if (userId is Map<String, dynamic> && userId['name'] != null) {
      return userId['name'].toString();
    }
    if (hostProfile!['legalName'] != null && hostProfile!['legalName'].toString().trim().isNotEmpty) {
      return hostProfile!['legalName'].toString();
    }
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

  Experience({
    required this.id,
    required this.hostId,
    required this.title,
    required this.category,
    required this.price,
    this.description = '',
    required this.location,
    this.images = const [],
    required this.duration,
    this.yearsOfExperience = 0,
    this.maxGuests = 1,
    this.itinerary = const [],
    this.availableDates = const [],
    this.residentialAddress,
    this.isPublished = false,
    this.createdAt,
    this.hostProfile,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    final hostId = json['hostId'];
    String hostIdStr = '';
    Map<String, dynamic>? hostProfile;

    if (hostId is Map<String, dynamic>) {
      hostIdStr = hostId['_id']?.toString() ?? '';
      hostProfile = hostId;
    } else {
      hostIdStr = hostId?.toString() ?? '';
    }

    List<Map<String, String>> itinerary = [];
    if (json['itinerary'] != null) {
      for (var item in json['itinerary']) {
        if (item is Map) {
          final title =
              item['title']?.toString() ??
              item['activityTitle']?.toString() ??
              item['activity']?.toString() ??
              item['name']?.toString() ??
              '';
          final description =
              item['description']?.toString() ??
              item['details']?.toString() ??
              item['summary']?.toString() ??
              '';
          final duration =
              item['duration']?.toString() ??
              item['time']?.toString() ??
              item['length']?.toString() ??
              '';

          itinerary.add({
            'title': title,
            'description': description,
            'duration': duration,
          });
        } else if (item is String && item.trim().isNotEmpty) {
          itinerary.add({
            'title': item.trim(),
            'description': '',
            'duration': '',
          });
        }
      }
    }

    return Experience(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      hostId: hostIdStr,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      duration: json['duration'] ?? '',
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      maxGuests: json['maxGuests'] ?? 1,
      itinerary: itinerary,
      availableDates: List<String>.from(
        (json['availableDates'] ?? []).map((d) => d.toString()),
      ),
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
