import 'package:flutter/material.dart';
import 'map_screen.dart';
import '../services/vendor_service.dart';
import '../models/vendor.dart';
import 'package:geolocator/geolocator.dart' as geo;

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
        children: const [HomeTabScreen(), MapScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
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
  final VendorService _vendorService = VendorService();
  final TextEditingController _searchController = TextEditingController();
  List<Vendor> _allVendors = [];
  List<Vendor> _filteredVendors = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  geo.Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _currentPosition = position;
      });
      // Carica i vendor automaticamente quando si ottiene la posizione
      _loadVendors();
    } catch (e) {
      print('Errore nel recupero della posizione: $e');
      // Usa una posizione di default (es. Roma)
      setState(() {
        _currentPosition = geo.Position(
          latitude: 41.9028,
          longitude: 12.4964,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      });
      _loadVendors();
    }
  }

  Future<void> _loadVendors() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vendors = await _vendorService.fetchVendors(
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        radiusKm: 50.0, // Raggio più ampio per la ricerca iniziale
      );

      setState(() {
        _allVendors = vendors;
        _filteredVendors = vendors;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore nel caricamento: $e')));
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredVendors = _allVendors;
      });
      return;
    }

    setState(() {
      _filteredVendors = _allVendors.where((vendor) {
        final companyName = vendor.companyName.toLowerCase();
        final address = vendor.address.toLowerCase();
        final city = vendor.city.toLowerCase();

        return companyName.contains(query) ||
            address.contains(query) ||
            city.contains(query);
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredVendors = _allVendors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpPro'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra di ricerca
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cerca per nome venditore o via...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contenuto principale
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento fornitori...'),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_searching, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Sto cercando la tua posizione...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_filteredVendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty
                  ? Icons.search_off
                  : Icons.store_mall_directory_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Nessun risultato trovato'
                  : 'Nessun fornitore nelle vicinanze',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Prova con parole chiave diverse'
                  : 'Prova ad ampliare il raggio di ricerca',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVendors,
      child: ListView.builder(
        itemCount: _filteredVendors.length,
        itemBuilder: (context, index) {
          final vendor = _filteredVendors[index];
          return _buildVendorCard(vendor);
        },
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vendor.category,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showVendorOptions(vendor);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              vendor.companyName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${vendor.address}, ${vendor.city}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callVendor(vendor),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Chiama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showOnMap(vendor),
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('Mappa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVendorOptions(Vendor vendor) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vendor.companyName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Dettagli'),
                onTap: () {
                  Navigator.pop(context);
                  _showVendorDetails(vendor);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Chiama'),
                onTap: () {
                  Navigator.pop(context);
                  _callVendor(vendor);
                },
              ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Mostra sulla mappa'),
                onTap: () {
                  Navigator.pop(context);
                  _showOnMap(vendor);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVendorDetails(Vendor vendor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(vendor.companyName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Categoria', vendor.category),
              _detailRow('Indirizzo', vendor.address),
              _detailRow('Città', vendor.city),
              _detailRow('CAP', vendor.postcode),
              _detailRow('Paese', vendor.country),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _callVendor(Vendor vendor) {
    // Implementa la chiamata
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Chiamata a ${vendor.companyName}')));
  }

  void _showOnMap(Vendor vendor) {
    // Naviga alla mappa e mostra il vendor
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
    // Qui potresti passare parametri per centrare la mappa sul vendor
  }
}
