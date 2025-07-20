import 'package:flutter/material.dart';
import 'map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          const HomeTabScreen(),
          const MapScreen(),
          const CartScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mappa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrello',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
        ],
      ),
    );
  }
}

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Categorie di servizi
  final List<Map<String, String>> _categories = [
    {'name': 'Parrucchiere', 'image': 'assets/categories/haircut.png'},
    {'name': 'Estetista', 'image': 'assets/categories/beautician.png'},
    {'name': 'Idraulico', 'image': 'assets/categories/plumber.png'},
    {'name': 'Muratore', 'image': 'assets/categories/mason.png'},
  ];

  // Servizi in evidenza
  final List<Map<String, String>> _featured = [
    {
      'name': 'Taglio di Capelli',
      'image': 'assets/featured/haircut.png',
      'price': '€25',
    },
    {
      'name': 'Trattamento Viso',
      'image': 'assets/featured/facial.png',
      'price': '€45',
    },
  ];

  // Promozioni della settimana
  final List<Map<String, dynamic>> _promotions = [
    {
      'title': 'Offerta Bellezza',
      'description': 'Sconto 20% su tutti i trattamenti viso',
      'color': Colors.pink[100],
      'discount': '20%',
    },
    {
      'title': 'Taglio + Barba',
      'description': 'Pacchetto completo a prezzo speciale',
      'color': Colors.blue[100],
      'discount': '15%',
    },
    {
      'title': 'Casa & Giardino',
      'description': 'Manutenzione domestica con sconto',
      'color': Colors.green[100],
      'discount': '25%',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            12.0,
            8.0,
            12.0,
            20.0,
          ), // Padding asimmetrico per evitare overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo in alto centrato
              Center(
                child: Image.asset('assets/logo.png', height: 50),
              ), // Ridotto da 60 a 50
              const SizedBox(height: 12), // Ridotto da 16 a 12
              // Barra di ricerca
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Trova un servizio',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12, // Ridotto da 16 a 12
                    ),
                    isDense: true, // Aggiungiamo per ridurre l'altezza
                  ),
                ),
              ),
              const SizedBox(height: 16), // Ridotto da 24 a 16
              // Menu categorie
              const Text(
                'Categorie',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8), // Ridotto da 12 a 8
              SizedBox(
                height: 80, // Ridotto da 90 a 80
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            width: 50, // Ridotto da 60 a 50
                            height: 50, // Ridotto da 60 a 50
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                25,
                              ), // Aggiornato da 30 a 25
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                25,
                              ), // Aggiornato da 30 a 25
                              child: Image.asset(
                                category['image']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name']!,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20), // Ridotto da 32 a 20
              // In Evidenza
              const Text(
                'In Evidenza',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8), // Ridotto da 12 a 8
              SizedBox(
                height: 140, // Ridotto da 160 a 140
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _featured.length,
                  itemBuilder: (context, index) {
                    final item = _featured[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.asset(
                              item['image']!,
                              height: 80, // Ridotto da 100 a 80
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(
                              8,
                            ), // Ridotto da 12 a 8
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item['price']!,
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16), // Ridotto da 20 a 16
              // Promozioni della Settimana
              const Text(
                'Promozioni della Settimana',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8), // Ridotto da 12 a 8
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _promotions.length,
                itemBuilder: (context, index) {
                  final promo = _promotions[index];
                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 8,
                    ), // Ridotto da 12 a 8
                    padding: const EdgeInsets.all(12), // Ridotto da 16 a 12
                    decoration: BoxDecoration(
                      color: promo['color'],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, // Ridotto da 50 a 40
                          height: 40, // Ridotto da 50 a 40
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // Aggiornato da 25 a 20
                          ),
                          child: Center(
                            child: Text(
                              promo['discount'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 12, // Ridotto il font size
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12), // Ridotto da 16 a 12
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promo['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                promo['description'],
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // Spazio finale per evitare overflow
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Placeholder per CartScreen
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Carrello',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Il tuo carrello è vuoto'),
          ],
        ),
      ),
    );
  }
}

// Placeholder per ProfileScreen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Profilo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Gestisci il tuo account'),
          ],
        ),
      ),
    );
  }
}
