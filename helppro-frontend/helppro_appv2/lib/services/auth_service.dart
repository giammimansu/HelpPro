import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  static const String _baseUrl =
      'http://10.0.2.2:8000'; // Indirizzo del backend (emulatore Android)

  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=$email&password=$password',
    );

    if (response.statusCode == 200) {
      final data = response.body;
      // Parsing manuale per evitare dipendenze, puoi usare jsonDecode se preferisci
      final tokenMatch = RegExp(
        r'"access_token"\s*:\s*"([^"]+)"',
      ).firstMatch(data);
      if (tokenMatch != null) {
        _accessToken = tokenMatch.group(1);
        notifyListeners();
        return true;
      }
      return false;
    } else {
      return false;
    }
  }

  Future<bool> signup(String email, String fullName, String password) async {
    final url = Uri.parse('$_baseUrl/auth/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body:
          '{"email": "$email", "full_name": "$fullName", "password": "$password"}',
    );

    if (response.statusCode == 201) {
      return true; // Registrazione riuscita
    } else {
      return false; // Errore nella registrazione
    }
  }
}
