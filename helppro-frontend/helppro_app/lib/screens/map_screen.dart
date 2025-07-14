// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../models/vendor.dart';
import '../services/vendor_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _cityCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final VendorService _vendorService = VendorService();

  List<Vendor> _allVendors = [];
  Map<int, LatLng> _geoCache = {};

  // **Filtro** di categoria
  String? _selectedCategory;
  final _categories = ['haircut', 'beautician', 'plumber', 'mason'];

  Set<Marker> _markers = {};
  static const _initialCamera = CameraPosition(
    target: LatLng(45.4642, 9.19),
    zoom: 12,
  );

  @override
  void dispose() {
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchAndMark() async {
    // 1) fetch server-side
    _allVendors = await _vendorService.searchVendors(
      city: _cityCtrl.text.isEmpty ? null : _cityCtrl.text,
      postcode: _postcodeCtrl.text.isEmpty ? null : _postcodeCtrl.text,
      address: _addressCtrl.text.isEmpty ? null : _addressCtrl.text,
    );
    // 2) geocode e cache
    for (var v in _allVendors) {
      if (!_geoCache.containsKey(v.id)) {
        final fullAddr = '${v.address}, ${v.city}, ${v.postcode}, ${v.country}';
        try {
          final locs = await locationFromAddress(fullAddr);
          if (locs.isNotEmpty) {
            _geoCache[v.id] = LatLng(locs.first.latitude, locs.first.longitude);
          }
        } catch (_) {
          /* ignora */
        }
      }
    }
    // 3) applica filtro lato client
    _applyFilters();
  }

  void _applyFilters() {
    final filtered = _allVendors.where((v) {
      if (_selectedCategory != null && v.category != _selectedCategory) {
        return false;
      }
      return _geoCache.containsKey(v.id);
    });
    setState(() {
      _markers = filtered.map((v) {
        final pos = _geoCache[v.id]!;
        return Marker(
          markerId: MarkerId(v.id.toString()),
          position: pos,
          infoWindow: InfoWindow(title: v.companyName),
        );
      }).toSet();
    });
  }

  void _openCategoryFilter() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Filtra per categoria",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._categories.map(
                (c) => CheckboxListTile(
                  title: Text(c),
                  value: _selectedCategory == c,
                  onChanged: (_) {
                    setState(() {
                      _selectedCategory = _selectedCategory == c ? null : c;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mappa Professionisti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtro categorie',
            onPressed: _openCategoryFilter,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1) la mappa sotto
          GoogleMap(
            initialCameraPosition: _initialCamera,
            markers: _markers,
            myLocationEnabled: true,
          ),

          // 2) search bar sopra alla mappa
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.location_city),
                          hintText: 'Città',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _searchAndMark(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _postcodeCtrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.markunread_mailbox),
                          hintText: 'CAP',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _searchAndMark(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.place),
                          hintText: 'Via',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _searchAndMark(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAndMark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
