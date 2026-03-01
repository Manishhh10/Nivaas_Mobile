import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/features/report/presentation/controllers/shake_report_target.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Self-contained dialog widget that manages its own TextEditingController.
class _ReportDialogWidget extends StatefulWidget {
  final ShakeReportTarget target;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const _ReportDialogWidget({
    required this.target,
    required this.scaffoldMessengerKey,
  });

  @override
  State<_ReportDialogWidget> createState() => _ReportDialogWidgetState();
}

class _ReportDialogWidgetState extends State<_ReportDialogWidget> {
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
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final api = ApiClient();
      await api.post(ApiEndpoints.reports, data: {
        'reportType': widget.target.reportType,
        'hostName': widget.target.hostName,
        'location': widget.target.location,
        'problem': problem,
        'itemId': widget.target.itemId,
        'itemTitle': widget.target.itemTitle,
        'sourcePlatform': 'mobile',
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _submitting = false);
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit report: ${error.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    return AlertDialog(
      title: Text(
        target.reportType == 'experience'
            ? 'Report this experience'
            : 'Report this stay',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Host: ${target.hostName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Location: ${target.location}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _problemController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Problem / inconvenience',
                hintText: 'Describe the issue',
              ),
            ),
          ],
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

class ShakeReportListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const ShakeReportListener({
    super.key,
    required this.child,
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
  });

  @override
  State<ShakeReportListener> createState() => _ShakeReportListenerState();
}

class _ShakeReportListenerState extends State<ShakeReportListener> {
  static const double _shakeThreshold = 2.0;
  static const Duration _hitWindow = Duration(milliseconds: 1000);
  static const Duration _cooldown = Duration(seconds: 8);

  final HiveService _hiveService = HiveService();
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSub;
  DateTime _lastTriggeredAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastShakeHitAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _shakeHitCount = 0;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _accelerometerSub =
        userAccelerometerEventStream().listen(_onAccelerometerEvent);
  }

  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    final hasSession =
        _hiveService.isLoggedIn() ||
        (_hiveService.getToken()?.isNotEmpty ?? false);
    if (!hasSession) return;
    if (ShakeReportTargetRegistry.isReportDialogOpen.value) return;
    if (_dialogOpen) return;

    final now = DateTime.now();
    if (now.difference(_lastTriggeredAt) < _cooldown) return;

    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (magnitude < _shakeThreshold) {
      if (now.difference(_lastShakeHitAt) > _hitWindow) {
        _shakeHitCount = 0;
      }
      return;
    }

    if (now.difference(_lastShakeHitAt) <= _hitWindow) {
      _shakeHitCount += 1;
    } else {
      _shakeHitCount = 1;
    }
    _lastShakeHitAt = now;

    if (_shakeHitCount < 2) return;

    final target = ShakeReportTargetRegistry.currentTarget.value;
    if (target == null) return;

    _lastTriggeredAt = now;
    _shakeHitCount = 0;
    _dialogOpen = true;
    ShakeReportTargetRegistry.setReportDialogOpen(true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _resetDialogState();
        return;
      }
      _openReportDialog(target);
    });
  }

  void _resetDialogState() {
    _dialogOpen = false;
    ShakeReportTargetRegistry.setReportDialogOpen(false);
  }

  Future<void> _openReportDialog(ShakeReportTarget target) async {
    final navState = widget.navigatorKey.currentState;
    if (navState == null) {
      _resetDialogState();
      return;
    }

    // Use the overlay context (topmost route) so the dialog visually appears
    // on top of the current screen, not at the root navigator level.
    final dialogContext = navState.overlay?.context ?? navState.context;

    bool? submitted;
    try {
      submitted = await showDialog<bool>(
        context: dialogContext,
        useRootNavigator: false,
        barrierDismissible: true,
        builder: (_) => _ReportDialogWidget(
          target: target,
          scaffoldMessengerKey: widget.scaffoldMessengerKey,
        ),
      );
    } catch (_) {
      // Dialog was dismissed abnormally
    }

    // Delay cleanup to next frame so the dialog route fully deactivates first.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _resetDialogState();
      if (submitted == true) {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Report sent to admin successfully')),
        );
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
