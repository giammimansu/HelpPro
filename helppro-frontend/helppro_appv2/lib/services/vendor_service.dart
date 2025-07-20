import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/vendor.dart';
import '../utils/memory_manager.dart';

class VendorService {
  final String _baseUrl = 'http://10.0.2.2:8000';

  // Configurazioni ottimizzate per memoria
  static const Duration networkTimeout = Duration(seconds: 8); // Ridotto
  static const int maxVendorsPerRequest = 50; // Limita i risultati

  Future<List<Vendor>> fetchVendors({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    // Crea una chiave cache semplificata per ridurre memoria
    final cacheKey =
        'vendors_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${radiusKm.toInt()}';

    // Usa MemoryManager per gestione intelligente della cache
    List<Vendor>? cachedVendors = MemoryManager.get<List<Vendor>>(cacheKey);
    if (cachedVendors != null && cachedVendors.isNotEmpty) {
      print('🎯 Cache hit: ${cachedVendors.length} vendors');
      return cachedVendors;
    }

    print('🌐 API Request: lat=$lat, lon=$lon, radius=${radiusKm}km');

    final uri = Uri.parse(
      '$_baseUrl/vendors/search?lat=$lat&lon=$lon&radius_km=$radiusKm',
    );

    try {
      final resp = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(networkTimeout);

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);

        // Limita il numero di vendors per evitare OOM
        final limitedData = data.take(maxVendorsPerRequest).toList();

        final vendors = limitedData
            .map((item) => Vendor.fromJson(item as Map<String, dynamic>))
            .toList();

        // Salva in cache usando MemoryManager
        MemoryManager.put(cacheKey, vendors);

        print(
          '✅ Caricati ${vendors.length} vendors (limitati da ${data.length})',
        );
        return vendors;
      } else {
        throw Exception('Server error (${resp.statusCode}): ${resp.body}');
      }
    } on TimeoutException {
      throw Exception('Timeout: Richiesta troppo lenta');
    } on FormatException {
      throw Exception('Dati corrotti dal server');
    } catch (e) {
      throw Exception('Errore di rete: ${e.toString()}');
    }
  }

  // Metodo per pulire la cache manualmente
  void clearCache() {
    MemoryManager.clearAll();
    print('🧹 Cache VendorService pulita');
  }

  // Metodo per ottenere statistiche memoria
  Map<String, dynamic> getMemoryStats() {
    return MemoryManager.getMemoryStats();
  }
}
