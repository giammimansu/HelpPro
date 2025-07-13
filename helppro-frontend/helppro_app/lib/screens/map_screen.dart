import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
    );
  }
}
