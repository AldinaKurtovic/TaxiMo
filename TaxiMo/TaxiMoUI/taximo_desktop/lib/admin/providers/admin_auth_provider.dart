import 'package:flutter/foundation.dart';
import '../services/admin_auth_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final AdminAuthService _authService = AdminAuthService();

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _authService.login(email, password);

      _isLoading = false;
      if (success) {
        _isAuthenticated = true;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _isAuthenticated = false;
        _errorMessage = "Invalid username or password";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _isAuthenticated = false;
      _errorMessage = "An error occurred. Please try again.";
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }
}

