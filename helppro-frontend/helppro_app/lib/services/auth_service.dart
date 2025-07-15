import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  static const _apiBase = 'api.yourdomain.com';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  String? _token;
  bool _isLoggedIn = false;
  static const _tokenKey = 'access_token';

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  Future<void> loadToken() async {
    final stored = await _storage.read(key: _tokenKey);
    if (stored != null) {
      _token = stored;
      _isLoggedIn = true;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final uri = Uri.https(_apiBase, '/auth/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _token = data['access_token'];
      await _storage.write(key: _tokenKey, value: _token);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signup(String email, String password, String fullName) async {
    final uri = Uri.https(_apiBase, '/auth/signup');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );
    if (res.statusCode == 201) {
      return await login(email, password);
    }
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _isLoggedIn = false;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }

  /// diventa static!
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storage.read(key: _tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
