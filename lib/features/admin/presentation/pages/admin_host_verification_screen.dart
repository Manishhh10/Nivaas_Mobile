import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/services/connectivity/connectivity_service.dart';
import 'package:nivaas/features/admin/data/services/admin_offline_service.dart';

/// Provider that fetches hosts — online from API (and caches), offline from Hive.
final adminHostsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final offlineService = ref.read(adminOfflineServiceProvider);
  await offlineService.init();

  final connectivity = ConnectivityService();
  final isOnline = await connectivity.isConnected();

  if (isOnline) {
    try {
      // Try syncing any pending offline actions first.
      final synced = await offlineService.syncPendingActions(api);
      if (synced > 0) {
        debugPrint('Admin: synced $synced pending offline actions');
      }

      final response = await api.get(ApiEndpoints.adminHosts);
      final hosts = (response.data['hosts'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      // Cache for offline use.
      await offlineService.cacheHosts(hosts);
      return hosts;
    } catch (_) {
      // Network looked connected but request failed — use cache.
      return offlineService.getCachedHosts();
    }
  }

  // Offline — return cached data.
  return offlineService.getCachedHosts();
});

final adminOfflineServiceProvider = Provider<AdminOfflineService>((ref) {
  return AdminOfflineService();
});

class AdminHostVerificationScreen extends ConsumerStatefulWidget {
  const AdminHostVerificationScreen({super.key});

  @override
  ConsumerState<AdminHostVerificationScreen> createState() =>
      _AdminHostVerificationScreenState();
}

