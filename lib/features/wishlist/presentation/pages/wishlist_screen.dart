import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/explore/data/models/accommodation_model.dart';
import 'package:nivaas/features/explore/data/models/experience_model.dart';
import 'package:nivaas/features/explore/presentation/pages/stay_detail_screen.dart';
import 'package:nivaas/features/explore/presentation/pages/experience_detail_screen.dart';
import 'package:nivaas/features/wishlist/presentation/providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistIds = ref.watch(wishlistProvider);
    final accommodationsAsync = ref.watch(accommodationsProvider);
    final experiencesAsync = ref.watch(experiencesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Wishlist',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${wishlistIds.length} saved items',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72), fontSize: 15)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: wishlistIds.isEmpty
                  ? _emptyState()
                  : _buildWishlistContent(context, ref, wishlistIds, accommodationsAsync, experiencesAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistContent(
    BuildContext context,
    WidgetRef ref,
    Set<String> wishlistIds,
    AsyncValue<List<Accommodation>> accommodationsAsync,
    AsyncValue<List<Experience>> experiencesAsync,
  ) {
    return accommodationsAsync.when(
      data: (allStays) {
        return experiencesAsync.when(
          data: (allExperiences) {
            final savedStays = allStays.where((s) => wishlistIds.contains(s.id)).toList();
            final savedExperiences = allExperiences.where((e) => wishlistIds.contains(e.id)).toList();

            if (savedStays.isEmpty && savedExperiences.isEmpty) {
              return _emptyState();
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (savedStays.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Stays', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ...savedStays.map((stay) => _stayCard(context, ref, stay)),
                ],
                if (savedExperiences.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12, top: 8),
                    child: Text('Experiences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ...savedExperiences.map((exp) => _experienceCard(context, ref, exp)),
                ],
                const SizedBox(height: 20),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: primaryOrange)),
          error: (_, __) => const Center(child: Text('Error loading experiences')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: primaryOrange)),
      error: (_, __) => const Center(child: Text('Error loading stays')),
    );
  }

  Widget _stayCard(BuildContext context, WidgetRef ref, Accommodation stay) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key('stay_${stay.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => ref.read(wishlistProvider.notifier).toggle(stay.id),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => StayDetailScreen(accommodationId: stay.id))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              NivaasImage(
                imagePath: stay.firstImage,
                width: 100,
                height: 100,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stay.title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.location_on, size: 13, color: colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 2),
                        Expanded(child: Text(stay.location,
                            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72), fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 6),
                      Text('NPR ${stay.price.toStringAsFixed(0)} / night',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryOrange, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => ref.read(wishlistProvider.notifier).toggle(stay.id),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _experienceCard(BuildContext context, WidgetRef ref, Experience exp) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key('exp_${exp.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => ref.read(wishlistProvider.notifier).toggle(exp.id),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ExperienceDetailScreen(experienceId: exp.id))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              NivaasImage(
                imagePath: exp.firstImage,
                width: 100,
                height: 100,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exp.title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(exp.category,
                              style: const TextStyle(color: primaryOrange, fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.location_on, size: 13, color: colorScheme.onSurface.withOpacity(0.6)),
                        Expanded(child: Text(exp.location,
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72), fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 6),
                      Text('NPR ${exp.price.toStringAsFixed(0)} / person',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryOrange, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => ref.read(wishlistProvider.notifier).toggle(exp.id),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No saved items', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Tap the heart icon to save stays & experiences', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
