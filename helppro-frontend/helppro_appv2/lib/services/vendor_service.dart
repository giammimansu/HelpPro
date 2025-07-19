import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vendor.dart';

class VendorService {
  final String _baseUrl = 'http://10.0.2.2:8000';

  Future<List<Vendor>> fetchVendors({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/vendors/search?lat=$lat&lon=$lon&radius_km=$radiusKm',
    );
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data
          .map((item) => Vendor.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load vendors (${resp.statusCode}): ${resp.body}',
      );
    }
  }
}
