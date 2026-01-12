import 'package:flutter/foundation.dart';
import '../services/mobile_auth_service.dart';
import '../models/user_model.dart';

class MobileAuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isAuthLocked = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isAuthLocked => _isAuthLocked;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  final MobileAuthService _authService = MobileAuthService();

  void lockAuth() {
    if (_isAuthLocked) return;
      _isAuthLocked = true;
      notifyListeners();
  }

  void unlockAuth() {
    if (!_isAuthLocked) return;
      _isAuthLocked = false;
      notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);

      _isLoading = false;
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _isAuthenticated = false;
        _currentUser = null;
        _errorMessage = "Invalid username or password";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
      _errorMessage = "An error occurred. Please try again.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void updateCurrentUser(UserModel user) {
    if (_currentUser == user) return;
    _currentUser = user;
    // ❌ ZABRANJENO: notifyListeners() samo u login(), logout(), lockAuth(), unlockAuth()
  }
}

