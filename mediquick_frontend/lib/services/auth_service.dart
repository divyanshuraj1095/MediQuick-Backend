import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(Config.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        await _saveAuthData(data['token'], data['user']);
        return data;
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error. Is the backend running?'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(Config.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': 'user',
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && data['success'] == true) {
        await _saveAuthData(data['token'], data['user']);
        return data;
      }
      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error. Is the backend running?'};
    }
  }

  static Future<void> _saveAuthData(String token, dynamic user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>> updateAddress(String newAddress) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final response = await http.put(
        Uri.parse(Config.updateAddressUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'address': newAddress}),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        // Update local user cache
        final currentUser = await getUser();
        if (currentUser != null) {
          currentUser['address'] = data['user']['address'];
          await _saveAuthData(token, currentUser);
        }
        return data;
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to update address'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateLocation(double lat, double lng) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final response = await http.put(
        Uri.parse(Config.updateLocationUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        // Update local user cache
        final currentUser = await getUser();
        if (currentUser != null) {
          currentUser['location'] = data['user']['location'];
          await _saveAuthData(token, currentUser);
        }
        return data;
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to map location'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
