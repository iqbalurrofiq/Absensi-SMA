import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  String? _token;
  String? _userRole;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userRole => _userRole;

  Future<void> login(
    String nisnEmail,
    String password, {
    String role = 'student',
  }) async {
    try {
      final response = await _authService.login(
        nisnEmail,
        password,
        role: role,
      );
      _token = response['token'];
      _userRole = response['user']['role'] ?? role;
      _isAuthenticated = true;
      await _saveToken(_token!);
      await _saveUserRole(_userRole!);
      notifyListeners();
    } catch (e) {
      // For demo, fallback to mock
      if (nisnEmail.isNotEmpty && password.isNotEmpty) {
        _isAuthenticated = true;
        _token = 'mock_jwt_token';
        _userRole = role;
        await _saveToken(_token!);
        await _saveUserRole(_userRole!);
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
    _userRole = prefs.getString('user_role') ?? 'student';
    _isAuthenticated = _token != null;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_role');
  }
}
