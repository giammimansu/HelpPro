import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  // scegli host in base alla piattaforma
  static final String _baseUrl = kIsWeb
    ? 'http://localhost:8000'
    : Platform.isAndroid
      ? 'http://10.0.2.2:8000'
      : 'http://localhost:8000';

  final _storage = const FlutterSecureStorage();
  String? _token;
  bool get isLoggedIn => _token != null;
  String? get token => _token;

  Future<void> loadToken() async {
    _token = await _storage.read(key: 'access_token');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access_token'];
      await _storage.write(key: 'access_token', value: _token);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signup(String email, String password, String fullName, String role) async {
    final url = Uri.parse('$_baseUrl/auth/signup');
    final body = jsonEncode({
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': role,
    });
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return response.statusCode == 201;
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'access_token');
    notifyListeners();
  }
}
