import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helppro_app/models/vendor.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl =
      'http://10.0.2.2:3000'; // Backend locale su emulator Android

  String? _token;
  String? get token => _token;

  /// Carica il token salvato in precedenza
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
    notifyListeners();
  }

  /// Ritorna il token corrente o lo recupera dalla memoria
  Future<String> getToken() async {
    if (_token != null) return _token!;
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('authToken');
    if (t == null) {
      throw Exception('Token non trovato. Effettua il login.');
    }
    _token = t;
    return _token!;
  }

  /// Salva il token e notifica i listener
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    _token = token;
    notifyListeners();
  }

  /// Effettua la richiesta di login a /auth/token utilizzando form data
  Future<void> login({required String email, required String password}) async {
    final uri = Uri.parse('$_baseUrl/auth/token');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    print('LOGIN ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      await saveToken(accessToken);
    } else {
      throw Exception('Login fallito (${response.statusCode})');
    }
  }

  /// Effettua la registrazione a /auth/signup e poi esegue il login
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/signup');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    print('SIGNUP ${response.statusCode}: ${response.body}');
    if (response.statusCode == 201) {
      // Signup avvenuto: ora login per ottenere token
      await login(email: email, password: password);
    } else {
      throw Exception('Signup fallito (${response.statusCode})');
    }
  }

  /// Logout: rimuove il token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    _token = null;
    notifyListeners();
  }

  /// Recupera i vendor vicini usando il token per autorizzazione
  /// Parametri: latitudine, longitudine, raggio in km (default 5)
  Future<List<Vendor>> fetchNearbyProfessionals({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final t = await getToken();
    final uri = Uri.parse(
      '\$_baseUrl/vendors/search?lat=\$latitude&lon=\$longitude&radius_km=\$radiusKm',
    );
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \$t',
      },
    );
    print('VENDORS ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Vendor.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Errore fetching vendors (${response.statusCode})');
  }
}
