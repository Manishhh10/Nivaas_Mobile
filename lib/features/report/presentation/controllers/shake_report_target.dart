import 'package:flutter/foundation.dart';

class ShakeReportTarget {
  final String reportType;
  final String itemId;
  final String itemTitle;
  final String hostName;
  final String location;

  const ShakeReportTarget({
    required this.reportType,
    required this.itemId,
    required this.itemTitle,
    required this.hostName,
    required this.location,
  });
}

class ShakeReportTargetRegistry {
  static final ValueNotifier<ShakeReportTarget?> currentTarget =
      ValueNotifier<ShakeReportTarget?>(null);
  static final ValueNotifier<bool> isReportDialogOpen = ValueNotifier<bool>(
    false,
  );

  static void setTarget(ShakeReportTarget target) {
    currentTarget.value = target;
  }

  static void clear() {
    currentTarget.value = null;
  }

  static void clearIfItem(String itemId) {
    final current = currentTarget.value;
    if (current != null && current.itemId == itemId) {
      currentTarget.value = null;
    }
  }

  static void setReportDialogOpen(bool isOpen) {
    isReportDialogOpen.value = isOpen;
  }
}
