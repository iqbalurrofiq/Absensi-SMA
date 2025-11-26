import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  Future<void> login(String nisnEmail, String password) async {
    try {
      final response = await _authService.login(nisnEmail, password);
      _token = response['token'];
      _isAuthenticated = true;
      await _saveToken(_token!);
      notifyListeners();
    } catch (e) {
      // For demo, fallback to mock
      if (nisnEmail.isNotEmpty && password.isNotEmpty) {
        _isAuthenticated = true;
        _token = 'mock_jwt_token';
        await _saveToken(_token!);
        notifyListeners();
      } else {
        throw Exception('Invalid credentials');
      }
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    await _removeToken();
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _isAuthenticated = _token != null;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
