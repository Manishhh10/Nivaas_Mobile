import 'package:hive/hive.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/constants/hive_table_constant.dart';
import 'package:nivaas/core/services/connectivity/connectivity_service.dart';
import 'package:nivaas/features/admin/data/models/admin_host_hive_model.dart';

class AdminOfflineService {
  late Box<AdminHostHiveModel> _hostsBox;
  late Box<AdminPendingAction> _actionsBox;
  final ConnectivityService _connectivity = ConnectivityService();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (!Hive.isAdapterRegistered(HiveTableConstant.adminHostTypeId)) {
      Hive.registerAdapter(AdminHostHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTableConstant.adminActionTypeId)) {
      Hive.registerAdapter(AdminPendingActionAdapter());
    }
    _hostsBox = await Hive.openBox<AdminHostHiveModel>(
        HiveTableConstant.adminHostsBox);
    _actionsBox = await Hive.openBox<AdminPendingAction>(
        HiveTableConstant.adminActionsBox);
    _initialized = true;
  }

  // ── Cache operations ──────────────────────────────────────────────────

  /// Save hosts fetched from API into local cache.
  Future<void> cacheHosts(List<Map<String, dynamic>> hosts) async {
    await init();
    await _hostsBox.clear();
    for (final host in hosts) {
      final model = AdminHostHiveModel.fromApiMap(host);
      await _hostsBox.put(model.id, model);
    }
  }

  /// Get cached hosts as the Map format the screen expects.
  Future<List<Map<String, dynamic>>> getCachedHosts() async {
    await init();
    // Apply any pending offline actions on top of cached data.
    final actions = _actionsBox.values.toList();
    final hosts = <String, AdminHostHiveModel>{};
    for (final h in _hostsBox.values) {
      hosts[h.id] = h;
    }

    for (final action in actions) {
      final existing = hosts[action.hostId];
      if (existing != null) {
        hosts[action.hostId] = AdminHostHiveModel(
          id: existing.id,
          userName: existing.userName,
          userEmail: existing.userEmail,
          userPhone: existing.userPhone,
          legalName: existing.legalName,
          hostPhone: existing.hostPhone,
          address: existing.address,
          governmentId: existing.governmentId,
          idDocument: existing.idDocument,
          verificationStatus:
              action.action == 'approve' ? 'verified' : 'rejected',
          rejectionReason:
              action.action == 'reject' ? action.reason : existing.rejectionReason,
          createdAt: existing.createdAt,
          cachedAt: existing.cachedAt,
        );
      }
    }

    return hosts.values.map((h) => h.toApiMap()).toList();
  }

  bool get hasCachedData {
    if (!_initialized) return false;
    return _hostsBox.isNotEmpty;
  }

  // ── Offline action queue ──────────────────────────────────────────────

  Future<void> queueApprove(String hostId) async {
    await init();
    // Remove any previous action for this host.
    await _removeExistingAction(hostId);
    await _actionsBox.add(AdminPendingAction(
      hostId: hostId,
      action: 'approve',
      reason: '',
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<void> queueReject(String hostId, String reason) async {
    await init();
    await _removeExistingAction(hostId);
    await _actionsBox.add(AdminPendingAction(
      hostId: hostId,
      action: 'reject',
      reason: reason.isNotEmpty ? reason : 'No reason provided',
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  int get pendingActionCount => _initialized ? _actionsBox.length : 0;

  List<AdminPendingAction> get pendingActions =>
      _initialized ? _actionsBox.values.toList() : [];

  Future<void> _removeExistingAction(String hostId) async {
    final keysToRemove = <dynamic>[];
    for (final key in _actionsBox.keys) {
      final action = _actionsBox.get(key);
      if (action != null && action.hostId == hostId) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      await _actionsBox.delete(key);
    }
  }

  // ── Sync pending actions when back online ─────────────────────────────

  /// Returns the number of successfully synced actions.
  Future<int> syncPendingActions(ApiClient api) async {
    await init();
    if (_actionsBox.isEmpty) return 0;

    final isOnline = await _connectivity.isConnected();
    if (!isOnline) return 0;

    int synced = 0;
    final keys = _actionsBox.keys.toList();

    for (final key in keys) {
      final action = _actionsBox.get(key);
      if (action == null) continue;

      try {
        if (action.action == 'approve') {
          await api.post(ApiEndpoints.adminApproveHost(action.hostId));
        } else {
          await api.post(
            ApiEndpoints.adminRejectHost(action.hostId),
            data: {'reason': action.reason},
          );
        }
        await _actionsBox.delete(key);
        synced++;
      } catch (_) {
        // If a single action fails, continue with the rest.
      }
    }

    return synced;
  }
}
