import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool isHomesSelected = true;

  final Color primaryOrange = const Color(0xFFFF6F00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            _searchBar(),

            const SizedBox(height: 20),

            _topCategories(),

            const SizedBox(height: 20),

            _tripHighlightCard(),

            const SizedBox(height: 28),

            if (isHomesSelected) ...[
              _sectionTitle(context, "Services in Nepal"),
              const SizedBox(height: 12),
              _servicesList(),
            ],

            if (!isHomesSelected) ...[
              _sectionTitle(context, "Popular Experiences"),
              const SizedBox(height: 12),
              _experienceGrid(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.search, color: Colors.black54),
            SizedBox(width: 12),
            Text(
              "Where are you going?",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCategories() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _categoryItem(
          icon: Icons.home_rounded,
          label: "Homes",
          isActive: isHomesSelected,
          onTap: () => setState(() => isHomesSelected = true),
        ),
        const SizedBox(width: 48),
        _categoryItem(
          icon: Icons.landscape_rounded,
          label: "Experiences",
          isActive: !isHomesSelected,
          onTap: () => setState(() => isHomesSelected = false),
        ),
      ],
    );
  }

  Widget _categoryItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? primaryOrange.withOpacity(0.15) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: isActive ? primaryOrange : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive ? primaryOrange : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripHighlightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryOrange.withOpacity(0.9),
              primaryOrange.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Upcoming Trip",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Pokhara Getaway",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "18–22 May · 2 guests",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "3\nDays",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicesList() {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _serviceCard("Photography", "Kathmandu", Icons.camera_alt),
          _serviceCard("Private Chef", "Pokhara", Icons.restaurant),
          _serviceCard("Local Guide", "Bhaktapur", Icons.map),
        ],
      ),
    );
  }

  Widget _serviceCard(String title, String location, IconData icon) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 120,
              color: primaryOrange.withOpacity(0.15),
              child: Center(
                child: Icon(icon, size: 42, color: primaryOrange),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            location,
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _experienceGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
        children: [
          _experienceCard("Everest View Trek", "From Rs. 4,500"),
          _experienceCard("Paragliding", "From Rs. 6,000"),
          _experienceCard("Jungle Safari", "From Rs. 3,500"),
          _experienceCard("Cultural Tour", "From Rs. 2,000"),
        ],
      ),
    );
  }

  Widget _experienceCard(String title, String price) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 140,
              color: primaryOrange.withOpacity(0.15),
              child: const Center(
                child: Icon(Icons.landscape, size: 42, color: Colors.orange),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              price,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