class _AdminHostVerificationScreenState
    extends ConsumerState<AdminHostVerificationScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  static final String baseUrl = ApiClient.baseUrl;

  String? _processingId; // currently approving / rejecting
  String _statusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  final ConnectivityService _connectivity = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (mounted && _isOffline != !online) {
        setState(() => _isOffline = !online);
        if (online) {
          // Back online — sync and refresh.
          ref.invalidate(adminHostsProvider);
        }
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await _connectivity.isConnected();
    if (mounted) setState(() => _isOffline = !online);
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _docUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Replace the /api suffix with the file path
    final origin = baseUrl.replaceAll('/api', '');
    return '$origin${path.startsWith('/') ? '' : '/'}$path';
  }

  String _hostStatus(Map<String, dynamic> host) {
    return (host['verificationStatus']?.toString().toLowerCase() ?? 'pending')
        .trim();
  }

  bool _matchesSearch(Map<String, dynamic> host, String query) {
    if (query.isEmpty) return true;

    final user = host['userId'];
    final userName =
        user is Map<String, dynamic> ? (user['name']?.toString() ?? '') : '';
    final userEmail =
        user is Map<String, dynamic> ? (user['email']?.toString() ?? '') : '';
    final userPhone = user is Map<String, dynamic>
        ? (user['phoneNumber']?.toString() ?? '')
        : '';

    final haystack = [
      userName,
      userEmail,
      userPhone,
      host['legalName']?.toString() ?? '',
      host['phoneNumber']?.toString() ?? '',
      host['address']?.toString() ?? '',
      host['governmentId']?.toString() ?? '',
    ].join(' ').toLowerCase();

    return haystack.contains(query.toLowerCase());
  }

  Widget _statusFilters(List<Map<String, dynamic>> hosts) {
    final colorScheme = Theme.of(context).colorScheme;
    final pendingCount =
        hosts.where((h) => _hostStatus(h) == 'pending').length;
    final approvedCount =
        hosts.where((h) => _hostStatus(h) == 'verified').length;
    final rejectedCount =
        hosts.where((h) => _hostStatus(h) == 'rejected').length;

    Widget chip(String key, String label, int count, Color activeColor) {
      final selected = _statusFilter == key;
      return ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = key),
        selectedColor: activeColor,
        labelStyle: TextStyle(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: colorScheme.surfaceContainerLow,
        side: BorderSide(color: colorScheme.outline.withOpacity(0.45)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('all', 'All', hosts.length, primaryOrange),
        chip('pending', 'Pending', pendingCount, const Color(0xFFEA580C)),
        chip('verified', 'Approved', approvedCount, const Color(0xFF15803D)),
        chip('rejected', 'Rejected', rejectedCount, const Color(0xFFB91C1C)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hostsAsync = ref.watch(adminHostsProvider);
    final offlineService = ref.read(adminOfflineServiceProvider);
    final pendingCount = offlineService.pendingActionCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Host Verification',
            style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: '$pendingCount action(s) waiting to sync',
                child: Badge(
                  label: Text('$pendingCount'),
                  child: Icon(Icons.cloud_upload_outlined,
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, size: 18, color: Color(0xFF92400E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pendingCount > 0
                          ? 'Offline mode · $pendingCount action(s) will sync when online'
                          : 'Offline mode · Showing cached data',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: primaryOrange,
              onRefresh: () async => ref.invalidate(adminHostsProvider),
              child: hostsAsync.when(
                data: (hosts) => _buildHostList(hosts),
                loading: () => const Center(
                    child: CircularProgressIndicator(color: primaryOrange)),
                error: (e, _) => _buildError(e, colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object e, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text('Error: ${e.toString().replaceAll('Exception: ', '')}',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(adminHostsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHostList(List<Map<String, dynamic>> hosts) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredHosts = hosts.where((host) {
      final status = _hostStatus(host);
      final statusMatch = _statusFilter == 'all' || status == _statusFilter;
      final searchMatch = _matchesSearch(host, _searchQuery);
      return statusMatch && searchMatch;
    }).toList();

    if (hosts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 160),
          Center(
            child: Column(
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 56, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                const Text('No host applications found',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                    _isOffline
                        ? 'Connect to the internet to fetch applications'
                        : 'Host applications will appear here',
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 14)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value.trim());
          },
          decoration: InputDecoration(
            hintText: 'Search hosts by name, email, address or ID',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.close),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: colorScheme.outline.withOpacity(0.45)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _statusFilters(hosts),
        const SizedBox(height: 12),
        if (filteredHosts.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: colorScheme.outline.withOpacity(0.35)),
            ),
            child: const Text(
              'No applications match your filters.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ...filteredHosts.map(_hostCard),
      ],
    );
  }

  Widget _hostCard(Map<String, dynamic> host) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = host['userId'];
    final String name;
    final String email;
    final String phone;
    if (user is Map<String, dynamic>) {
      name = user['name'] ?? '—';
      email = user['email'] ?? '—';
      phone = user['phoneNumber'] ?? '—';
    } else {
      name = '—';
      email = '—';
      phone = '—';
    }

    final legalName = host['legalName'] ?? '—';
    final hostPhone = host['phoneNumber'] ?? '—';
    final address = host['address'] ?? '—';
    final govId = host['governmentId'] ?? '—';
    final idDocPath = host['idDocument'] as String?;
    final docUrl = _docUrl(idDocPath);
    final hostId = host['_id'] as String? ?? '';
    final status = _hostStatus(host);
    final isVerified = status == 'verified';
    final isRejected = status == 'rejected';
    final createdAt = host['createdAt'] != null
        ? DateTime.tryParse(host['createdAt'].toString())
        : null;

    final isProcessing = _processingId == hostId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withOpacity(0.12), blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - user info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryOrange.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(email,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? const Color(0x2215803D)
                              : isRejected
                                  ? const Color(0x22B91C1C)
                                  : primaryOrange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isVerified
                              ? 'APPROVED'
                              : isRejected
                                  ? 'REJECTED'
                                  : 'PENDING',
                          style: TextStyle(
                            fontSize: 11,
                            color: isVerified
                                ? const Color(0xFF15803D)
                                : isRejected
                                    ? const Color(0xFFB91C1C)
                                    : primaryOrange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          Divider(height: 24, color: colorScheme.outline.withOpacity(0.3)),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _detailRow('Legal Name', legalName),
                _detailRow('Phone (account)', phone),
                _detailRow('Phone (host)', hostPhone),
                _detailRow('Address', address),
                _detailRow('Government ID', govId),
              ],
            ),
          ),

          // ID Document image
          if (docUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID Document',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      docUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('Could not load document',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.outline.withOpacity(0.35), style: BorderStyle.solid),
                ),
                    child: Center(
                  child: Text('No ID document uploaded',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!isVerified)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (isProcessing || hostId.isEmpty)
                                  ? null
                                  : () => _approve(hostId),
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    if (!isVerified && !isRejected) const SizedBox(width: 10),
                    if (!isRejected)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : hostId.isEmpty
                                  ? null
                              : () => _showRejectDialog(hostId),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB91C1C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),
                if (isRejected && (host['rejectionReason']?.toString().isNotEmpty == true))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Reason: ${host['rejectionReason']}',
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(String hostId) async {
    setState(() => _processingId = hostId);
    try {
      if (_isOffline) {
        final offlineService = ref.read(adminOfflineServiceProvider);
        await offlineService.queueApprove(hostId);
        ref.invalidate(adminHostsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Approval queued — will sync when online'),
                backgroundColor: Color(0xFF92400E)),
          );
        }
      } else {
        final api = ref.read(apiClientProvider);
        await api.post(ApiEndpoints.adminApproveHost(hostId));
        ref.invalidate(adminHostsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Host application approved!'),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  void _showRejectDialog(String hostId) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for rejection.',
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Invalid government ID',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: primaryOrange, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reject(hostId, reasonCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _reject(String hostId, String reason) async {
    final effectiveReason = reason.isNotEmpty ? reason : 'No reason provided';
    setState(() => _processingId = hostId);
    try {
      if (_isOffline) {
        final offlineService = ref.read(adminOfflineServiceProvider);
        await offlineService.queueReject(hostId, effectiveReason);
        ref.invalidate(adminHostsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Rejection queued — will sync when online'),
                backgroundColor: Color(0xFF92400E)),
          );
        }
      } else {
        final api = ref.read(apiClientProvider);
        await api.post(ApiEndpoints.adminRejectHost(hostId), data: {
          'reason': effectiveReason,
        });
        ref.invalidate(adminHostsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Host application rejected'),
                backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }
}
