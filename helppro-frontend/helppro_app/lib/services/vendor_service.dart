// lib/services/vendor_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/vendor.dart';
import 'auth_service.dart'; // importa AuthService

class VendorService {
  // ora accessibile
  static final _baseUrl = AuthService.baseUrl;
  final _storage = const FlutterSecureStorage();

  Future<List<Vendor>> searchVendors({
    String? city,
    String? postcode,
    String? address,
  }) async {
    final token = await _storage.read(key: 'access_token');
    final uri = Uri.parse('$_baseUrl/vendors/search').replace(
      queryParameters: {
        if (city != null && city.isNotEmpty) 'city': city,
        if (postcode != null && postcode.isNotEmpty) 'postcode': postcode,
        if (address != null && address.isNotEmpty) 'address': address,
      },
    );
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Errore fetching vendors: ${resp.statusCode}');
    }
    final list = jsonDecode(resp.body) as List;
    return list.map((j) => Vendor.fromJson(j)).toList();
  }
}
