// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> categories = const [
    { 'label': 'Hairdressers', 'icon': Icons.content_cut, 'color': Color(0xFFE0BBE4) },
    { 'label': 'Beauticians', 'icon': Icons.brush,    'color': Color(0xFFB2EBF2) },
    { 'label': 'Plumbers',    'icon': Icons.plumbing, 'color': Color(0xFFC8E6C9) },
    { 'label': 'Masons',      'icon': Icons.build,    'color': Color(0xFFFFF9C4) },
  ];

  final List<Map<String, dynamic>> featured = const [
    { 'title': 'Haircut', 'subtitle': 'From \$50', 'price': '\$40', 'image': 'assets/haircut.png' },
    { 'title': 'Facial',  'subtitle': 'From \$20', 'price': '\$80', 'image': 'assets/facial.png' },
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpNow'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for services',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Categories (height adjusted)
            SizedBox(
              height: 100,  // Increased from 80 to give room
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  return CategoryCard(
                    label: c['label'],
                    icon: c['icon'],
                    color: c['color'],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Featured title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Featured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.arrow_forward),
              ],
            ),

            const SizedBox(height: 12),

            // Featured list (height adjusted)
            SizedBox(
              height: 220,  // Increased from 200
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final s = featured[i];
                  return ServiceCard(
                    title: s['title'],
                    subtitle: s['subtitle'],
                    price: s['price'],
                    imageAsset: s['image'],
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// === CategoryCard ===
class CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const CategoryCard({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color.darken()),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// === ServiceCard ===
class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String imageAsset;

  const ServiceCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imageAsset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Image at top
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              imageAsset,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
              ),
            ),
          ),

          // Title, price, subtitle
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// === Color extension ===
extension ColorUtils on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}
