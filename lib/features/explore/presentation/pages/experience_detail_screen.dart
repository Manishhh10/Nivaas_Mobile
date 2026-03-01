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
import 'package:nivaas/features/explore/data/models/experience_model.dart';
import 'package:nivaas/features/explore/data/models/review_model.dart';
import 'package:nivaas/features/report/presentation/controllers/shake_report_target.dart';
import 'package:nivaas/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:nivaas/features/explore/presentation/pages/booking_screen.dart';
import 'package:nivaas/features/messages/presentation/pages/messages_screen.dart';
import 'package:nivaas/app/app.dart' show appRouteObserver;

class ExperienceDetailScreen extends ConsumerStatefulWidget {
  final String experienceId;
  const ExperienceDetailScreen({super.key, required this.experienceId});

  @override
  ConsumerState<ExperienceDetailScreen> createState() =>
      _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState
    extends ConsumerState<ExperienceDetailScreen>
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

  @override
  void didPopNext() {
    if (_pendingTarget != null) {
      ShakeReportTargetRegistry.setTarget(_pendingTarget!);
    }
  }

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
        final expId = booking['experienceId'] is Map
            ? booking['experienceId']['_id']?.toString()
            : booking['experienceId']?.toString();
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

        if (expId == widget.experienceId && isActive) {
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
    ShakeReportTargetRegistry.clearIfItem(widget.experienceId);
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

  Future<void> _submitReview(String experienceId) async {
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
          'experienceId': experienceId,
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
    String? experienceId,
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

  Future<void> _openExperienceReportDialog(Experience exp) async {
    if (_currentUserId == null) {
      _showSnackBar('Please login to report this experience', Colors.red);
      return;
    }

    ShakeReportTargetRegistry.setReportDialogOpen(true);
    bool? submitted;
    try {
      submitted = await showDialog<bool>(
        context: context,
        builder: (_) => _ExperienceReportDialog(
          experience: exp,
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
      experienceDetailProvider(widget.experienceId),
    );

    return Scaffold(
      body: detailAsync.when(
        data: (exp) {
          final isOwnerNow =
              _currentUserId != null && exp.hostUserId == _currentUserId;

          if (!isOwnerNow) {
            final target = ShakeReportTarget(
              reportType: 'experience',
              itemId: exp.id,
              itemTitle: exp.title,
              hostName: exp.hostName,
              location: exp.location,
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
              ShakeReportTargetRegistry.clearIfItem(exp.id);
            });
          }
          if (_mapLoading && _coordinates == null) {
            _geocodeLocation(exp.location);
          }
          // Check if this is the current user's listing
          if (_currentUserId != null &&
              exp.hostUserId == _currentUserId &&
              !_isMyListing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isMyListing = true);
            });
          }
          return _buildContent(exp);
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
                  experienceDetailProvider(widget.experienceId),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Experience exp) {
    final wishlist = ref.watch(wishlistProvider);
    final isLiked = wishlist.contains(exp.id);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Image carousel
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  SizedBox(
                    height: 280,
                    child: exp.images.isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.landscape,
                              size: 80,
                              color: Colors.grey,
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: exp.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentImageIndex = i),
                            itemBuilder: (_, i) => NivaasImage(
                              imagePath: exp.images[i],
                              width: double.infinity,
                              height: 280,
                            ),
                          ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 12,
                    child: _circleButton(
                      Icons.arrow_back,
                      () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 12,
                    child: _circleButton(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      () => ref.read(wishlistProvider.notifier).toggle(exp.id),
                        iconColor: isLiked
                          ? Colors.red
                          : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.9),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryOrange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        exp.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (exp.images.length > 1)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.72),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${exp.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.title,
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
                            exp.location,
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
                    const SizedBox(height: 16),

                    // Quick info row
                    Row(
                      children: [
                        _infoCard(Icons.schedule, 'Duration', exp.duration),
                        const SizedBox(width: 12),
                        _infoCard(
                          Icons.group,
                          'Max guests',
                          '${exp.maxGuests}',
                        ),
                        if (exp.yearsOfExperience > 0) ...[
                          const SizedBox(width: 12),
                          _infoCard(
                            Icons.workspace_premium,
                            'Experience',
                            '${exp.yearsOfExperience} yrs',
                          ),
                        ],
                      ],
                    ),
                    const Divider(height: 32),

                    // Host
                    _hostSection(exp),
                    if (!_isMyListing) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _openExperienceReportDialog(exp),
                          icon: const Icon(
                            Icons.flag_outlined,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Report this experience',
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
                      'About this experience',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exp.description,
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

                    // What travelers will do
                    ..._buildWhatYouWillDoSection(exp),
                    const Divider(height: 32),

                    // Available dates
                    if (exp.availableDates.isNotEmpty) ...[
                      const Text(
                        'Available dates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: exp.availableDates.map((d) {
                          final date = DateTime.tryParse(d);
                          final label = date != null
                              ? '${date.day}/${date.month}/${date.year}'
                              : d;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: primaryOrange.withOpacity(0.4),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 13,
                                color: primaryOrange,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 32),
                    ],

                    // Location map
                    _locationMapSection(exp.location),
                    const Divider(height: 32),

                    // Reviews
                    _reviewsSection(exp.id),
                    const SizedBox(height: 24),

                    // Write a review form
                    _writeReviewSection(exp.id),

                    const SizedBox(height: 160),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Bottom bar
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
                      'NPR ${exp.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                    Text(
                      'per person',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.72),
                        fontSize: 13,
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
                                itemId: exp.id,
                                itemType: 'experience',
                                itemTitle: exp.title,
                                pricePerUnit: exp.price,
                                unitLabel: 'person',
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
                        : 'Book Now',
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

  Widget _infoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryOrange, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hostSection(Experience exp) {
    final name = exp.hostName;
    final imageUrl = exp.hostImage;
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
        // Message host button
        GestureDetector(
          onTap: () => _messageHost(exp.hostUserId, exp.id, exp.hostName),
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

  Widget _itineraryItem(int step, Map<String, String> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (item['description']?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item['description']!,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.72),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (item['duration']?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.62),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['duration']!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.62),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWhatYouWillDoSection(Experience exp) {
    final normalized = _normalizedItinerary(exp);

    return [
      const Text(
        'What you\'ll do',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      ...normalized.asMap().entries.map(
        (entry) => _itineraryItem(entry.key + 1, entry.value),
      ),
    ];
  }

  List<Map<String, String>> _normalizedItinerary(Experience exp) {
    final validSteps = exp.itinerary.where((step) {
      final title = (step['title'] ?? '').trim();
      final desc = (step['description'] ?? '').trim();
      return title.isNotEmpty || desc.isNotEmpty;
    }).toList();

    if (validSteps.isNotEmpty) return validSteps;

    final cleanDescription = exp.description.trim();
    final firstSentence = cleanDescription.split(RegExp(r'[.!?]')).first.trim();

    return [
      {
        'title': 'Meet your host at ${exp.location}',
        'description': 'Your guide welcomes you, confirms the plan, and shares local tips before starting.',
        'duration': '10-15 min',
      },
      {
        'title': 'Main ${exp.category.toLowerCase()} activity',
        'description': firstSentence.isNotEmpty
            ? firstSentence
            : 'Enjoy the core hands-on experience with guidance from your host.',
        'duration': exp.duration,
      },
      {
        'title': 'Wrap-up and recommendations',
        'description': 'Finish with Q&A, photos, and recommendations for nearby spots to explore next.',
        'duration': '10-15 min',
      },
    ];
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

  Widget _writeReviewSection(String experienceId) {
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
                : () => _submitReview(experienceId),
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

  Widget _reviewsSection(String experienceId) {
    final reviewsAsync = ref.watch(reviewsProvider);

    return reviewsAsync.when(
      data: (allReviews) {
        final reviews = allReviews
            .where((r) => r.experienceId == experienceId)
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

class _ExperienceReportDialog extends StatefulWidget {
  final Experience experience;
  final void Function(String message, Color color) onSnackBar;

  const _ExperienceReportDialog({required this.experience, required this.onSnackBar});

  @override
  State<_ExperienceReportDialog> createState() => _ExperienceReportDialogState();
}

class _ExperienceReportDialogState extends State<_ExperienceReportDialog> {
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
        'reportType': 'experience',
        'hostName': widget.experience.hostName,
        'location': widget.experience.location,
        'problem': problem,
        'itemId': widget.experience.id,
        'itemTitle': widget.experience.title,
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
      title: const Text('Report this experience'),
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
