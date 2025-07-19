import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../services/vendor_service.dart';
import '../models/vendor.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  MapboxMap? mapboxMapController;
  geo.Position? _currentPosition;
  PointAnnotationManager? _pointAnnotationManager;
  final VendorService _vendorService = VendorService();
  List<Vendor> _vendors = [];
  List<Vendor> _filteredVendors = [];
  Set<String> _selectedCategories = {};
  Set<String> _availableCategories = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    // Ritarda leggermente per permettere al widget di inizializzarsi
    Future.delayed(Duration(milliseconds: 100), () {
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo
            .LocationAccuracy
            .medium, // Cambiato da high a medium per velocità
        timeLimit: Duration(seconds: 10), // Timeout per evitare attese infinite
      );
      setState(() {
        _currentPosition = position;
      });
      if (mapboxMapController != null) {
        _moveCameraAndDrawCircle();
      }
    } catch (e) {
      // Gestisci errore - prova con last known position
      try {
        geo.Position? position = await geo.Geolocator.getLastKnownPosition();
        if (position != null) {
          setState(() {
            _currentPosition = position;
          });
          if (mapboxMapController != null) {
            _moveCameraAndDrawCircle();
          }
        }
      } catch (e2) {
        print('Errore nella localizzazione: $e2');
      }
    }
  }

  void _moveCameraAndDrawCircle() {
    if (mapboxMapController != null && _currentPosition != null) {
      mapboxMapController!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          zoom: 12.5, // Zoom adatto per un raggio di circa 10km
        ),
      );
      _addUserMarker();
      _loadVendors();
    }
  }

  Future<void> _loadVendors() async {
    if (_currentPosition != null) {
      try {
        _vendors = await _vendorService.fetchVendors(
          lat: _currentPosition!.latitude,
          lon: _currentPosition!.longitude,
          radiusKm: 5.0,
        );

        // Estrai le categorie disponibili
        _availableCategories = _vendors
            .map((vendor) => vendor.category)
            .toSet();

        // Se non ci sono filtri selezionati, mostra tutti
        if (_selectedCategories.isEmpty) {
          _selectedCategories = Set.from(_availableCategories);
        }

        _applyFilters();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento venditori: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredVendors = _vendors
          .where((vendor) => _selectedCategories.contains(vendor.category))
          .toList();
    });
    _addVendorMarkers();
  }

  String _getMarkerAssetForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'beautician':
        return 'assets/vendor_markers/beautician_marker.png';
      case 'haircut':
        return 'assets/vendor_markers/haircut_marker.png';
      case 'mason':
        return 'assets/vendor_markers/mason_marker.png';
      case 'plumber':
        return 'assets/vendor_markers/plumber_marker.png';
      default:
        return 'assets/vendor_position.png'; // Marker di default
    }
  }

  Future<void> _addVendorMarkers() async {
    if (mapboxMapController == null || _filteredVendors.isEmpty) return;

    // Se esiste già un manager, cancella solo i marker vendor (mantieni quello utente)
    if (_pointAnnotationManager != null) {
      // Per ora cancelliamo tutto e ricreiamo, in futuro potremmo essere più selettivi
      await _pointAnnotationManager!.deleteAll();

      // Ricrea il marker utente
      await _addUserMarkerOnly();
    }

    // Ottieni il livello di zoom corrente
    final CameraState cameraState = await mapboxMapController!.getCameraState();
    final double currentZoom = cameraState.zoom;

    // Calcola la scala del marker in base al zoom
    double scale = 0.15 + (currentZoom - 10) * 0.01;
    scale = scale.clamp(0.1, 0.4); // Limita la scala tra 0.1 e 0.4

    // Raggruppa i vendor per categoria per ottimizzare il caricamento
    Map<String, List<Vendor>> vendorsByCategory = {};
    for (final vendor in _filteredVendors) {
      if (!vendorsByCategory.containsKey(vendor.category)) {
        vendorsByCategory[vendor.category] = [];
      }
      vendorsByCategory[vendor.category]!.add(vendor);
    }

    // Crea marker per ogni categoria
    List<PointAnnotationOptions> allVendorMarkers = [];

    for (final category in vendorsByCategory.keys) {
      try {
        // Carica l'immagine specifica per questa categoria
        final String assetPath = _getMarkerAssetForCategory(category);
        final ByteData imageData = await rootBundle.load(assetPath);
        final Uint8List imageBytes = imageData.buffer.asUint8List();

        // Crea marker per tutti i vendor di questa categoria
        for (final vendor in vendorsByCategory[category]!) {
          allVendorMarkers.add(
            PointAnnotationOptions(
              geometry: Point(
                coordinates: Position(vendor.longitude, vendor.latitude),
              ),
              image: imageBytes,
              iconSize: scale,
            ),
          );
        }
      } catch (e) {
        print('Errore nel caricamento del marker per categoria $category: $e');

        // Fallback al marker di default se l'immagine specifica non esiste
        try {
          final ByteData defaultImageData = await rootBundle.load(
            'assets/vendor_position.png',
          );
          final Uint8List defaultImageBytes = defaultImageData.buffer
              .asUint8List();

          for (final vendor in vendorsByCategory[category]!) {
            allVendorMarkers.add(
              PointAnnotationOptions(
                geometry: Point(
                  coordinates: Position(vendor.longitude, vendor.latitude),
                ),
                image: defaultImageBytes,
                iconSize: scale,
              ),
            );
          }
        } catch (e2) {
          print('Errore anche con il marker di default: $e2');
        }
      }
    }

    // Crea tutti i marker in una sola chiamata
    await _pointAnnotationManager!.createMulti(allVendorMarkers);
  }

  Future<void> _addUserMarkerOnly() async {
    if (mapboxMapController != null &&
        _currentPosition != null &&
        _pointAnnotationManager != null) {
      // Carica l'immagine come Uint8List
      final ByteData imageData = await rootBundle.load(
        'assets/user_marker.png',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Ottieni il livello di zoom corrente
      final CameraState cameraState = await mapboxMapController!
          .getCameraState();
      final double currentZoom = cameraState.zoom;

      // Calcola la scala del marker in base al zoom
      double scale = 0.15 + (currentZoom - 10) * 0.01;
      scale = scale.clamp(0.1, 0.4);

      // Aggiungi il marker personalizzato con scala adattiva
      final pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          ),
        ),
        image: imageBytes,
        iconSize: scale,
      );

      await _pointAnnotationManager!.create(pointAnnotationOptions);
    }
  }

  Future<void> _addUserMarker() async {
    if (mapboxMapController != null && _currentPosition != null) {
      // Rimuovi marker precedente se esiste
      if (_pointAnnotationManager != null) {
        await _pointAnnotationManager!.deleteAll();
      }

      // Crea il point annotation manager
      _pointAnnotationManager = await mapboxMapController!.annotations
          .createPointAnnotationManager();

      // Carica l'immagine come Uint8List
      final ByteData imageData = await rootBundle.load(
        'assets/user_marker.png',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Ottieni il livello di zoom corrente
      final CameraState cameraState = await mapboxMapController!
          .getCameraState();
      final double currentZoom = cameraState.zoom;

      // Calcola la scala del marker in base al zoom (più zoom = marker più piccolo)
      double scale = 0.15 + (currentZoom - 10) * 0.01;
      scale = scale.clamp(0.1, 0.4); // Limita la scala tra 0.1 e 0.4

      // Aggiungi il marker personalizzato con scala adattiva
      final pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          ),
        ),
        image: imageBytes,
        iconSize: scale,
      );

      await _pointAnnotationManager!.create(pointAnnotationOptions);
    }
  }

  Future<void> _requestLocationPermission() async {
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      permission = await geo.Geolocator.requestPermission();
    }
    // Puoi gestire qui eventuali errori o permessi negati
  }

  Future<void> _recenterToCurrentLocation() async {
    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      _moveCameraAndDrawCircle();
    } catch (e) {
      // Gestisci errore di localizzazione
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile ottenere la posizione')),
      );
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'beautician':
        return Icons.face;
      case 'haircut':
        return Icons.content_cut;
      case 'mason':
        return Icons.construction;
      case 'plumber':
        return Icons.plumbing;
      default:
        return Icons.work; // Icona di default
    }
  }

  void _showCategoryFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filtra per Categoria',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Pulsante "Seleziona tutto" / "Deseleziona tutto"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (_selectedCategories.length ==
                                _availableCategories.length) {
                              _selectedCategories.clear();
                            } else {
                              _selectedCategories = Set.from(
                                _availableCategories,
                              );
                            }
                          });
                        },
                        child: Text(
                          _selectedCategories.length ==
                                  _availableCategories.length
                              ? 'Deseleziona tutto'
                              : 'Seleziona tutto',
                        ),
                      ),
                      Text(
                        '${_selectedCategories.length}/${_availableCategories.length}',
                      ),
                    ],
                  ),
                  const Divider(),
                  // Lista delle categorie
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableCategories.length,
                      itemBuilder: (context, index) {
                        final category = _availableCategories.elementAt(index);
                        final isSelected = _selectedCategories.contains(
                          category,
                        );
                        final vendorCount = _vendors
                            .where((v) => v.category == category)
                            .length;

                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Icon(
                                _getIconForCategory(category),
                                size: 24,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(category),
                            ],
                          ),
                          subtitle: Text('$vendorCount venditori'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Applica Filtri'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(onMapCreated: _OnMapCreated),
          // Pulsante filtro categorie
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton(
              onPressed: _availableCategories.isNotEmpty
                  ? _showCategoryFilters
                  : null,
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              child: Stack(
                children: [
                  const Icon(Icons.filter_list),
                  if (_selectedCategories.length < _availableCategories.length)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_selectedCategories.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Filtra categorie',
            ),
          ),
          // Pulsante posizione corrente
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              onPressed: _recenterToCurrentLocation,
              child: const Icon(Icons.my_location),
              tooltip: 'Vai alla mia posizione',
            ),
          ),
        ],
      ),
    );
  }

  void _OnMapCreated(MapboxMap controller) {
    setState(() {
      mapboxMapController = controller;
    });
    mapboxMapController?.location.updateSettings(
      LocationComponentSettings(enabled: true),
    );
    _moveCameraAndDrawCircle();
  }
}
