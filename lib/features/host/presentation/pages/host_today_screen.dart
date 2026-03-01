import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/features/host/presentation/pages/host_dashboard_screen.dart';

class HostTodayScreen extends ConsumerStatefulWidget {
  const HostTodayScreen({super.key});

  @override
  ConsumerState<HostTodayScreen> createState() => _HostTodayScreenState();
}

class _HostTodayScreenState extends ConsumerState<HostTodayScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  bool _showToday = true;
  bool _showStays = true;

  @override
  Widget build(BuildContext context) {
    final resAsync = ref.watch(hostReservationsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryOrange,
          onRefresh: () async => ref.invalidate(hostReservationsProvider),
          child: resAsync.when(
            data: (reservations) => _buildContent(reservations),
            loading: () => const Center(
              child: CircularProgressIndicator(color: primaryOrange),
            ),
            error: (_, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Could not load reservations'),
                  TextButton(
                    onPressed: () => ref.invalidate(hostReservationsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> reservations) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);

    bool inDateWindow(Map<String, dynamic> booking) {
      final start = DateTime.tryParse(booking['startDate']?.toString() ?? '');
      final end = DateTime.tryParse(booking['endDate']?.toString() ?? '');
      if (start == null || end == null) return false;

      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);

      if (_showToday) {
        return startDay.isAtSameMomentAs(dayStart) ||
            (startDay.isBefore(dayStart) &&
                (endDay.isAtSameMomentAs(dayStart) ||
                    endDay.isAfter(dayStart)));
      }
      return startDay.isAtSameMomentAs(dayStart) || startDay.isAfter(dayStart);
    }

    bool inKind(Map<String, dynamic> booking) {
      final hasStay = booking['accommodationId'] != null;
      final hasExp = booking['experienceId'] != null;
      return _showStays ? hasStay : hasExp;
    }

    final filtered = reservations
        .where((r) => inDateWindow(r) && inKind(r))
        .toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Tab chips: Today / Upcoming
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip(
                  'Today',
                  _showToday,
                  () => setState(() => _showToday = true),
                ),
                const SizedBox(width: 10),
                _chip(
                  'Upcoming',
                  !_showToday,
                  () => setState(() => _showToday = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Kind chips: Stays / Experiences
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip(
                  'Stays',
                  _showStays,
                  () => setState(() => _showStays = true),
                ),
                const SizedBox(width: 10),
                _chip(
                  'Experiences',
                  !_showStays,
                  () => setState(() => _showStays = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _showStays
                  ? 'Your stay reservations'
                  : 'Your experience reservations',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 48,
                      color: colorScheme.onSurface.withOpacity(0.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _showStays
                          ? (_showToday
                                ? 'No stay reservations today'
                                : 'No upcoming stay reservations')
                          : (_showToday
                                ? 'No experience reservations today'
                                : 'No upcoming experience reservations'),
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.72),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((r) => _reservationCard(r)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? primaryOrange
              : colorScheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : colorScheme.onSurface.withOpacity(0.88),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _reservationCard(Map<String, dynamic> res) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = res['status']?.toString() ?? 'pending';
    final isStay = res['accommodationId'] != null;
    final item = isStay ? res['accommodationId'] : res['experienceId'];
    final title =
        (item is Map ? item['title'] : null)?.toString() ?? 'Reservation';
    final location = (item is Map ? item['location'] : null)?.toString() ?? '';
    final guestName =
        (res['userId'] is Map ? res['userId']['name'] : null)?.toString() ??
        'Guest';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = colorScheme.onSurface.withOpacity(0.7);
    }

    final startDate = DateTime.tryParse(res['startDate']?.toString() ?? '');
    final endDate = DateTime.tryParse(res['endDate']?.toString() ?? '');
    final dateStr = startDate != null && endDate != null
        ? '${_fmtDate(startDate)} - ${_fmtDate(endDate)}'
        : '';

    final guestEmail =
        (res['userId'] is Map ? res['userId']['email'] : null)?.toString() ??
        '';
    final guestCount = _extractGuestCount(res);
    final arrivalDate = startDate != null ? _fmtDate(startDate) : 'N/A';
    final departureDate = endDate != null ? _fmtDate(endDate) : 'N/A';

    return InkWell(
      onTap: () => _showReservationDetails(
        typeLabel: isStay ? 'Stay' : 'Experience',
        title: title,
        guestName: guestName,
        guestEmail: guestEmail,
        guestCount: guestCount,
        arrivalDate: arrivalDate,
        departureDate: departureDate,
        fullDateRange: dateStr,
        status: status,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withOpacity(0.24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.18
                    : 0.03,
              ),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStay ? 'Stay' : 'Experience',
                        style: const TextStyle(
                          color: primaryOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          location,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.72),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Guest: $guestName',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.72),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.62),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Tap for details',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.62),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _extractGuestCount(Map<String, dynamic> reservation) {
    final candidates = [
      reservation['guestCount'],
      reservation['guests'],
      reservation['numberOfGuests'],
      reservation['totalGuests'],
      reservation['bookingDetails'] is Map
          ? (reservation['bookingDetails'] as Map)['guestCount']
          : null,
      reservation['bookingDetails'] is Map
          ? (reservation['bookingDetails'] as Map)['guests']
          : null,
    ];

    for (final value in candidates) {
      if (value == null) continue;
      final parsed = int.tryParse(value.toString());
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return 1;
  }

  void _showReservationDetails({
    required String typeLabel,
    required String title,
    required String guestName,
    required String guestEmail,
    required int guestCount,
    required String arrivalDate,
    required String departureDate,
    required String fullDateRange,
    required String status,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$typeLabel booking details',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _detailRow('Title', title),
                _detailRow('Booked by', guestName),
                _detailRow(
                  'Guest email',
                  guestEmail.isNotEmpty ? guestEmail : 'N/A',
                ),
                _detailRow('Guests coming', guestCount.toString()),
                _detailRow('Arrival date', arrivalDate),
                _detailRow('Departure date', departureDate),
                _detailRow(
                  'Date range',
                  fullDateRange.isNotEmpty ? fullDateRange : 'N/A',
                ),
                _detailRow('Status', status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.92)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
}
