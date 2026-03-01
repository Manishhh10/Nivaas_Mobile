import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/core/utils/geocoding_util.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/explore/data/models/accommodation_model.dart';
import 'package:nivaas/features/explore/data/models/review_model.dart';
import 'package:nivaas/features/report/presentation/controllers/shake_report_target.dart';
import 'package:nivaas/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:nivaas/features/explore/presentation/pages/booking_screen.dart';
import 'package:nivaas/features/messages/presentation/pages/messages_screen.dart';
import 'package:nivaas/app/app.dart' show appRouteObserver;

class StayDetailScreen extends ConsumerStatefulWidget {
  final String accommodationId;
  const StayDetailScreen({super.key, required this.accommodationId});

  @override
  ConsumerState<StayDetailScreen> createState() => _StayDetailScreenState();
}

class _StayDetailScreenState extends ConsumerState<StayDetailScreen>
    with RouteAware {
  static const Color primaryOrange = Color(0xFFFF6518);
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  // Map state
  LatLng? _coordinates;
  bool _mapLoading = true;

  // Review form state
  int _reviewRating = 5;
  final TextEditingController _reviewCommentController =
      TextEditingController();
  bool _reviewSubmitting = false;
  String? _currentUserId;

  // Booking / ownership state
  bool _isMyListing = false;
  bool _isReservedByMe = false;

  // Cached target so RouteAware callbacks can set/clear it.
  ShakeReportTarget? _pendingTarget;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  /// Screen became visible again (popped back to).
  @override
  void didPopNext() {
    if (_pendingTarget != null) {
      ShakeReportTargetRegistry.setTarget(_pendingTarget!);
    }
  }

  /// Another route was pushed on top — clear the target.
  @override
  void didPushNext() {
    ShakeReportTargetRegistry.clear();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final hiveService = HiveService();
    final user = await hiveService.getUser();
    if (mounted && user != null) {
      setState(() => _currentUserId = user['id'] ?? user['_id']);
      _checkBookingStatus();
    }
  }

  Future<void> _checkBookingStatus() async {
    if (_currentUserId == null) return;
    try {
      final api = ApiClient();
      final response = await api.get(ApiEndpoints.bookings);
      final bookings = (response.data['data'] as List?) ?? [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      bool hasActiveBooking = false;

      for (final booking in bookings) {
        final accId = booking['accommodationId'] is Map
            ? booking['accommodationId']['_id']?.toString()
            : booking['accommodationId']?.toString();
        final status = booking['status']?.toString().toLowerCase() ?? '';
        final endDate = DateTime.tryParse(booking['endDate']?.toString() ?? '');
        final endLocal = endDate?.toLocal();
        final endDay = endLocal != null
            ? DateTime(endLocal.year, endLocal.month, endLocal.day)
            : null;
        final isActive =
            (status == 'pending' || status == 'confirmed') &&
            endDay != null &&
            (endDay.isAtSameMomentAs(today) || endDay.isAfter(today));

        if (accId == widget.accommodationId && isActive) {
          hasActiveBooking = true;
          break;
        }
      }

      if (mounted) {
        setState(() => _isReservedByMe = hasActiveBooking);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    ShakeReportTargetRegistry.clearIfItem(widget.accommodationId);
    _pageController.dispose();
    _reviewCommentController.dispose();
    super.dispose();
  }

  Future<void> _geocodeLocation(String location) async {
    final result = await geocodeLocation(location);
    if (mounted) {
      setState(() {
        _coordinates = result != null
            ? LatLng(result.lat, result.lng)
            : LatLng(27.7172, 85.3240);
        _mapLoading = false;
      });
    }
  }

  Future<void> _submitReview(String accommodationId) async {
    if (_currentUserId == null) {
      _showSnackBar('Please login to write a review', Colors.red);
      return;
    }
    if (_reviewCommentController.text.trim().isEmpty) {
      _showSnackBar('Please write a comment', Colors.red);
      return;
    }

    setState(() => _reviewSubmitting = true);
    try {
      final api = ApiClient();
      await api.post(
        ApiEndpoints.reviews,
        data: {
          'userId': _currentUserId,
          'accommodationId': accommodationId,
          'rating': _reviewRating,
          'comment': _reviewCommentController.text.trim(),
        },
      );

      _reviewCommentController.clear();
      setState(() => _reviewRating = 5);
      ref.invalidate(reviewsProvider);
      _showSnackBar('Review submitted!', Colors.green);
    } catch (e) {
      _showSnackBar(
        'Failed to submit review: ${e.toString().replaceAll('Exception: ', '')}',
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _reviewSubmitting = false);
    }
  }

  Future<void> _messageHost(
    String? hostUserId,
    String? accommodationId,
    String hostName,
  ) async {
    if (_currentUserId == null) {
      _showSnackBar('Please login to message the host', Colors.red);
      return;
    }
    if (hostUserId == null || hostUserId.isEmpty) {
      _showSnackBar('Unable to message this host', Colors.red);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(recipientId: hostUserId, recipientName: hostName),
      ),
    );
  }

  Future<void> _openStayReportDialog(Accommodation stay) async {
    if (_currentUserId == null) {
      _showSnackBar('Please login to report this stay', Colors.red);
      return;
    }

    ShakeReportTargetRegistry.setReportDialogOpen(true);
    bool? submitted;
    try {
      submitted = await showDialog<bool>(
        context: context,
        builder: (_) => _StayReportDialog(
          stay: stay,
          onSnackBar: _showSnackBar,
        ),
      );
    } catch (_) {}

    // Delay cleanup to next frame so the dialog route fully deactivates first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShakeReportTargetRegistry.setReportDialogOpen(false);
      if (submitted == true) {
        _showSnackBar('Report submitted successfully', Colors.green);
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      accommodationDetailProvider(widget.accommodationId),
    );

    return Scaffold(
      body: detailAsync.when(
        data: (stay) {
          final isOwnerNow =
              _currentUserId != null && stay.hostUserId == _currentUserId;

          if (!isOwnerNow) {
            final target = ShakeReportTarget(
              reportType: 'stay',
              itemId: stay.id,
              itemTitle: stay.title,
              hostName: stay.hostName,
              location: stay.location,
            );
            _pendingTarget = target;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final route = ModalRoute.of(context);
              if (route == null || !route.isCurrent) return;
              ShakeReportTargetRegistry.setTarget(target);
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ShakeReportTargetRegistry.clearIfItem(stay.id);
            });
          }
          if (_mapLoading && _coordinates == null) {
            _geocodeLocation(stay.location);
          }
          // Check if this is the current user's listing
          if (_currentUserId != null &&
              stay.hostUserId == _currentUserId &&
              !_isMyListing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isMyListing = true);
            });
          }
          return _buildContent(stay);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryOrange),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load details',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              TextButton(
                onPressed: () => ref.invalidate(
                  accommodationDetailProvider(widget.accommodationId),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Accommodation stay) {
    final wishlist = ref.watch(wishlistProvider);
    final isLiked = wishlist.contains(stay.id);
    final isOwner = _currentUserId != null && stay.hostUserId == _currentUserId;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Image carousel
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  SizedBox(
                    height: 300,
                    child: stay.images.isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: stay.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentImageIndex = i),
                            itemBuilder: (_, i) => NivaasImage(
                              imagePath: stay.images[i],
                              width: double.infinity,
                              height: 300,
                            ),
                          ),
                  ),
                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 12,
                    child: _circleButton(
                      Icons.arrow_back,
                      () => Navigator.pop(context),
                    ),
                  ),
                  // Wishlist button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 12,
                    child: Row(
                      children: [
                        if (!isOwner)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _circleButton(
                              Icons.flag_outlined,
                              () => _openStayReportDialog(stay),
                              iconColor: Colors.red,
                            ),
                          ),
                        _circleButton(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          () => ref.read(wishlistProvider.notifier).toggle(stay.id),
                            iconColor: isLiked
                              ? Colors.red
                              : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.9),
                        ),
                      ],
                    ),
                  ),
                  // Page indicator
                  if (stay.images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          stay.images.length,
                          (i) => Container(
                            width: _currentImageIndex == i ? 10 : 6,
                            height: _currentImageIndex == i ? 10 : 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == i
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      stay.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.72),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            stay.location,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.72),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick stats
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _statChip(Icons.person, '${stay.maxGuests} guests'),
                        _statChip(Icons.bed, '${stay.bedrooms} bedrooms'),
                        _statChip(Icons.single_bed, '${stay.beds} beds'),
                        _statChip(
                          Icons.bathtub_outlined,
                          '${stay.bathrooms} baths',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nivaas support badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryOrange.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: primaryOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nivaas guest support included',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Booking type badge
                    if (stay.bookingType.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                            color:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              stay.bookingType == 'instant'
                                  ? Icons.bolt
                                  : Icons.schedule,
                              size: 16,
                                color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.72),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              stay.bookingType == 'instant'
                                  ? 'Instant booking'
                                  : 'Requires host approval',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 32),

                    // Host info
                    _hostSection(stay, canMessageHost: !isOwner),
                    if (!isOwner) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _openStayReportDialog(stay),
                          icon: const Icon(
                            Icons.flag_outlined,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Report this stay',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 32),

                    // Description
                    const Text(
                      'About this place',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stay.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                    const Divider(height: 32),

                    // Amenities
                    if (stay.amenities.isNotEmpty) ...[
                      const Text(
                        'Amenities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: stay.amenities
                            .map((a) => _amenityChip(a))
                            .toList(),
                      ),
                      const Divider(height: 32),
                    ],

                    // Standout amenities
                    if (stay.standoutAmenities.isNotEmpty) ...[
                      const Text(
                        'Standout amenities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: stay.standoutAmenities
                            .map((a) => _amenityChip(a, isStandout: true))
                            .toList(),
                      ),
                      const Divider(height: 32),
                    ],

                    // Safety items
                    if (stay.safetyItems.isNotEmpty) ...[
                      const Text(
                        'Safety & property',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...stay.safetyItems.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(s, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                    ],

                    // Highlights
                    if (stay.highlights.isNotEmpty) ...[
                      const Text(
                        'Highlights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...stay.highlights.map(
                        (h) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 18,
                                color: primaryOrange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  h,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                    ],

                    // Location map section
                    _locationMapSection(stay.location),
                    const Divider(height: 32),

                    // Reviews section
                    _reviewsSection(stay.id),
                    const SizedBox(height: 24),

                    // Write a review form
                    _writeReviewSection(stay.id),

                    const SizedBox(height: 160), // space for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),

        // Bottom booking bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NPR ${stay.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                    Text(
                      'per night',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.72),
                        fontSize: 13,
                      ),
                    ),
                    if (stay.weekendPrice != null &&
                        stay.weekendPrice != stay.price)
                      Text(
                        'NPR ${stay.weekendPrice!.toStringAsFixed(0)} on weekends',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.62),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: (_isMyListing || _isReservedByMe)
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingScreen(
                                itemId: stay.id,
                                itemType: 'accommodation',
                                itemTitle: stay.title,
                                pricePerUnit: stay.price,
                                unitLabel: 'night',
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMyListing
                        ? Colors.grey.shade400
                        : _isReservedByMe
                        ? Colors.green
                        : primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: _isMyListing
                        ? Colors.grey.shade400
                        : Colors.green,
                    disabledForegroundColor: Colors.white,
                  ),
                  child: Text(
                    _isMyListing
                        ? 'Your Listing'
                        : _isReservedByMe
                        ? 'Booked'
                        : 'Reserve',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ??
              Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
          size: 22,
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hostSection(Accommodation stay, {required bool canMessageHost}) {
    final name = stay.hostName;
    final imageUrl = stay.hostImage;
    final resolvedHostImage =
        (imageUrl != null && imageUrl.isNotEmpty) ? NivaasImage.fullUrl(imageUrl) : null;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: primaryOrange.withOpacity(0.15),
          backgroundImage: resolvedHostImage != null
              ? NetworkImage(resolvedHostImage)
              : null,
          child: resolvedHostImage == null
              ? Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryOrange,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hosted by $name',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.verified, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Verified host',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (canMessageHost)
          GestureDetector(
            onTap: () => _messageHost(stay.hostUserId, stay.id, stay.hostName),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: primaryOrange),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: primaryOrange),
                  const SizedBox(width: 4),
                  Text(
                    'Message',
                    style: TextStyle(
                      color: primaryOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _amenityChip(String amenity, {bool isStandout = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isStandout
            ? primaryOrange.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: isStandout
            ? Border.all(color: primaryOrange.withValues(alpha: 0.35))
            : Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Text(
        amenity,
        style: TextStyle(
          fontSize: 13,
            color: isStandout
              ? primaryOrange
              : colorScheme.onSurface,
          fontWeight: isStandout ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  // ─── Location Map ───

  Widget _locationMapSection(String location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where you\'ll be',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: _mapLoading
                ? Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: const Center(
                      child: CircularProgressIndicator(color: primaryOrange),
                    ),
                  )
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: _coordinates ?? LatLng(27.7172, 85.3240),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.nivaas.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _coordinates ?? LatLng(27.7172, 85.3240),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFFF6518),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Write Review Form ───

  Widget _writeReviewSection(String accommodationId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Write a review',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _reviewRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  i < _reviewRating ? Icons.star : Icons.star_border,
                  color: primaryOrange,
                  size: 32,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reviewCommentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Share your experience...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryOrange, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _reviewSubmitting
                ? null
                : () => _submitReview(accommodationId),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: primaryOrange.withOpacity(0.5),
            ),
            child: _reviewSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Submit Review',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _reviewsSection(String accommodationId) {
    final reviewsAsync = ref.watch(reviewsProvider);

    return reviewsAsync.when(
      data: (allReviews) {
        final reviews = allReviews
            .where((r) => r.accommodationId == accommodationId)
            .toList();
        if (reviews.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'No reviews yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
                ),
              ),
            ],
          );
        }

        final avgRating =
            reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: primaryOrange, size: 22),
                const SizedBox(width: 4),
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${reviews.length} reviews)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...reviews.take(5).map((r) => _reviewCard(r)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _reviewCard(Review review) {
    final userName = review.user?['name'] ?? 'Guest';
    final initial = userName[0].toUpperCase();
    final imageRaw =
        review.user?['image'] ??
        review.user?['avatar'] ??
        review.user?['profileImage'] ??
        review.user?['profile_picture'];

    String? rawImage;
    if (imageRaw is String && imageRaw.trim().isNotEmpty) {
      rawImage = imageRaw.trim();
    } else if (imageRaw is Map<String, dynamic>) {
      final candidate =
          imageRaw['url'] ??
          imageRaw['path'] ??
          imageRaw['image'] ??
          imageRaw['secure_url'];
      if (candidate is String && candidate.trim().isNotEmpty) {
        rawImage = candidate.trim();
      }
    }

    final imageUrl = rawImage != null ? NivaasImage.fullUrl(rawImage) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryOrange.withOpacity(0.15),
                child: ClipOval(
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarInitial(initial),
                        )
                      : _avatarInitial(initial),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ...List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 14,
                  color: i < review.rating
                      ? primaryOrange
                      : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarInitial(String initial) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: primaryOrange,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _StayReportDialog extends StatefulWidget {
  final Accommodation stay;
  final void Function(String message, Color color) onSnackBar;

  const _StayReportDialog({required this.stay, required this.onSnackBar});

  @override
  State<_StayReportDialog> createState() => _StayReportDialogState();
}

class _StayReportDialogState extends State<_StayReportDialog> {
  final _problemController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final problem = _problemController.text.trim();
    if (problem.isEmpty) {
      widget.onSnackBar('Please describe the issue', Colors.red);
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = ApiClient();
      await api.post(ApiEndpoints.reports, data: {
        'reportType': 'stay',
        'hostName': widget.stay.hostName,
        'location': widget.stay.location,
        'problem': problem,
        'itemId': widget.stay.id,
        'itemTitle': widget.stay.title,
        'sourcePlatform': 'mobile',
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _submitting = false);
      widget.onSnackBar('Failed to submit report', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report this stay'),
      content: TextField(
        controller: _problemController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Problem / inconvenience',
          hintText: 'Describe the issue',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
