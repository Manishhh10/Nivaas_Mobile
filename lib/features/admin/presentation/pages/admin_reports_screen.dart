import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';

final adminReportsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.adminReports);
  final reports = response.data['data'] as List? ?? [];
  return reports.cast<Map<String, dynamic>>();
});

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  String? _processingId;
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  String _platformFilter = 'all';

  Future<void> _updateStatus(String reportId, String status) async {
    setState(() => _processingId = reportId);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        ApiEndpoints.adminReportStatus(reportId),
        data: {'status': status},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'resolved'
                  ? 'Report marked resolved'
                  : 'Report reopened',
            ),
          ),
        );
      }
      ref.invalidate(adminReportsProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update report status')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reportsAsync = ref.watch(adminReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: RefreshIndicator(
        color: primaryOrange,
        onRefresh: () async => ref.invalidate(adminReportsProvider),
        child: reportsAsync.when(
          data: (reports) {
            final filteredReports = reports.where((report) {
              final status = report['status']?.toString() ?? 'open';
              final type = report['reportType']?.toString() ?? '';
              final platform =
                  report['sourcePlatform']?.toString() ?? 'unknown';

              final statusMatch =
                  _statusFilter == 'all' || status == _statusFilter;
              final typeMatch = _typeFilter == 'all' || type == _typeFilter;
              final platformMatch =
                  _platformFilter == 'all' || platform == _platformFilter;

              return statusMatch && typeMatch && platformMatch;
            }).toList();

            if (filteredReports.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _filtersBar(),
                  ),
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.flag_outlined, size: 56, color: colorScheme.onSurfaceVariant),
                        SizedBox(height: 12),
                        Text(
                          'No reports for selected filters',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredReports.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _filtersBar(),
                  );
                }

                final report = filteredReports[i - 1];
                final reportId =
                  (report['_id'] ?? report['id'])?.toString() ?? '';
                final status = report['status']?.toString() ?? 'open';
                final isResolved = status == 'resolved';
                final createdAt = report['createdAt'] != null
                    ? DateTime.tryParse(report['createdAt'].toString())
                    : null;
                final reporter = report['reporterId'] is Map<String, dynamic>
                    ? report['reporterId'] as Map<String, dynamic>
                    : <String, dynamic>{};
                final reporterName = reporter['name']?.toString() ?? 'Unknown';
                final reporterEmail = reporter['email']?.toString() ?? '';
                final isProcessing = reportId.isNotEmpty && _processingId == reportId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              (report['reportType']?.toString() ?? 'report')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? Colors.green.withOpacity(0.12)
                                  : primaryOrange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isResolved
                                    ? Colors.green
                                    : primaryOrange,
                              ),
                            ),
                          ),
                          if ((report['sourcePlatform']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                (report['sourcePlatform']?.toString() ??
                                        'unknown')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (createdAt != null)
                            Text(
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        report['itemTitle']?.toString().isNotEmpty == true
                            ? report['itemTitle'].toString()
                            : report['location']?.toString() ??
                                  'Unknown location',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Host: ${report['hostName'] ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Location: ${report['location'] ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report['problem']?.toString() ?? 'No details provided',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reporter: $reporterName${reporterEmail.isNotEmpty ? ' ($reporterEmail)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 150,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: (isProcessing || reportId.isEmpty)
                              ? null
                              : () => _updateStatus(
                                  reportId,
                                  isResolved ? 'open' : 'resolved',
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isResolved
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                            disabledForegroundColor: colorScheme.onSurfaceVariant,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isProcessing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Updating',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isResolved
                                            ? Icons.lock_open_rounded
                                            : Icons.check_circle_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isResolved ? 'Open' : 'Resolve',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryOrange),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 10),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => ref.invalidate(adminReportsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filtersBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filters',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterMenu(
              label: 'Status',
              value: _statusFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _statusFilter = value);
              },
            ),
            _filterMenu(
              label: 'Type',
              value: _typeFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'stay', child: Text('Stay')),
                DropdownMenuItem(
                  value: 'experience',
                  child: Text('Experience'),
                ),
                DropdownMenuItem(value: 'host', child: Text('Host')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _typeFilter = value);
              },
            ),
            _filterMenu(
              label: 'Platform',
              value: _platformFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'web', child: Text('Web')),
                DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
                DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _platformFilter = value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterMenu({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withOpacity(0.45)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
          hint: Text(label),
        ),
      ),
    );
  }
}
