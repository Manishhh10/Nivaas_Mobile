import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/core/widgets/notification_popup.dart';
import 'package:nivaas/features/explore/data/models/accommodation_model.dart';
import 'package:nivaas/features/explore/data/models/experience_model.dart';
import 'package:nivaas/features/explore/presentation/pages/stay_detail_screen.dart';
import 'package:nivaas/features/explore/presentation/pages/experience_detail_screen.dart';
import 'package:nivaas/features/explore/presentation/pages/search_screen.dart';
import 'package:nivaas/features/wishlist/presentation/providers/wishlist_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool isStaysSelected = true;
  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accommodationsAsync = ref.watch(accommodationsProvider);
    final experiencesAsync = ref.watch(experiencesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryOrange,
          onRefresh: () async {
            ref.invalidate(accommodationsProvider);
            ref.invalidate(experiencesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _searchBar(),
                const SizedBox(height: 20),
                _topCategories(),
                const SizedBox(height: 24),
                if (isStaysSelected) ...[
                  _sectionTitle("Stays in Nepal"),
                  const SizedBox(height: 12),
                  accommodationsAsync.when(
                    data: (stays) => stays.isEmpty
                        ? _emptyState('No stays available yet')
                        : _staysList(stays),
                    loading: () => _loadingShimmer(),
                    error: (e, _) => _errorState('Failed to load stays'),
                  ),
                ] else ...[
                  _sectionTitle("Experiences in Nepal"),
                  const SizedBox(height: 12),
                  experiencesAsync.when(
                    data: (experiences) => experiences.isEmpty
                        ? _emptyState('No experiences available yet')
                        : _experiencesGrid(experiences),
                    loading: () => _loadingShimmer(),
                    error: (e, _) => _errorState('Failed to load experiences'),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withOpacity(0.72),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Where are you going?",
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.72),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => NotificationPopup.show(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: colorScheme.outline.withOpacity(0.24)),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: colorScheme.onSurface.withOpacity(0.72),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topCategories() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _categoryItem(Icons.home_rounded, "Stays", isStaysSelected,
            () => setState(() => isStaysSelected = true)),
        const SizedBox(width: 48),
        _categoryItem(Icons.landscape_rounded, "Experiences", !isStaysSelected,
            () => setState(() => isStaysSelected = false)),
      ],
    );
  }

  Widget _categoryItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? primaryOrange.withOpacity(0.15)
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 26,
                color: isActive
                    ? primaryOrange
                    : colorScheme.onSurface.withOpacity(0.72)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isActive
                    ? primaryOrange
                    : colorScheme.onSurface.withOpacity(0.72),
              )),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 20,
              decoration: BoxDecoration(
                color: primaryOrange,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _staysList(List<Accommodation> stays) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stays.length,
      itemBuilder: (context, index) => _stayCard(stays[index]),
    );
  }

  Widget _stayCard(Accommodation stay) {
    final colorScheme = Theme.of(context).colorScheme;
    final wishlist = ref.watch(wishlistProvider);
    final isLiked = wishlist.contains(stay.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StayDetailScreen(accommodationId: stay.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                NivaasImage(
                  imagePath: stay.firstImage,
                  height: 200,
                  width: double.infinity,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(wishlistProvider.notifier).toggle(stay.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.96),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked
                            ? Colors.red.shade500
                            : colorScheme.onSurface,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stay.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.62),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stay.location,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.72),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'NPR ${stay.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryOrange,
                        ),
                      ),
                      Text(
                        ' / night',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.72),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      _infoChip(Icons.person, '${stay.maxGuests}'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.bed, '${stay.bedrooms}'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.bathtub_outlined, '${stay.bathrooms}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurface.withOpacity(0.62)),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.72),
          ),
        ),
      ],
    );
  }

  Widget _experiencesGrid(List<Experience> experiences) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: experiences.length,
      itemBuilder: (context, index) => _experienceCard(experiences[index]),
    );
  }

  Widget _experienceCard(Experience exp) {
    final colorScheme = Theme.of(context).colorScheme;
    final wishlist = ref.watch(wishlistProvider);
    final isLiked = wishlist.contains(exp.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExperienceDetailScreen(experienceId: exp.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                NivaasImage(
                  imagePath: exp.firstImage,
                  height: 180,
                  width: double.infinity,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(wishlistProvider.notifier).toggle(exp.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.96),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked
                            ? Colors.red.shade500
                            : colorScheme.onSurface,
                        size: 21,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      exp.category,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exp.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.62),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(exp.location,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.72),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'NPR ${exp.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryOrange,
                        ),
                      ),
                      Text(
                        ' / person',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.72),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.62),
                      ),
                      const SizedBox(width: 4),
                      Text(exp.duration,
                          style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.72),
                          fontSize: 12,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }

  Widget _loadingShimmer() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 260,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.45),
            ),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.72),
                  fontSize: 15,
                )),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(color: Colors.red.shade400, fontSize: 15)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.invalidate(accommodationsProvider);
                ref.invalidate(experiencesProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}