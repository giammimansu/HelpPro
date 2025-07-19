import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMapController;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    // Puoi gestire qui eventuali errori o permessi negati
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: MapWidget(onMapCreated: _OnMapCreated));
  }

  void _OnMapCreated(MapboxMap controller) {
    setState(() {
      mapboxMapController = controller;
    });

    mapboxMapController?.location.updateSettings(
      LocationComponentSettings(enabled: true),
    );
  }
}
