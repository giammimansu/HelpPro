// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static final List<Widget> _pages = [
    const _HomeTab(),
    const MapScreen(),
    const CartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpNow'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F4EF),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({Key? key}) : super(key: key);

  static const List<CategoryItem> categories = [
    CategoryItem(label: 'Haircut', asset: 'assets/categories/haircut.png'),
    CategoryItem(
      label: 'Beautician',
      asset: 'assets/categories/beautician.png',
    ),
    CategoryItem(label: 'Plumber', asset: 'assets/categories/plumber.png'),
    CategoryItem(label: 'Mason', asset: 'assets/categories/mason.png'),
  ];

  static const List<ServiceItem> featured = [
    ServiceItem(
      title: 'Haircut',
      price: '\$25',
      imageAsset: 'assets/featured/haircut.png',
    ),
    ServiceItem(
      title: 'Facial',
      price: '\$40',
      imageAsset: 'assets/featured/facial.png',
    ),
  ];

  static const List<PromotionItem> promotions = [
    PromotionItem(label: '20% OFF', color: Color(0xFFE94E1B)),
    PromotionItem(label: '\$10 OFF', color: Color(0xFFF7941D)),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),

            // Categories
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => CategoryCard(item: categories[i]),
              ),
            ),

            const SizedBox(height: 24),

            // Featured
            const Text(
              'Featured',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) => ServiceCard(item: featured[i]),
              ),
            ),

            const SizedBox(height: 24),

            // Promotions
            const Text(
              'Promotions of the week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: promotions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) => PromotionCard(item: promotions[i]),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Models
class CategoryItem {
  final String label;
  final String asset;
  const CategoryItem({required this.label, required this.asset});
}

class ServiceItem {
  final String title;
  final String price;
  final String imageAsset;
  const ServiceItem({
    required this.title,
    required this.price,
    required this.imageAsset,
  });
}

class PromotionItem {
  final String label;
  final Color color;
  const PromotionItem({required this.label, required this.color});
}

// Widgets
class CategoryCard extends StatelessWidget {
  final CategoryItem item;
  const CategoryCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            item.asset,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final ServiceItem item;
  const ServiceCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              item.imageAsset,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.price, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PromotionCard extends StatelessWidget {
  final PromotionItem item;
  const PromotionCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        item.label,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Map and Cart Screens
class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  static const _initialCamera = CameraPosition(
    target: LatLng(45.4642, 9.19), // Milano di default
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    return const GoogleMap(
      initialCameraPosition: _initialCamera,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Il tuo carrello è vuoto',
        style: Theme.of(context).textTheme.titleLarge, // <— usiamo titleLarge
      ),
    );
  }
}
