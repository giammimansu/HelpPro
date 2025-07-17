import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/vendor.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  List<Vendor> _vendors = [];
  bool _isLoading = true;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(41.9028, 12.4964), // Centro di Roma
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final lat = _initialPosition.target.latitude;
      final lng = _initialPosition.target.longitude;
      // Chiamata al backend con il token
      final vendors = await auth.fetchNearbyProfessionals(
        latitude: lat,
        longitude: lng,
      );

      final markers = vendors.map(
        (v) => Marker(
          markerId: MarkerId(v.id.toString()),
          position: LatLng(v.latitude, v.longitude),
          infoWindow: InfoWindow(title: v.companyName, snippet: v.address),
        ),
      );

      setState(() {
        _vendors = vendors;
        _markers = markers.toSet();
      });
    } catch (e) {
      debugPrint('Errore fetching vendors: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore nel caricamento: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mappa Professionisti'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadVendors),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
                if (_vendors.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, -2),
                          ),
                        ],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _vendors.length,
                        itemBuilder: (_, i) {
                          final v = _vendors[i];
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Container(
                                width: 160,
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.companyName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      v.address,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
