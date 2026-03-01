import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/features/admin/presentation/pages/admin_host_verification_screen.dart';
import 'package:nivaas/features/admin/presentation/pages/admin_reports_screen.dart';
import 'package:nivaas/features/navigation/presentation/pages/bottom_navigation_screen.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int adminUsers;
  final int pendingHosts;
  final int totalReports;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.adminUsers,
    required this.pendingHosts,
    required this.totalReports,
  });
}

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((ref) async {
  final api = ref.read(apiClientProvider);
  final usersResponse = await api.get('${ApiEndpoints.adminUsers}?page=1&limit=1000');
  final pendingHostsResponse = await api.get(ApiEndpoints.adminPendingHosts);
  final reportsResponse = await api.get(ApiEndpoints.adminReports);

  final users = (usersResponse.data['users'] as List? ?? [])
      .cast<Map<String, dynamic>>();
  final reports = (reportsResponse.data['data'] as List? ?? [])
      .cast<Map<String, dynamic>>();

  final totalUsers = (usersResponse.data['pagination'] is Map)
      ? ((usersResponse.data['pagination']['total'] as int?) ?? users.length)
      : users.length;

  final adminUsers = users.where((u) {
    final role = (u['role'] ?? '').toString().toLowerCase();
    return role == 'admin';
  }).length;

  final pendingHosts = (pendingHostsResponse.data['hosts'] as List? ?? []).length;

  final totalReports = reports.length;

  return AdminDashboardStats(
    totalUsers: totalUsers,
    adminUsers: adminUsers,
    pendingHosts: pendingHosts,
    totalReports: totalReports,
  );
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final stats = statsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const AdminDashboardStats(
        totalUsers: 0,
        adminUsers: 0,
        pendingHosts: 0,
        totalReports: 0,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const BottomNavigationScreen(),
              ),
            );
          },
        ),
        title: const Text('Admin Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BottomNavigationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
            label: const Text(
              'User App',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryOrange,
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryOrange.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: primaryOrange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Moderate host approvals and user reports',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context: context,
                    title: 'Total Users',
                    value: stats.totalUsers.toString(),
                    icon: Icons.groups_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    context: context,
                    title: 'Admin Users',
                    value: stats.adminUsers.toString(),
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context: context,
                    title: 'Pending Hosts',
                    value: stats.pendingHosts.toString(),
                    icon: Icons.verified_user_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    context: context,
                    title: 'Total Reports',
                    value: stats.totalReports.toString(),
                    icon: Icons.flag_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _actionCard(
              context,
              icon: Icons.verified_user_outlined,
              title: 'Host Verification Queue',
              subtitle: 'Review and approve pending host applications',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminHostVerificationScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _actionCard(
              context,
              icon: Icons.flag_outlined,
              title: 'Reports Moderation',
              subtitle: 'Resolve or reopen reported issues',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
              ),
            ),
            const SizedBox(height: 20),
            statsAsync.when(
              data: (_) => const SizedBox.shrink(),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: CircularProgressIndicator(color: primaryOrange),
                ),
              ),
              error: (e, _) => Text(
                'Could not refresh admin stats right now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryOrange),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72)),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outline.withOpacity(0.24)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.72),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
