import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/explore/data/models/accommodation_model.dart';
import 'package:nivaas/features/explore/data/models/experience_model.dart';
import 'package:nivaas/features/explore/presentation/pages/stay_detail_screen.dart';
import 'package:nivaas/features/explore/presentation/pages/experience_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  static const Color primaryOrange = Color(0xFFFF6518);
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _query = '';

  bool _matchesPrice(double price, String query) {
    final normalized = query.replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalized.isEmpty) return false;
    final priceText = price.toStringAsFixed(0);
    return priceText.contains(normalized);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accommodationsAsync = ref.watch(accommodationsProvider);
    final experiencesAsync = ref.watch(experiencesProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search stays & experiences...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75)),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryOrange,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          indicatorColor: primaryOrange,
          tabs: const [
            Tab(text: 'Stays'),
            Tab(text: 'Experiences'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Stays tab
          accommodationsAsync.when(
            data: (stays) {
              final filtered = _query.isEmpty
                  ? stays
                  : stays.where((s) =>
                      s.title.toLowerCase().contains(_query) ||
                      s.location.toLowerCase().contains(_query) ||
                    s.description.toLowerCase().contains(_query) ||
                    _matchesPrice(s.price, _query)).toList();
              if (filtered.isEmpty) return _emptyResult('No stays found');
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _staySearchCard(filtered[i]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: primaryOrange)),
            error: (_, __) => _emptyResult('Error loading stays'),
          ),

          // Experiences tab
          experiencesAsync.when(
            data: (experiences) {
              final filtered = _query.isEmpty
                  ? experiences
                  : experiences.where((e) =>
                      e.title.toLowerCase().contains(_query) ||
                      e.location.toLowerCase().contains(_query) ||
                      e.category.toLowerCase().contains(_query) ||
                    e.description.toLowerCase().contains(_query) ||
                    _matchesPrice(e.price, _query)).toList();
              if (filtered.isEmpty) return _emptyResult('No experiences found');
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _experienceSearchCard(filtered[i]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: primaryOrange)),
            error: (_, __) => _emptyResult('Error loading experiences'),
          ),
        ],
      ),
    );
  }

  Widget _staySearchCard(Accommodation stay) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => StayDetailScreen(accommodationId: stay.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            NivaasImage(
              imagePath: stay.firstImage,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stay.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(stay.location,
                            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72), fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('NPR ${stay.price.toStringAsFixed(0)} / night',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: primaryOrange, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _experienceSearchCard(Experience exp) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ExperienceDetailScreen(experienceId: exp.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            NivaasImage(
              imagePath: exp.firstImage,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exp.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(exp.category,
                            style: const TextStyle(color: primaryOrange, fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on, size: 13, color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(exp.location,
                            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72), fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('NPR ${exp.price.toStringAsFixed(0)} / person',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: primaryOrange, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyResult(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: colorScheme.onSurface.withOpacity(0.45)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72), fontSize: 15)),
        ],
      ),
    );
  }
}
