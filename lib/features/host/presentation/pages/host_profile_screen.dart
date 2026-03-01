import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';
import 'package:nivaas/features/host/presentation/pages/host_dashboard_screen.dart';
import 'package:nivaas/features/host/presentation/pages/host_stats_dashboard_screen.dart';
import 'package:nivaas/features/host/presentation/pages/host_apply_screen.dart';
import 'package:nivaas/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:nivaas/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:nivaas/features/splash/presentation/pages/home_check_screen.dart';

class HostProfileScreen extends ConsumerStatefulWidget {
  const HostProfileScreen({super.key});

  @override
  ConsumerState<HostProfileScreen> createState() => _HostProfileScreenState();
}

class _HostProfileScreenState extends ConsumerState<HostProfileScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context) {
    final verifyAsync = ref.watch(verifyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: verifyAsync.when(
          data: (data) => _body(context, data),
          loading: () =>
              const Center(child: CircularProgressIndicator(color: primaryOrange)),
          error: (_, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: colorScheme.onSurface.withOpacity(0.45),
                ),
                const SizedBox(height: 12),
                const Text('Could not load profile'),
                TextButton(
                  onPressed: () => ref.invalidate(verifyProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, VerifyResponse data) {
    final user = data.user;
    final hostStatus = data.hostStatus;
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: primaryOrange,
      onRefresh: () async => ref.invalidate(verifyProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryOrange.withValues(alpha: 0.15),
                  child: user != null && user.image != null && user.image!.isNotEmpty
                      ? ClipOval(
                          child: NivaasImage(
                              imagePath: user.image!, width: 100, height: 100))
                      : Text(
                          user != null && user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'H',
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: primaryOrange),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      ref.invalidate(verifyProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              Text(user.name,
                  style:
                      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user.email,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.72),
                    fontSize: 15,
                  )),
            ],
            const SizedBox(height: 24),

            // Verification status card
            if (hostStatus != null) _verificationCard(hostStatus),
            const SizedBox(height: 16),

            _sectionLabel('Host'),
            _menuItem(Icons.space_dashboard_outlined, 'Host Dashboard', () {
              Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HostStatsDashboardScreen()));
            }),
            _menuItem(Icons.verified_user_outlined, 'Verification', () {
              _showVerificationDetail(context, hostStatus);
            }),
            _menuItem(Icons.notifications_outlined, 'Notifications', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            }),
            _menuItem(Icons.home_outlined, 'Host a Stay', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateListingScreen()));
            }),
            _menuItem(Icons.landscape_outlined, 'Host an Experience', () {
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const CreateExperienceScreen()));
            }),
            _menuItem(Icons.assignment_turned_in_outlined, 'Apply / Reapply Verification', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HostApplyScreen()));
            }),
            const Divider(height: 32),
            _menuItem(Icons.swap_horiz, 'Switch to Traveling', () {
              Navigator.pop(context); // pops back to the traveler shell
            }),
            _menuItem(Icons.logout, 'Logout', () => _logout(context),
                isDestructive: true),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface.withOpacity(0.68),
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _verificationCard(HostStatus hostStatus) {
    final colorScheme = Theme.of(context).colorScheme;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (hostStatus.status.toLowerCase()) {
      case 'verified':
        statusColor = Colors.green;
        statusText = 'Verified Host';
        statusIcon = Icons.verified;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Verification Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Application Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = primaryOrange;
        statusText = 'Not Verified';
        statusIcon = Icons.info_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: statusColor)),
                if (hostStatus.rejectionReason != null &&
                    hostStatus.rejectionReason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(hostStatus.rejectionReason!,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.72),
                          fontSize: 13,
                        )),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive
              ? Colors.red
              : colorScheme.onSurface.withOpacity(0.72),
        ),
        title: Text(title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDestructive
                  ? Colors.red
                  : colorScheme.onSurface.withOpacity(0.92),
            )),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16,
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.5)
                : colorScheme.onSurface.withOpacity(0.38)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  void _showVerificationDetail(BuildContext context, HostStatus? hostStatus) {
    final status = hostStatus?.status.toLowerCase() ?? 'none';
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              status == 'verified'
                  ? Icons.verified
                  : status == 'pending'
                      ? Icons.hourglass_empty
                      : status == 'rejected'
                          ? Icons.cancel
                          : Icons.info_outline,
              size: 56,
              color: status == 'verified'
                  ? Colors.green
                  : status == 'pending'
                      ? Colors.orange
                      : status == 'rejected'
                          ? Colors.red
                          : primaryOrange,
            ),
            const SizedBox(height: 12),
            Text(
              status == 'verified'
                  ? 'You are a Verified Host'
                  : status == 'pending'
                      ? 'Your application is being reviewed'
                      : status == 'rejected'
                          ? 'Your application was rejected'
                          : 'You have not applied to be a host',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (hostStatus?.rejectionReason != null &&
                hostStatus!.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reason: ${hostStatus.rejectionReason}',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.72),
                  )),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    final hiveService = HiveService();
    hiveService.logout();
    invalidateAllProviders(ref);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeCheckScreen()),
      (route) => false,
    );
  }
}
