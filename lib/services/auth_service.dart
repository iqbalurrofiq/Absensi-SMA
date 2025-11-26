import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      'https://api.smaunggul1.com'; // Replace with actual API URL

  Future<Map<String, dynamic>> login(
    String nisnEmail,
    String password, {
    String role = 'student',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': nisnEmail,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Forgot password failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Token refresh failed: ${response.body}');
    }
  }
}
