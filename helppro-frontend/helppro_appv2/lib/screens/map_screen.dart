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

  // Controlli zoom
  double _currentZoom = 12.5;
  static const double _minZoom = 8.0;
  static const double _maxZoom = 18.0;
  static const double _zoomStep = 1.0;

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

  Future<void> _testMapMovement() async {
    if (mapboxMapController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Controller mappa non disponibile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Test 1: Vai a Roma
      await mapboxMapController!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(12.4964, 41.9028), // Roma
          ),
          zoom: 13.0,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test: Mappa spostata a Roma'),
          backgroundColor: Colors.blue,
        ),
      );

      // Test 2: Dopo 2 secondi, vai a Milano
      await Future.delayed(const Duration(seconds: 2));

      await mapboxMapController!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(9.1900, 45.4642), // Milano
          ),
          zoom: 13.0,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test: Mappa spostata a Milano'),
          backgroundColor: Colors.green,
        ),
      );

      // Test 3: Torna alla posizione corrente dopo altri 2 secondi
      await Future.delayed(const Duration(seconds: 2));
      if (_currentPosition != null) {
        await mapboxMapController!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(
                _currentPosition!.longitude,
                _currentPosition!.latitude,
              ),
            ),
            zoom: 12.5,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test completato: Tornato alla posizione corrente'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _recenterToCurrentLocation() async {
    try {
      // Mostra un indicatore di caricamento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recupero posizione...'),
          duration: Duration(seconds: 1),
        ),
      );

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });

      // Verifica se il controller è disponibile
      if (mapboxMapController != null) {
        await mapboxMapController!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
            zoom: 15.0, // Zoom più vicino per verificare il movimento
          ),
        );

        // Ricarica i vendor nella nuova posizione
        _loadVendors();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Posizione aggiornata!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Controller mappa non disponibile');
      }
    } catch (e) {
      // Gestisci errore di localizzazione
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
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

  // Metodi per gestire lo zoom
  Future<void> _zoomIn() async {
    if (mapboxMapController == null) return;

    final newZoom = (_currentZoom + _zoomStep).clamp(_minZoom, _maxZoom);
    if (newZoom == _currentZoom) {
      // Zoom massimo raggiunto - feedback visivo
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Zoom massimo raggiunto'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    try {
      await mapboxMapController!.setCamera(CameraOptions(zoom: newZoom));
      setState(() {
        _currentZoom = newZoom;
      });
      print('🔍 Zoom In: ${_currentZoom.toStringAsFixed(1)}');
    } catch (e) {
      print('❌ Errore zoom in: $e');
    }
  }

  Future<void> _zoomOut() async {
    if (mapboxMapController == null) return;

    final newZoom = (_currentZoom - _zoomStep).clamp(_minZoom, _maxZoom);
    if (newZoom == _currentZoom) {
      // Zoom minimo raggiunto - feedback visivo
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Zoom minimo raggiunto'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    try {
      await mapboxMapController!.setCamera(CameraOptions(zoom: newZoom));
      setState(() {
        _currentZoom = newZoom;
      });
      print('🔍 Zoom Out: ${_currentZoom.toStringAsFixed(1)}');
    } catch (e) {
      print('❌ Errore zoom out: $e');
    }
  }

  Future<void> _updateCurrentZoom() async {
    if (mapboxMapController == null) return;

    try {
      final cameraState = await mapboxMapController!.getCameraState();
      setState(() {
        _currentZoom = cameraState.zoom;
      });
    } catch (e) {
      print('❌ Errore aggiornamento zoom: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Scaffold(
      body: Stack(
        children: [
          // Wrap MapWidget in un GestureDetector per debug
          GestureDetector(
            onTap: () => print('🔥 Tap sulla mappa rilevato!'),
            onPanUpdate: (details) =>
                print('🔥 Pan sulla mappa: ${details.delta}'),
            child: MapWidget(
              onMapCreated: _OnMapCreated,
              onCameraChangeListener: (CameraChangedEventData data) {
                // Aggiorna il livello di zoom quando l'utente cambia la camera
                if (mounted) {
                  setState(() {
                    _currentZoom = data.cameraState.zoom;
                  });
                }
              },
              cameraOptions: CameraOptions(
                center: _currentPosition != null
                    ? Point(
                        coordinates: Position(
                          _currentPosition!.longitude,
                          _currentPosition!.latitude,
                        ),
                      )
                    : Point(
                        coordinates: Position(12.4964, 41.9028), // Roma default
                      ),
                zoom: 12.5,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
            ),
          ),
          // Controlli Zoom +/-
          Positioned(
            top: 50,
            left: 16,
            child: Column(
              children: [
                // Pulsante Zoom In (+)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _zoomIn,
                      child: const Icon(
                        Icons.add,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Separatore
                Container(width: 50, height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 2),
                // Pulsante Zoom Out (-)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _zoomOut,
                      child: const Icon(
                        Icons.remove,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          // Pulsante di test movimento mappa (debug)
          Positioned(
            bottom: 150,
            right: 16,
            child: FloatingActionButton(
              onPressed: _testMapMovement,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.explore),
              tooltip: 'Test movimento mappa',
            ),
          ),
        ],
      ),
    );
  }

  void _OnMapCreated(MapboxMap controller) async {
    setState(() {
      mapboxMapController = controller;
    });

    print('🗺️ Mappa creata, inizializzazione...');

    // Inizializza il livello di zoom corrente
    await _updateCurrentZoom();

    // Configura le impostazioni di localizzazione
    try {
      await mapboxMapController?.location.updateSettings(
        LocationComponentSettings(enabled: true),
      );
      print('✅ Location component abilitato');
    } catch (e) {
      print('❌ Errore location component: $e');
    }

    // Abilita esplicitamente le gesture di navigazione
    await _enableMapGestures();

    // Verifica lo stato delle gesture dopo l'abilitazione
    await _checkGestureSettings();

    // Sposta la camera alla posizione corrente se disponibile
    _moveCameraAndDrawCircle();
  }

  Future<void> _checkGestureSettings() async {
    if (mapboxMapController != null) {
      try {
        final settings = await mapboxMapController!.gestures.getSettings();
        print('🎯 Gesture Settings:');
        print('   - Scroll: ${settings.scrollEnabled}');
        print('   - Pinch to Zoom: ${settings.pinchToZoomEnabled}');
        print('   - Rotate: ${settings.rotateEnabled}');
        print('   - Pitch: ${settings.pitchEnabled}');
        print('   - Double Tap: ${settings.doubleTapToZoomInEnabled}');

        if (settings.scrollEnabled == false) {
          print('⚠️ WARNING: Scroll non abilitato!');
        }
      } catch (e) {
        print('❌ Errore controllo gesture: $e');
      }
    }
  }

  Future<void> _enableMapGestures() async {
    if (mapboxMapController != null) {
      try {
        // Abilita tutte le gesture della mappa
        await mapboxMapController!.gestures.updateSettings(
          GesturesSettings(
            scrollEnabled: true,
            pinchToZoomEnabled: true,
            rotateEnabled: true,
            pitchEnabled: true,
            doubleTapToZoomInEnabled: true,
            doubleTouchToZoomOutEnabled: true,
            quickZoomEnabled: true,
          ),
        );

        print('Gesture della mappa abilitate');
      } catch (e) {
        print('Errore nell\'abilitazione delle gesture: $e');
      }
    }
  }
}
