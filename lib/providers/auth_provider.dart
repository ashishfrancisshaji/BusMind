import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userId;
  String? _userEmail;
  String? _userName;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      _userId = prefs.getString('userId');
      _userEmail = prefs.getString('userEmail');
      _userName = prefs.getString('userName');
    } catch (e) {
      debugPrint('Error loading auth state: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate authentication with demo credentials
      await Future.delayed(const Duration(seconds: 2));
      
      // Demo credentials for testing
      const validEmail = "demo@busmind.com";
      const validPassword = "password123";
      
      if (email == validEmail && password == validPassword) {
        _isAuthenticated = true;
        _userId = DateTime.now().millisecondsSinceEpoch.toString();
        _userEmail = email;
        _userName = "Demo User";

        await _saveAuthState();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Invalid credentials
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate registration - replace with real authentication
      await Future.delayed(const Duration(seconds: 2));
      
      if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
        _isAuthenticated = true;
        _userId = DateTime.now().millisecondsSinceEpoch.toString();
        _userEmail = email;
        _userName = name;

        await _saveAuthState();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Sign up error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
      _userName = null;
    } catch (e) {
      debugPrint('Sign out error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', _isAuthenticated);
      if (_userId != null) await prefs.setString('userId', _userId!);
      if (_userEmail != null) await prefs.setString('userEmail', _userEmail!);
      if (_userName != null) await prefs.setString('userName', _userName!);
    } catch (e) {
      debugPrint('Error saving auth state: $e');
    }
  }
}
