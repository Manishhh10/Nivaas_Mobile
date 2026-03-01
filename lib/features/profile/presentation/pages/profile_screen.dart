import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/services/hive/hive_service.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';
import 'package:nivaas/features/splash/presentation/pages/home_check_screen.dart';
import 'package:nivaas/features/auth/presentation/pages/login_screen.dart';
import 'package:nivaas/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:nivaas/features/host/presentation/pages/host_bottom_navigation_screen.dart';
import 'package:nivaas/features/messages/presentation/pages/messages_screen.dart';
import 'package:nivaas/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:nivaas/features/admin/presentation/pages/admin_host_verification_screen.dart';
import 'package:nivaas/features/admin/presentation/pages/admin_reports_screen.dart';
import 'package:nivaas/features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'package:nivaas/features/profile/presentation/pages/settings_screen.dart';
import 'package:nivaas/features/profile/presentation/pages/traveler_dashboard_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggedIn = false;

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  void initState() {
    super.initState();
    _refreshAuthState();
  }

  void _refreshAuthState() {
    final hiveService = HiveService();
    if (!mounted) return;
    setState(() {
      _isLoggedIn =
          hiveService.isLoggedIn() ||
          ((hiveService.getToken() ?? '').isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return _notLoggedIn(context);
    }

    final verifyAsync = ref.watch(verifyProvider);

    return Scaffold(
      body: SafeArea(
        child: verifyAsync.when(
          data: (verifyData) => _buildProfile(context, verifyData),
          loading: () => const Center(child: CircularProgressIndicator(color: primaryOrange)),
          error: (e, _) => _buildOfflineProfile(context),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, VerifyResponse data) {
    final user = data.user;
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin =
        (user?.isAdmin ?? false) ||
        HiveService().getUserRole().toLowerCase() == 'admin';

    if (user == null) {
      return const Center(child: Text('User data not available'));
    }

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
                  backgroundColor: primaryOrange.withOpacity(0.15),
                  child: user.image != null && user.image!.isNotEmpty
                      ? ClipOval(
                          child: NivaasImage(
                            imagePath: user.image!,
                            width: 100,
                            height: 100,
                          ),
                        )
                      : Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: primaryOrange,
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()));
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
            Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.72),
                fontSize: 15,
              ),
            ),
            if (user.phoneNumber.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                user.phoneNumber,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.64),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 24),

            const SizedBox(height: 16),

            if (isAdmin) ...[
              _sectionLabel('Admin'),
              _menuItem(Icons.dashboard_customize_outlined, 'Admin Dashboard', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              }),
              _menuItem(Icons.admin_panel_settings, 'Host Verification Queue', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminHostVerificationScreen()));
              }),
              _menuItem(Icons.flag_outlined, 'Reports Moderation', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminReportsScreen()));
              }),
              _menuItem(Icons.person_outline, 'Edit Profile', () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                _refreshAuthState();
                ref.invalidate(verifyProvider);
              }),
              _menuItem(Icons.settings_outlined, 'Settings', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
            ] else ...[
              _sectionLabel('Traveler'),
              _menuItem(Icons.dashboard_outlined, 'Traveler Dashboard', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TravelerDashboardScreen()));
              }),
              _menuItem(Icons.person_outline, 'Edit Profile', () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                _refreshAuthState();
                ref.invalidate(verifyProvider);
              }),
              _menuItem(Icons.chat_bubble_outline, 'Messages', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ConversationsScreen()));
              }),
              _menuItem(Icons.notifications_outlined, 'Notifications', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              }),
              _menuItem(Icons.settings_outlined, 'Settings', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),

              const SizedBox(height: 8),
              _menuItem(Icons.swap_horiz, 'Switch to Host', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HostBottomNavigationScreen()));
              }),
            ],
            _menuItem(Icons.help_outline, 'Help & Support', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact: support@nivaas.com')),
              );
            }),
            _menuItem(Icons.info_outline, 'About Nivaas', () {
              showAboutDialog(
                context: context,
                applicationName: 'Nivaas',
                applicationVersion: '1.0.0',
                children: [const Text('Find your perfect stay in Nepal')],
              );
            }),
            const SizedBox(height: 12),
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

  Widget _hostStatusCard(BuildContext context, HostStatus hostStatus) {
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
        statusText = 'Host Verification Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Host Application Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = primaryOrange;
        statusText = 'Become a Host';
        statusIcon = Icons.add_home;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HostBottomNavigationScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
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
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: statusColor)),
                  if (hostStatus.rejectionReason != null && hostStatus.rejectionReason!.isNotEmpty)
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
            Icon(Icons.arrow_forward_ios, size: 16, color: statusColor),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
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
                ? Colors.red.withOpacity(0.5)
                : colorScheme.onSurface.withOpacity(0.38)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildOfflineProfile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = HiveService().getUserRole().toLowerCase() == 'admin';
    return Center(
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
          if (isAdmin) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.dashboard_customize_outlined),
              label: const Text('Admin Dashboard'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminHostVerificationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Host Verification Queue'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                );
              },
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Reports Moderation'),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _notLoggedIn(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.45),
            ),
            const SizedBox(height: 16),
            const Text('Not logged in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
                _refreshAuthState();
                ref.invalidate(verifyProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Login'),
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
      const SnackBar(content: Text('Logged out successfully'), backgroundColor: Colors.green),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeCheckScreen()),
      (route) => false,
    );
  }
}