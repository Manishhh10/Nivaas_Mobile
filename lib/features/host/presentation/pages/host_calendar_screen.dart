import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/features/host/presentation/pages/host_dashboard_screen.dart';

class HostCalendarScreen extends ConsumerStatefulWidget {
  const HostCalendarScreen({super.key});

  @override
  ConsumerState<HostCalendarScreen> createState() => _HostCalendarScreenState();
}

class _HostCalendarScreenState extends ConsumerState<HostCalendarScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  static const Color stayColor = Color(0xFF10B981);
  static const Color experienceColor = Color(0xFFF59E0B);
  static const Color bothColor = Color(0xFF8B5CF6);

  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  DateTime _toDay(DateTime value) => DateTime(value.year, value.month, value.day);

  bool _isStayReservation(Map<String, dynamic> reservation) => reservation['accommodationId'] != null;

  Map<DateTime, List<Map<String, dynamic>>> _buildEvents(List<Map<String, dynamic>> reservations) {
    final events = <DateTime, List<Map<String, dynamic>>>{};
    for (final r in reservations) {
      final start = DateTime.tryParse(r['startDate']?.toString() ?? '');
      final end = DateTime.tryParse(r['endDate']?.toString() ?? '');
      if (start == null || end == null) continue;
      var d = _toDay(start);
      final endDay = _toDay(end);
      while (!d.isAfter(endDay)) {
        events.putIfAbsent(d, () => []).add(r);
        d = d.add(const Duration(days: 1));
      }
    }
    return events;
  }

  ({bool hasStay, bool hasExperience}) _eventKindsForDay(List<Map<String, dynamic>> dayEvents) {
    var hasStay = false;
    var hasExperience = false;

    for (final reservation in dayEvents) {
      if (_isStayReservation(reservation)) {
        hasStay = true;
      } else {
        hasExperience = true;
      }

      if (hasStay && hasExperience) break;
    }

    return (hasStay: hasStay, hasExperience: hasExperience);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resAsync = ref.watch(hostReservationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Calendar',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            resAsync.when(
              data: (reservations) {
                final events = _buildEvents(reservations);
                final totalStayReservations = reservations.where(_isStayReservation).length;
                final totalExperienceReservations = reservations.length - totalStayReservations;

                final selectedEvents = _selectedDay != null
                    ? events[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? []
                    : <Map<String, dynamic>>[];

                return Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                title: 'Stay reservations',
                                count: totalStayReservations,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _summaryCard(
                                title: 'Experience reservations',
                                count: totalExperienceReservations,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _calendarHeader(),
                      _calendarGrid(events),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _legendChip('Stay booked', stayColor),
                            _legendChip('Experience booked', experienceColor),
                            _legendChip('Both booked', bothColor),
                            _legendChip('Selected day', primaryOrange),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: selectedEvents.isEmpty
                            ? Center(
                                child: Text(
                                  _selectedDay != null
                                      ? 'No reservations on this day'
                                      : 'Select a date to view reservations',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(0.66),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: selectedEvents.length,
                                itemBuilder: (_, i) =>
                                    _calendarResCard(selectedEvents[i]),
                              ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Expanded(
                child: Center(
                    child: CircularProgressIndicator(color: primaryOrange)),
              ),
              error: (_, _) => Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Could not load calendar data'),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(hostReservationsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarHeader() {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
              });
            },
          ),
          Text(
            '${months[_focusedMonth.month]} ${_focusedMonth.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _calendarGrid(Map<DateTime, List<Map<String, dynamic>>> events) {
    final colorScheme = Theme.of(context).colorScheme;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;
    final today = DateTime.now();
    final todayKey = _toDay(today);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.62))),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          ...List.generate(6, (week) {
            return Row(
              children: List.generate(7, (weekday) {
                final dayIndex = week * 7 + weekday - firstWeekday + 1;
                if (dayIndex < 1 || dayIndex > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 42));
                }
                final dayKey = DateTime(_focusedMonth.year, _focusedMonth.month, dayIndex);
                final dayEvents = events[dayKey] ?? const <Map<String, dynamic>>[];
                final hasEvents = dayEvents.isNotEmpty;
                final kinds = _eventKindsForDay(dayEvents);
                final isSelected = _selectedDay != null &&
                    _selectedDay!.year == dayKey.year &&
                    _selectedDay!.month == dayKey.month &&
                    _selectedDay!.day == dayKey.day;
                final isToday = dayKey == todayKey;

                final hasStay = kinds.hasStay;
                final hasExperience = kinds.hasExperience;
                final hasBoth = hasStay && hasExperience;

                final Color? dayBackgroundColor = hasBoth
                    ? bothColor.withValues(alpha: 0.14)
                    : hasStay
                        ? stayColor.withValues(alpha: 0.16)
                        : hasExperience
                            ? experienceColor.withValues(alpha: 0.18)
                            : isToday
                                ? primaryOrange.withValues(alpha: 0.12)
                                : null;

                final Color dayTextColor = hasBoth
                    ? const Color(0xFF5B21B6)
                    : hasStay
                        ? const Color(0xFF065F46)
                        : hasExperience
                            ? const Color(0xFF92400E)
                            : isToday
                                ? primaryOrange
                              : colorScheme.onSurface.withOpacity(0.9);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = dayKey),
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: dayBackgroundColor,
                        border: isSelected
                            ? Border.all(color: primaryOrange, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayIndex',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                              color: dayTextColor,
                            ),
                          ),
                          if (hasEvents)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: hasBoth
                                    ? bothColor
                                    : hasStay
                                        ? stayColor
                                        : experienceColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _calendarResCard(Map<String, dynamic> res) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = res['status']?.toString() ?? 'pending';
    final isStay = res['accommodationId'] != null;
    final typeColor = isStay ? stayColor : experienceColor;
    final typeLabel = isStay ? 'Stay' : 'Experience';
    final item = isStay ? res['accommodationId'] : res['experienceId'];
    final title = (item is Map ? item['title'] : null)?.toString() ?? 'Reservation';
    final guest = (res['userId'] is Map ? res['userId']['name'] : null)?.toString() ?? 'Guest';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isStay ? Icons.home : Icons.landscape, color: typeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeLabel,
                    style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Guest: $guest',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.72),
                      fontSize: 12,
                    )),
              ],
            ),
          ),
          Text(status[0].toUpperCase() + status.substring(1),
              style: TextStyle(
                  color: status == 'cancelled'
                      ? Colors.red
                      : status == 'confirmed'
                          ? Colors.green
                          : Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _summaryCard({required String title, required int count}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _legendChip(String label, Color dotColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
