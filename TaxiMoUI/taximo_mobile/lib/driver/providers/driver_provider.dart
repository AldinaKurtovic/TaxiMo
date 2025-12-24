import 'package:flutter/foundation.dart';
import '../services/driver_auth_service.dart';
import '../models/driver_model.dart';
import '../../user/services/driver_service.dart';
import '../../user/models/driver_dto.dart';

class DriverProvider extends ChangeNotifier {
  final DriverAuthService _authService = DriverAuthService();
  final DriverService _driverService = DriverService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  DriverModel? _currentDriver;
  DriverDto? _driverProfile;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DriverModel? get currentDriver => _currentDriver;
  DriverDto? get driverProfile => _driverProfile;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final driver = await _authService.login(username, password);

      if (driver != null) {
        _currentDriver = driver;
        _isAuthenticated = true;
        _errorMessage = null;
        
        // Load driver profile after successful login
        await loadDriverProfile(username);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isAuthenticated = false;
        _currentDriver = null;
        _errorMessage = "Invalid username or password";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentDriver = null;
      _errorMessage = "An error occurred. Please try again.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDriverProfile(String username) async {
    try {
      _driverProfile = await _driverService.getDriverByUsername(username);
      notifyListeners();
    } catch (e) {
      // Log error but don't block login
      debugPrint('Failed to load driver profile: $e');
    }
  }

  void logout() {
    _isAuthenticated = false;
    _currentDriver = null;
    _driverProfile = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

