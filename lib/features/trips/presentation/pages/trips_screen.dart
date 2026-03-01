import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/trips/data/models/booking_model.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  bool _showStays = true; // true = Stays, false = Experiences
  final Set<String> _cancellingBookingIds = <String>{};

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Booking end dates are day-based; include the whole end day in active trips.
  DateTime? _inclusiveEndOfDay(String rawEndDate) {
    final parsed = DateTime.tryParse(rawEndDate);
    if (parsed == null) return null;
    return _startOfDay(parsed).add(const Duration(days: 1));
  }

  Future<void> _cancelBooking(Booking booking) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel booking?'),
          content: const Text('This booking will be marked as cancelled.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

    setState(() => _cancellingBookingIds.add(booking.id));

    try {
      final api = ref.read(apiClientProvider);
      await api.put(
        ApiEndpoints.bookingById(booking.id),
        data: {'status': 'cancelled'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
      }
      ref.invalidate(bookingsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel booking')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cancellingBookingIds.remove(booking.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Your Trips',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Manage your bookings',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.72),
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Toggle tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _tabButton(
                    context,
                    'Stays',
                    _showStays,
                    () => setState(() => _showStays = true),
                  ),
                  const SizedBox(width: 10),
                  _tabButton(
                    context,
                    'Experiences',
                    !_showStays,
                    () => setState(() => _showStays = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: RefreshIndicator(
                color: primaryOrange,
                onRefresh: () async => ref.invalidate(bookingsProvider),
                child: bookingsAsync.when(
                  data: (bookings) {
                    final filtered = bookings
                        .where((b) => _showStays ? b.isStay : b.isExperience)
                        .toList();
                    if (filtered.isEmpty) return _emptyState();
                    final todayStart = _startOfDay(DateTime.now());
                    final upcoming = filtered.where((b) {
                      final end = _inclusiveEndOfDay(b.endDate);
                      final status = b.status.toLowerCase();
                      return end != null &&
                          end.isAfter(todayStart) &&
                          status != 'cancelled' &&
                          status != 'pending';
                    }).toList();
                    final past = filtered.where((b) {
                      final end = _inclusiveEndOfDay(b.endDate);
                      final status = b.status.toLowerCase();
                      return end != null &&
                          (!end.isAfter(todayStart) ||
                              status == 'cancelled' ||
                              status == 'pending');
                    }).toList();

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (upcoming.isNotEmpty) ...[
                          _sectionHeader('Upcoming', upcoming.length),
                          ...upcoming.map((b) => _bookingCard(context, b)),
                        ],
                        if (past.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _sectionHeader('Past', past.length),
                          ...past.map(
                            (b) => _bookingCard(context, b, isPast: true),
                          ),
                        ],
                        if (upcoming.isEmpty && past.isEmpty) _emptyState(),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: primaryOrange),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: colorScheme.onSurface.withOpacity(0.45),
                        ),
                        const SizedBox(height: 12),
                        const Text('Failed to load trips'),
                        TextButton(
                          onPressed: () => ref.invalidate(bookingsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(
    BuildContext context,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryOrange : colorScheme.surface,
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : colorScheme.onSurface.withOpacity(0.75),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(
    BuildContext context,
    Booking booking, {
    bool isPast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM dd');
    final start = DateTime.tryParse(booking.startDate);
    final end = _inclusiveEndOfDay(booking.endDate);
    final todayStart = _startOfDay(DateTime.now());
    final dateStr = (start != null && end != null)
      ? '${dateFormat.format(start)} – ${dateFormat.format(end.subtract(const Duration(days: 1)))}'
        : '';
    final canCancel =
        end != null &&
      end.isAfter(todayStart) &&
        booking.status.toLowerCase() != 'cancelled' &&
        booking.status.toLowerCase() != 'completed';
    final isCancelling = _cancellingBookingIds.contains(booking.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : (isPast ? 0.03 : 0.06),
            ),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          NivaasImage(
            imagePath: booking.itemImages.isNotEmpty
                ? booking.itemImages.first
                : '',
            width: 100,
            height: 100,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.itemTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colorScheme.onSurface.withOpacity(
                        isPast ? 0.72 : 0.92,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (booking.itemLocation.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            booking.itemLocation,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.72),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.72),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'NPR ${booking.totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPast
                              ? colorScheme.onSurface.withOpacity(0.65)
                              : primaryOrange,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (canCancel) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: isCancelling
                            ? null
                            : () => _cancelBooking(booking),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.withOpacity(0.4)),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: isCancelling
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Cancel booking'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.luggage,
                size: 64,
                color: colorScheme.onSurface.withOpacity(0.35),
              ),
              const SizedBox(height: 16),
              Text(
                _showStays ? 'No stays yet' : 'No experiences yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.78),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your bookings will appear here',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.64)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
