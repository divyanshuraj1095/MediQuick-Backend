import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config.dart';

class AdminAuthService {
  static const String _adminTokenKey = 'admin_token';
  static const String _adminUserKey = 'admin_user_data';

  static Future<Map<String, dynamic>> adminLogin(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(Config.adminLoginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        await _saveAdminData(data['token'], data['user']);
        return data;
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Login failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Is the backend running?',
      };
    }
  }

  static Future<void> _saveAdminData(String token, dynamic user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminTokenKey, token);
    await prefs.setString(_adminUserKey, jsonEncode(user));
  }

  static Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminTokenKey);
  }

  static Future<Map<String, dynamic>?> getAdminUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_adminUserKey);
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isAdminLoggedIn() async {
    final token = await getAdminToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> adminLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminTokenKey);
    await prefs.remove(_adminUserKey);
  }
}
