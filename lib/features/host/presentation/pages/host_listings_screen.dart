import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/host/presentation/pages/host_edit_pages.dart';
import 'package:nivaas/features/host/presentation/pages/host_dashboard_screen.dart';

class HostListingsScreen extends ConsumerStatefulWidget {
  const HostListingsScreen({super.key});

  @override
  ConsumerState<HostListingsScreen> createState() => _HostListingsScreenState();
}

class _HostListingsScreenState extends ConsumerState<HostListingsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryOrange = Color(0xFFFF6518);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Listings',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            TabBar(
              controller: _tabController,
              labelColor: primaryOrange,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: primaryOrange,
              tabs: const [
                Tab(text: 'Stays'),
                Tab(text: 'Experiences'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _accommodationsTab(),
                  _experiencesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        backgroundColor: primaryOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _accommodationsTab() {
    final listingsAsync = ref.watch(hostListingsProvider);

    return RefreshIndicator(
      color: primaryOrange,
      onRefresh: () async => ref.invalidate(hostListingsProvider),
      child: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return _emptyState('No stays yet', 'Add your first stay');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            itemBuilder: (_, i) => _listingCard(listings[i]),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: primaryOrange)),
        error: (_, _) => const Center(child: Text('Error loading listings')),
      ),
    );
  }

  Widget _experiencesTab() {
    final expAsync = ref.watch(hostExperiencesProvider);

    return RefreshIndicator(
      color: primaryOrange,
      onRefresh: () async => ref.invalidate(hostExperiencesProvider),
      child: expAsync.when(
        data: (experiences) {
          if (experiences.isEmpty) {
            return _emptyState('No experiences yet', 'Create your first experience');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: experiences.length,
            itemBuilder: (_, i) => _experienceCard(experiences[i]),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: primaryOrange)),
        error: (_, _) => const Center(child: Text('Error loading experiences')),
      ),
    );
  }

  Widget _listingCard(Map<String, dynamic> listing) {
    final colorScheme = Theme.of(context).colorScheme;
    final images = List<String>.from(listing['images'] ?? []);
    final isPublished = listing['isPublished'] == true;
    final listingId = (listing['_id'] ?? '').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: listingId.isEmpty
          ? null
          : () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HostEditListingScreen(listingId: listingId),
                ),
              );
              if (updated == true) ref.invalidate(hostListingsProvider);
            },
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          NivaasImage(
            imagePath: images.isNotEmpty ? images.first : '',
            width: 100,
            height: 100,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(listing['title'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPublished
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPublished ? 'Published' : 'Draft',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPublished ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(listing['location'] ?? '',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                      'NPR ${(listing['price'] ?? 0).toString()} / night',
                      style: const TextStyle(
                          color: primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _experienceCard(Map<String, dynamic> exp) {
    final colorScheme = Theme.of(context).colorScheme;
    final images = List<String>.from(exp['images'] ?? []);
    final experienceId = (exp['_id'] ?? '').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: experienceId.isEmpty
          ? null
          : () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HostEditExperienceScreen(experienceId: experienceId),
                ),
              );
              if (updated == true) ref.invalidate(hostExperiencesProvider);
            },
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          NivaasImage(
            imagePath: images.isNotEmpty ? images.first : '',
            width: 100,
            height: 100,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exp['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(exp['category'] ?? '',
                      style: const TextStyle(
                          color: primaryOrange, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                      'NPR ${(exp['price'] ?? 0).toString()} / person',
                      style: const TextStyle(
                          color: primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Create New',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home, color: primaryOrange),
              ),
              title: const Text('Add Stay'),
              subtitle: const Text('List a new stay'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateListingScreen()));
                ref.invalidate(hostListingsProvider);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.landscape, color: primaryOrange),
              ),
              title: const Text('Add Experience'),
              subtitle: const Text('Create a new experience'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateExperienceScreen()));
                ref.invalidate(hostExperiencesProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
